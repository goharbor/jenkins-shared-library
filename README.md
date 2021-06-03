# Jenkins Shared Library
The experimental [shared libraries](https://www.jenkins.io/doc/book/pipeline/shared-libraries/) for running E2E tests against Harbor instance(2.3+) on Jenkins.

## Prerequisites
- Jenkins 2.249.1+
- Jenkins Plugins:
  - [Workspace Cleanup 0.39+](https://plugins.jenkins.io/ws-cleanup/)
  - [Robot Framework 3.0.1+](https://plugins.jenkins.io/robot/)
  - [Slack Notification 2.48+](https://plugins.jenkins.io/slack/)

## Runs As Jenkins Shared Library
1. Register this repository as the `Global Pipeline Libraries`(named `harbor`) in Jenkins according to this [guide](https://www.jenkins.io/doc/book/pipeline/shared-libraries/#global-shared-libraries).
2. Import the registered library in `Jenkinsfile`:
    ```
    // import main branch to run cases against Harbor instance deployed from master branch
    @Library('harbor@main') _
    
   // import 2.3 branch to run cases against Harbor instance v2.3.x
    @Library('harbor@2.3') _
    ```
   **Notes: Import the corresponding branch of the library for the Harbor instance to be tested. e.g. for Harbor v2.3.x importing branch 2.3**
   
3. Use the libraries in `Jenkinsfile`
    ```
    @Library('harbor@main') _
    import io.goharbor.*
    
    node() {
        HarborInstance instance = new HarborInstance()
        instance.coreServiceURL = "https://harbor.local"
        instance.notaryServiceURL = "https://notary.harbor.local"
    
        stage('Health-Check') {
            check_health(instance)
        }
        stage('Test') {
            CaseSettings caseSettings = new CaseSettings()
            caseSettings.branch = "master"
            run_test_case(instance, caseSettings, "workdir")
        }
        stage('Publish-Result') {
            publish_test_result("workdir/result")
        }
    }
    ```

## Libraries
- [check_health](./vars/check_health.groovy)
- [import_trivy_db](./vars/import_trivy_db.groovy)
- [run_test_case](./vars/run_test_case.groovy)
- [publish_test_result](./vars/publish_test_result.groovy)
- [send_to_slack](./vars/send_to_slack.groovy)
- [run_fresh_install_pipeline](./vars/run_fresh_install_pipeline.groovy)

## Pipelines
- [Run tests on demand](./pipelines/e2e_test_on_demand)


