#!/bin/bash
set -e

usage(){
  echo "Usage: $(basename "$0") [OPTIONS]"
  echo "Script to check the health status of the Harbor instance"
  echo "Options:"
  echo "  -h, --help                    Print usage"
  echo "      --tty                     Set it as false to disable the tty when executing docker run"
  echo "  -w, --workdir                 The working directory"
  echo "  -c, --core-service-url        The URL of the Harbor Core service, e.g. https://harbor.local"
  echo "      --proxy                   The HTTP proxy used to connect to the Harbor instance"
  echo "      --host-ip-mappings        The host-to-ip mappings, split multiple items by comma, e.g. harbor.local:192.168.0.1"
  echo "      --retry                   The retry count to check the health status of the Harbor instance, wait 10 seconds between retries, default: 60"
  echo "      --e2e-engine-image        The image of e2e engine, default: harbor-repo.vmware.com/harbor-ci/harbor-chart/e2e-engine:2.10"
}

# the default values
workdir="workdir"
retry="60"
e2e_engine_image="harbor-repo.vmware.com/harbor-ci/harbor-chart/e2e-engine:2.10"

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
    -c|--core-service-url)
      core_service_url="$2"
      shift
      shift
      ;;
    --proxy)
      proxy="$2"
      shift
      shift
      ;;
    --host-ip-mappings)
      host_ip_mappings="$2"
      shift
      shift
      ;;
    --retry)
      retry="$2"
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

# make workdir if not exists
workdir=$(mkdir -p ${workdir};cd ${workdir};pwd)

# write the scripts into a file which runs inside the container
cat <<EOF > ${workdir}/_check_health.sh
#!/bin/bash
set -e

# set proxy environment variables
if [[ -n "${proxy}" ]]; then
  echo -n " > setting the environment variables for proxy: ${proxy}... "
  export http_proxy="${proxy}" https_proxy="${proxy}" no_proxy="127.0.0.1,localhost" HTTP_PROXY="${proxy}" HTTPS_PROXY="${proxy}" NO_PROXY="127.0.0.1,localhost"
  echo "done"
fi

# check health status
echo " > call the health API to verify the deployment..."
status=""
for (( i=0; i<${retry}; i++ )); do
  resp=\$(curl -k --silent --connect-timeout 30 --write-out "HTTPSTATUS:%{http_code}" ${core_service_url}/api/v2.0/health || true)
  body=\$(echo \$resp | sed -e 's/HTTPSTATUS\:.*//g' || true)
  code=\$(echo \$resp | tr -d '\n' | sed -e 's/.*HTTPSTATUS://' || true)
  if [[ "\$code" -ne 200 ]]; then
    echo " > call health API failed, code \$code != 200, wait for 10 seconds..."
    sleep 10s
    continue
  fi
  unhealthy=\$(echo "\$body" | grep "unhealthy" || true)
  if [[ -n "\$unhealthy"  ]]; then
    echo " > unhealthy, \${body}, wait for 10 seconds..."
    sleep 10s
    continue
  fi
  status="ok"
  break
done
if [[ "\$status" != "ok" ]]; then
  echo " > call health API timeout"
  exit 1
else
  echo " > the Harbor instance is healthy"
fi
EOF

# append "--add-host" options to docker_run_options
if [[ -n "${host_ip_mappings}" ]]; then
  IFS=',' read -ra mappings <<< "${host_ip_mappings}"
  for mapping in "${mappings[@]}"; do
    docker_run_options="${docker_run_options} --add-host ${mapping} "
  done
fi

# the process cannot be stopped by "Ctrl+C" without "-t" when running docker run in interactive mode
if [[ "${tty}" = "false" ]]; then
  docker_run_options="-i ${docker_run_options}"
else
  docker_run_options="-it ${docker_run_options}"
fi

docker run ${docker_run_options} --init --privileged --rm -w /workdir -v ${workdir}/:/workdir/ \
  ${e2e_engine_image} bash /workdir/_check_health.sh