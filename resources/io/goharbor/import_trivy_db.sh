#!/bin/bash
set -e

usage(){
  echo "Usage: $(basename "$0") [OPTIONS]"
  echo "Script to import Trivy database into the Harbor instance deployed on Kubernetes"
  echo "Options:"
  echo "  -h, --help                    Print usage"
  echo "      --tty                     Set it as false to disable the tty when executing docker run"
  echo "  -w, --workdir                 The working directory"
  echo "      --db-file                 The location of Trivy db file, default: ./trivy-db.tar.gz"
  echo "      --kube-config             The location of kube config file"
  echo "      --kube-context            The name of the kube config context to use"
  echo "      --namespace               The namespace where Harbor is deployed in, use the namespace defined in the context if not specify"
  echo "      --proxy                   The HTTP proxy used to connect to the Harbor instance"
  echo "      --e2e-engine-image        The image of e2e engine, default: harbor-repo.vmware.com/harbor-ci/harbor-chart/e2e-engine:dev"
}

# the default values
workdir="workdir"
db_file="$(pwd)/trivy-db.tar.gz"
e2e_engine_image="harbor-repo.vmware.com/harbor-ci/harbor-chart/e2e-engine:2.5"

while [[ $# -gt 0 ]]
do
  case "$1" in
    -h|--help)
    usage
      exit
      ;;
    --tty)
      tty="$2"
      shift
      shift
      ;;
    -w|--workdir)
      workdir="$2"
      shift
      shift
      ;;
    --db-file)
      db_file="$2"
      shift
      shift
      ;;
    --kube-config)
      kube_config="$2"
      shift
      shift
      ;;
    --kube-context)
      kube_context="$2"
      shift
      shift
      ;;
    --namespace)
      namespace="$2"
      shift
      shift
      ;;
    --proxy)
      proxy="$2"
      shift
      shift
      ;;
    --e2e-engine-image)
      e2e_engine_image="$2"
      shift
      shift
      ;;
    *)
      echo "error: unknown option $1, try $(basename "$0") -h/--help for more information"
      exit 1
      ;;
  esac
done

if [[ -z "${kube_config}" ]]; then
  echo 'the "--kube-config" option is required'
  exit 1
fi

# make workdir if not exists
workdir=$(mkdir -p ${workdir};cd ${workdir};pwd)

# write the scripts into a file which runs inside the container
cat <<EOF > ${workdir}/_import_trivy_db.sh
#!/bin/bash
set -e

# set proxy environment variables
if [[ -n "${proxy}" ]]; then
  echo -n " > setting the environment variables for proxy: ${proxy}... "
  export http_proxy="${proxy}" https_proxy="${proxy}" no_proxy="127.0.0.1,localhost" HTTP_PROXY="${proxy}" HTTPS_PROXY="${proxy}" NO_PROXY="127.0.0.1,localhost"
  echo "done"
fi

if [[ -n "${kube_context}" ]]; then
  options="--context ${kube_context}"
fi

if [[ -n "${namespace}" ]]; then
  options="\${options} --namespace ${namespace}"
fi

echo -n " > importing Trivy database... "
tar -zxf ./trivy-db.tar.gz
# append "|| true" here to output more information when get no pod named trivy
trivy_pod=\$(kubectl \${options} get pods -o custom-columns=":metadata.name" | grep trivy || true)
kubectl \${options} exec -i \${trivy_pod} -- mkdir -p /home/scanner/.cache/trivy/db/
cat ./trivy_db/metadata.json | kubectl \${options} exec -i \${trivy_pod} -- tee /home/scanner/.cache/trivy/db/metadata.json 1>/dev/null
cat ./trivy_db/trivy.db | kubectl \${options} exec -i \${trivy_pod} -- tee /home/scanner/.cache/trivy/db/trivy.db 1>/dev/null
echo "done"
EOF

# the process cannot be stopped by "Ctrl+C" without "-t" when running docker run in interactive mode
if [[ "${tty}" = "false" ]]; then
  docker_run_options="-i"
else
  docker_run_options="-it"
fi

docker run ${docker_run_options} --init --privileged --rm -w /workdir -v ${workdir}/:/workdir/ \
  -v ${kube_config}:/root/.kube/config -v ${db_file}:/workdir/trivy-db.tar.gz \
  ${e2e_engine_image} bash /workdir/_import_trivy_db.sh