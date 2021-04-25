// import Trivy db into the Harbor instance deployed on Kubernetes
def call(String kubeConfig, String kubeContext, String namespace, String proxy){
    // load resource files into the workspace of Jenkins worker
    writeFile file: "import_trivy_db.sh", text: libraryResource("io/goharbor/import_trivy_db.sh")
    writeFile file: "trivy-db.tar.gz", text: libraryResource(resource: "io/goharbor/trivy-db.tar.gz", encoding: "Base64"), encoding: "Base64"

    String options = "--tty false --workdir workdir --db-file $env.WORKSPACE/trivy-db.tar.gz"
    options = kubeConfig ? "$options --kube-config $kubeConfig" : options
    options = kubeContext ? "$options --kube-context $kubeContext" : options
    options = namespace ? "$options --namespace $namespace" : options
    options = proxy ? "$options --proxy $proxy" : options

    sh """
        bash import_trivy_db.sh $options
    """
}