import io.goharbor.*

// this is a pre-defined pipeline library which has implemented the common steps(e.g. health checking, test, result publishing, etd.)
// callers are responsible for the customized parts(e.g. installation) by implementing the abstract class "io.goharbor.FreshInstallPipelineExecutor"
def call(FreshInstallPipelineSettings settings) {
    node(settings.node) {
        try{
            // set pipeline properties if defined
            if (settings.properties){
                properties(settings.properties())
            }

            cleanWs() // clean the workspace before running
            checkout scm

            HarborInstance instance

            stage('Pre-Install') {
                 settings.executor.preInstall()
            }
            stage('Install') {
                instance = settings.executor.install()
            }
            stage('Post-Install') {
                settings.executor.postInstall()
            }
            stage('Health-Check') {
                check_health(instance)
            }
            stage('Pre-Test') {
                settings.executor.preTest()
            }
            stage('Test') {
                // set the properties if not specifying
                CaseSettings caseSettings = settings.caseSettings()
                withCredentials([usernamePassword(credentialsId: "79e9fd98-cdf5-4f55-81fa-ecba01365534", usernameVariable: "DOCKER_HUB_USERNAME", passwordVariable: "DOCKER_HUB_PASSWORD"),
                    usernamePassword(credentialsId: "ecr-credential", usernameVariable: "ECR_ACCESS_ID", passwordVariable: "ECR_ACCESS_SECRET"),
                    usernamePassword(credentialsId: "gitlab-registry-credential", usernameVariable: "GITLAB_ACCESS_ID", passwordVariable: "GITLAB_ACCESS_SECRET"),
                    string(credentialsId: "gcr-credential", variable: "GCR_ACCESS_SECRET")]) {
                    caseSettings.dockerHubUsername = caseSettings.dockerHubUsername ? caseSettings.dockerHubUsername : env.DOCKER_HUB_USERNAME
                    caseSettings.dockerHubPassword = caseSettings.dockerHubPassword ? caseSettings.dockerHubPassword : env.DOCKER_HUB_PASSWORD
                    caseSettings.ecrAccessID = caseSettings.ecrAccessID ? caseSettings.ecrAccessID : env.ECR_ACCESS_ID
                    caseSettings.ecrAccessSecret = caseSettings.ecrAccessSecret ? caseSettings.ecrAccessSecret : env.ECR_ACCESS_SECRET
                    caseSettings.gitlabAccessID = caseSettings.gitlabAccessID ? caseSettings.gitlabAccessID : env.GITLAB_ACCESS_ID
                    caseSettings.gitlabAccessSecret = caseSettings.gitlabAccessSecret ? caseSettings.gitlabAccessSecret : env.GITLAB_ACCESS_SECRET
                    caseSettings.gcrAccessSecret = caseSettings.gcrAccessSecret ? caseSettings.gcrAccessSecret : env.GCR_ACCESS_SECRET
                }
                run_test_case(instance, caseSettings, "workdir")
            }
            stage('Post-Test') {
                settings.executor.postTest()
            }
        } catch(e){
            // since we're catching the exception in order to report on it, we need to re-throw it, to ensure that the build is marked as failed
            throw e
        } finally {
            publish_test_result("workdir/result")
            withCredentials([string(credentialsId: "slack-token", variable: "SLACK_TOKEN")]) {
                send_to_slack("#yinw-channel", env.SLACK_TOKEN, "vmware")
            }
        }
    }
}