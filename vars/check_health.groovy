import io.goharbor.*

// check the health status of Harbor instance
def call(HarborInstance instance){
    // write the script content into the workspace of Jenkins worker
    writeFile file: "check_health.sh", text: libraryResource("io/goharbor/check_health.sh")

    String options = "--tty false --workdir workdir --core-service-url $instance.coreServiceURL"
    options = instance.proxy ? "$options --proxy $instance.proxy" : options
    options = instance.hostIPMappings ? "$options --host-ip-mappings $instance.hostIPMappings" : options

    sh """
        bash check_health.sh $options
    """
}