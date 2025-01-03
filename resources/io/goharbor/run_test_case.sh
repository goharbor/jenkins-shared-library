#!/bin/bash
set -e

usage(){
  echo "Usage: $(basename "$0") [OPTIONS]"
  echo "Script to run the end to end test cases against Harbor instance"
  echo "Options:"
  echo "  -h, --help                    Print usage"
  echo "      --tty                     Set it as false to disable the tty when executing docker run"
  echo "  -w, --workdir                 The working directory. The test report is put in the result folder under the working directory"
  echo "  -c, --core-service-url        The URL of the Harbor Core service, e.g. https://harbor.local"
  echo "  -n, --notary-service-url      The URL of the Harbor Notary service, e.g. https://notary.harbor.local"
  echo "      --auth-mode               The authentication mode of the Harbor instance[database/ldap/oidc/uaa/http-auth-proxy], default: database"
  echo "      --components              The enabled components of the Harbor instance[trivy/notary/chartmuseum], split multiple items by comma, default: trivy,notary,chartmuseum"
  echo "      --admin-password          The password of the Harbor administrator, default: Harbor12345"
  echo "      --proxy                   The HTTP proxy used to connect to the Harbor instance"
  echo "      --host-ip-mappings        The host-to-ip mappings, split multiple items by comma, e.g. harbor.local:192.168.0.1"
  echo "      --replication-target-url  The URL of another Harbor instance to run as target for replication cases. The URL specified in '--core-service-url' will be used as the replication target as well if leaving it empty. e.g. https://replication.harbor.local"
  echo "      --case-repository         The repository of test cases, default: https://github.com/goharbor/harbor.git"
  echo "  -b, --case-branch             The branch/tag of the test case repository, default: main"
  echo "      --cases                   The test cases that to run against the Harbor instance[gc/common/schedule/replication/database/ldap/oidc/uaa/trivy/notary/chartmuseum/api], split multiple items by comma. If no cases set, determine the cases by the authentication mode and enabled components of the Harbor instance automatically"
  echo "      --e2e-engine-image        The image of e2e engine, default: registry.goharbor.io/harbor-ci/harbor-chart/e2e-engine:dev"
  echo "      --image-registry          The registry where stores the test images, default: registry.goharbor.io"
  echo "      --image-repository-prefix The prefix of the repository where stores the test images, default: harbor-ci"
  echo "  -u, --dockerhub-username      The username of Dockerhub to avoid the pull limit"
  echo "  -p, --dockerhub-password      The password of Dockerhub to avoid the pull limit"
  echo "      --ecr-access-id           The access key ID of ECR for replication test"
  echo "      --ecr-access-secret       The access key secret of ECR for replication test"
  echo "      --gitlab-access-id        The access key ID of Gitlab registry for replication test"
  echo "      --gitlab-access-secret    The access key secret of Gitlab registry for replication test"
  echo "      --gcr-access-secret       The access secret of GCR for replication test"
}

# the default values
workdir="workdir"
auth_mode="database"
components="trivy,notary,chartmuseum"
admin_password="Harbor12345"
case_repository="https://github.com/goharbor/harbor.git"
case_branch="2.12_update_robot_testcase"
e2e_engine_image="registry.goharbor.io/harbor-ci/harbor-chart/e2e-engine:dev"
image_registry="registry.goharbor.io"
image_repository_prefix="harbor-ci"

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
    -n|--notary-service-url)
      notary_service_url="$2"
      shift
      shift
      ;;
    --auth-mode)
      auth_mode="$2"
      shift
      shift
      ;;
    --components)
      components="$2"
      shift
      shift
      ;;
    --admin-password)
      admin_password="$2"
      shift
      shift
      ;;
    --proxy)
      proxy="$2"
      shift
      shift
      ;;
    --replication-target-url)
      replication_target_url="$2"
      shift
      shift
      ;;
    --host-ip-mappings)
      host_ip_mappings="$2"
      shift
      shift
      ;;
    --case-repository)
      case_repository="$2"
      shift # past argument
      shift # past value
      ;;
    -b|--case-branch)
      case_branch="$2"
      shift
      shift
      ;;
    --cases)
      cases="$2"
      shift
      shift
      ;;
    --e2e-engine-image)
      e2e_engine_image="$2"
      shift
      shift
      ;;
    --image-registry)
      image_registry="$2"
      shift
      shift
      ;;
    --image-repository-prefix)
      image_repository_prefix="$2"
      shift
      shift
      ;;
    -u|--dockerhub-username)
      dockerhub_username="$2"
      shift
      shift
      ;;
    -p|--dockerhub-password)
      dockerhub_password="$2"
      shift
      shift
      ;;
    --ecr-access-id)
      ecr_access_id="$2"
      shift
      shift
      ;;
    --ecr-access-secret)
      ecr_access_secret="$2"
      shift
      shift
      ;;
    --gitlab-access-id)
      gitlab_access_id="$2"
      shift
      shift
      ;;
    --gitlab-access-secret)
      gitlab_access_secret="$2"
      shift
      shift
      ;;
    --gcr-access-secret)
      gcr_access_secret="$2"
      shift
      shift
      ;;
    *)
      echo "error: unknown option $1, try $(basename "$0") -h/--help for more information"
      exit 1
      ;;
  esac
done

# TODO group the test cases by tag/label
# test cases to runs
test_cases="tests/robot-cases/Group1-Nightly/Setup_Nightly.robot"
if [[ -n "${cases}" ]]; then
  IFS=',' read -ra cs <<< "${cases}"
  for c in "${cs[@]}"; do
    case "${c}" in
      gc)
        test_cases="${test_cases} tests/robot-cases/Group1-Nightly/Common_GC.robot"
        ;;
      common)
        test_cases="${test_cases} tests/robot-cases/Group1-Nightly/Common.robot"
        ;;
      schedule)
        test_cases="${test_cases} tests/robot-cases/Group1-Nightly/Schedule.robot"
        ;;
      replication)
        test_cases="${test_cases} tests/robot-cases/Group1-Nightly/Replication.robot"
        ;;
      database)
        test_cases="${test_cases} tests/robot-cases/Group1-Nightly/DB.robot"
        ;;
      ldap)
        test_cases="${test_cases} tests/robot-cases/Group1-Nightly/LDAP.robot"
        ;;
      oidc)
        test_cases="${test_cases} tests/robot-cases/Group1-Nightly/OIDC.robot"
        ;;
      uaa)
        test_cases="${test_cases} tests/robot-cases/Group1-Nightly/UAA.robot"
        ;;
      trivy)
        test_cases="${test_cases} tests/robot-cases/Group1-Nightly/Trivy.robot"
        ;;
      notary)
        test_cases="${test_cases} tests/robot-cases/Group1-Nightly/Notary.robot"
        ;;
      chartmuseum)
        test_cases="${test_cases} tests/robot-cases/Group1-Nightly/Chartmuseum.robot"
        ;;
      api)
        test_cases="${test_cases} tests/robot-cases/Group0-BAT/API_DB.robot"
        ;;
      *)
        echo "error: unknown case ${c}"
        exit 1
        ;;
    esac
  done
else
  test_cases="tests/robot-cases/Group1-Nightly/Setup_Nightly.robot tests/robot-cases/Group1-Nightly/Common_GC.robot tests/robot-cases/Group1-Nightly/Common.robot tests/robot-cases/Group1-Nightly/Schedule.robot tests/robot-cases/Group1-Nightly/Replication.robot"
  # determine cases by authentication mode
  if [[ -n "${auth_mode}" ]]; then
    case "${auth_mode}" in
      database)
        test_cases="${test_cases} tests/robot-cases/Group1-Nightly/DB.robot"
        ;;
      ldap)
        test_cases="${test_cases} tests/robot-cases/Group1-Nightly/LDAP.robot"
        ;;
      oidc)
        test_cases="${test_cases} tests/robot-cases/Group1-Nightly/OIDC.robot"
        ;;
      uaa)
        test_cases="${test_cases} tests/robot-cases/Group1-Nightly/UAA.robot"
        ;;
      *)
        echo "error: unknown authentication mode ${auth_mode}"
        exit 1
        ;;
    esac
  fi
  # determine cases by enabled components
  if [[ -n "${components}" ]]; then
    IFS=',' read -ra cs <<< "${components}"
    for c in "${cs[@]}"; do
      case "${c}" in
        trivy)
          test_cases="${test_cases} tests/robot-cases/Group1-Nightly/Trivy.robot"
          ;;
        notary)
          test_cases="${test_cases} tests/robot-cases/Group1-Nightly/Notary.robot"
          ;;
        chartmuseum)
          test_cases="${test_cases} tests/robot-cases/Group1-Nightly/Chartmuseum.robot"
          ;;
        *)
          echo "error: unknown component ${c}"
          exit 1
          ;;
      esac
    done
  fi
fi
test_cases="${test_cases} tests/robot-cases/Group1-Nightly/Teardown.robot"

# make workdir if not exists
workdir=$(mkdir -p ${workdir};cd ${workdir};pwd)

# write the scripts into a file which runs inside the container
cat <<EOF > ${workdir}/_run_test_case.sh
#!/bin/bash
set -e

# set proxy environment variables
if [[ -n "${proxy}" ]]; then
  echo -n " > setting the environment variables for proxy: ${proxy}... "
  export http_proxy="${proxy}" https_proxy="${proxy}" no_proxy="127.0.0.1,localhost" HTTP_PROXY="${proxy}" HTTPS_PROXY="${proxy}" NO_PROXY="127.0.0.1,localhost"
  echo "done"
fi

# checkout test case
echo -n " > checkout the test cases from the repository: ${case_repository}@${case_branch}... "
rm -rf harbor || true
git clone -b ${case_branch} --single-branch ${case_repository} -q harbor
echo "done"

# use the core_service_url as the replication_target_url when doesn't specify it
if [[ -z "${replication_target_url}" ]]; then
  replication_target_url=${core_service_url}
fi

# TODO move into the setup.robot
# prepare the test users if the deployment is database authentication mode
if [[ "${test_cases}" == *"DB.robot"* ]]; then
  echo -n " > populating user data... "
  for username in user001 user002 user003 user004 user005 user006 user007 user008 user009 user010 user011 user012 user013 user014 user015 user016 user017 user018 user019 user020 user021 user022 user023 user024 user025 user026 user027 user028
  do
    curl -u admin:${admin_password} -k -s -S -X POST --header 'Content-Type: application/json' -d '{
     "username": "'\${username}'",
     "email": "'\${username}@vmware.com'",
     "password": "Test1@34",
     "realname": "user for testing",
     "comment": "user comment for testing"
     }' ${core_service_url}/api/v2.0/users
  done
  echo "done"
fi

# trim the prefix http/https scheme as the robot cases only accept the URL without scheme
core_service_endpoint=$(echo ${core_service_url} | sed "s|http://||g" | sed "s|https://||g")
notary_service_endpoint=$(echo ${notary_service_url} | sed "s|http://||g" | sed "s|https://||g")
replication_target_endpoint=\$(echo \${replication_target_url} | sed "s|http://||g" | sed "s|https://||g")

# apply some workarounds for the robot cases
# the directory "/drone" is needed and hardcoded in the robot cases
# TODO remove the vmwarecert.crt part
mkdir /drone && mkdir /ecs_ca && echo "" > /ecs_ca/vmwarecert.crt

# run test cases
echo " > running test cases..."
cd harbor
make swagger_client 1>/dev/null # workaround https://github.com/robotframework/robotframework/issues/3972
# pass the core_service_endpoint as the ip1 to run the replication cases based on the same Harbor instance
robot -d ../result -v ip:\${core_service_endpoint} -v notaryServerEndpoint:\${notary_service_endpoint} \
  -v LOCAL_REGISTRY:${image_registry} -v LOCAL_REGISTRY_NAMESPACE:${image_repository_prefix} \
  -v DOCKER_USER:${dockerhub_username} -v DOCKER_PWD:${dockerhub_password} \
  -v HARBOR_PASSWORD:${admin_password} -v http_get_ca:true \
  -v DRAGONFLY_AUTH_TOKEN:${DRAGONFLY_AUTH_TOKEN} \
  -v ip1:\${replication_target_endpoint} -v OIDC_HOSTNAME: \
  -v ecr_ac_id:${ecr_access_id} -v ecr_ac_key:${ecr_access_secret} \
  -v gitlab_id:${gitlab_access_id} -v gitlab_key:${gitlab_access_secret} \
  -v gcr_ac_key:'${gcr_access_secret}' ${test_cases} || true
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

docker pull ${e2e_engine_image}
docker run ${docker_run_options} --init --privileged --rm -w /workdir -v /dev/shm:/dev/shm -v ${workdir}/:/workdir/ \
  ${e2e_engine_image} bash /workdir/_run_test_case.sh