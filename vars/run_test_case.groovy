import io.goharbor.*

// run the test cases, the test result is put in the "result" folder under the provided workDir
def call(HarborInstance instance, CaseSettings settings, String workDir){
    // write the script content into the workspace of Jenkins worker
    writeFile file: "run_test_case.sh", text: libraryResource("io/goharbor/run_test_case.sh")

    String options = "--tty false --workdir workdir --core-service-url $instance.coreServiceURL --notary-service-url $instance.notaryServiceURL"
    options = instance.authMode ? "$options --auth-mode $instance.authMode" : options
    options = instance.components ? "$options --components $instance.components" : "$options --components ''"
    options = instance.adminPassword ? "$options --admin-password $instance.adminPassword" : options
    options = instance.proxy ? "$options --proxy $instance.proxy" : options
    options = instance.hostIPMappings ? "$options --host-ip-mappings $instance.hostIPMappings" : options
    options = instance.replicationTargetURL ? "$options --replication-target-url $instance.replicationTargetURL" : options
    options = settings.repository ? "$options --case-repository $settings.repository" : options
    options = settings.branch ? "$options --case-branch $settings.branch" : options
    options = settings.cases ? "$options --cases $settings.cases" : options
    options = settings.imageRegistry ? "$options --image-registry $settings.imageRegistry" : options
    options = settings.imageRepositoryPrefix ? "$options --image-repository-prefix $settings.imageRepositoryPrefix" : options
    options = settings.dockerHubUsername ? "$options --dockerhub-username $settings.dockerHubUsername" : options
    options = settings.dockerHubPassword ? "$options --dockerhub-password $settings.dockerHubPassword" : options
    options = settings.ecrAccessID ? "$options --ecr-access-id $settings.ecrAccessID" : options
    options = settings.ecrAccessSecret ? "$options --ecr-access-secret $settings.ecrAccessSecret" : options
    options = settings.gitlabAccessID ? "$options --gitlab-access-id $settings.gitlabAccessID" : options
    options = settings.gitlabAccessSecret ? "$options --gitlab-access-secret $settings.gitlabAccessSecret" : options
    options = settings.gcrAccessSecret ? "$options --gcr-access-secret \'$settings.gcrAccessSecret\'" : options
    options = workDir ? "$options --workdir $workDir" : options

    sh """
        set +x # disable the printing for the command as it contains credentials
        bash run_test_case.sh $options
    """
}