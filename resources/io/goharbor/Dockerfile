# build the new e2e engine image based on the harbor-e2e-engine one
FROM registry.goharbor.io/harbor-ci/goharbor/harbor-e2e-engine:latest-ui

ARG KUBECTL_VERSION="v1.21.1"

RUN curl https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl && chmod +x /usr/local/bin/kubectl
