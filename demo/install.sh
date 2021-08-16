#!/bin/bash

####################
# Settings
####################

# OS and arch settings
HOSTOS=$(uname -s | tr '[:upper:]' '[:lower:]')
HOSTARCH=$(uname -m)
SAFEHOSTARCH=${HOSTARCH}
if [[ ${HOSTOS} == darwin ]]; then
  SAFEHOSTARCH=amd64
fi
if [[ ${HOSTARCH} == x86_64 ]]; then
  SAFEHOSTARCH=amd64
fi
HOST_PLATFORM=${HOSTOS}_${HOSTARCH}
SAFEHOSTPLATFORM=${HOSTOS}-${SAFEHOSTARCH}

# Directory settings
ROOT_DIR=$(cd -P $(dirname $0) >/dev/null 2>&1 && pwd)
WORK_DIR=${ROOT_DIR}/.work
DEPLOY_LOCAL_WORKDIR=${WORK_DIR}/local/localdev
CACHE_DIR=${ROOT_DIR}/.cache
TOOLS_DIR=${CACHE_DIR}/tools
TOOLS_HOST_DIR=${TOOLS_DIR}/${HOST_PLATFORM}

mkdir -p ${DEPLOY_LOCAL_WORKDIR}
mkdir -p ${TOOLS_HOST_DIR}

# Custom settings
. ${ROOT_DIR}/config.sh

####################
# Utility functions
####################

CYAN="\033[0;36m"
NORMAL="\033[0m"

function info {
  echo -e "${CYAN}INFO ${NORMAL}$@" >&2
}

function wait-deployment {
  local object=$1
  local ns=$2
  echo -n "Waiting for deployment $object ready"
  retries=100
  until [[ $retries == 0 ]]; do
    echo -n "."
    local result=$(${KUBECTL} --kubeconfig ${KUBECONFIG} get deploy $object -n $ns -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
    if [[ $result == 1 ]]; then
      echo "done"
      break
    fi
    sleep 1
    retries=$((retries - 1))
  done
}

function wait-package {
  local package=$1
  echo -n "Waiting for package $package ready"
  retries=100
  until [[ $retries == 0 ]]; do
    echo -n "."
    local result=$(${KUBECTL} --kubeconfig ${KUBECONFIG} get configuration.pkg.crossplane.io $package -o jsonpath='{range .status.conditions[*]}{.type}:{.status} {end}' 2>/dev/null)
    if [[ $result =~ Installed:True && $result =~ Healthy:True ]]; then
      echo "done"
      break
    fi
    sleep 1
    retries=$((retries - 1))
  done
}

####################
# Install kind
####################

KIND=${TOOLS_HOST_DIR}/kind-${KIND_VERSION}

function install-kind {
  info "Installing kind ${KIND_VERSION}..."

  if [[ ! -f ${KIND} ]]; then
    curl -fsSLo ${KIND} https://github.com/kubernetes-sigs/kind/releases/download/${KIND_VERSION}/kind-${SAFEHOSTPLATFORM} || exit -1
    chmod +x ${KIND}
  else
    echo "kind ${KIND_VERSION} detected."
  fi

  info "Installing kind ${KIND_VERSION}...OK"
}

####################
# Install kubectl
####################

KUBECTL=${TOOLS_HOST_DIR}/kubectl-${KUBECTL_VERSION}

function install-kubectl {
  info "Installing kubectl ${KUBECTL_VERSION}..."

  if [[ ! -f ${KUBECTL} ]]; then
    curl -fsSLo ${KUBECTL} https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/${HOSTOS}/${SAFEHOSTARCH}/kubectl || exit -1
    chmod +x ${KUBECTL}
  else
    echo "kubectl ${KUBECTL_VERSION} detected."
  fi

  info "Installing kubectl ${KUBECTL_VERSION}...OK"
}

####################
# Install helm
####################

HELM3=${TOOLS_HOST_DIR}/helm-${HELM3_VERSION}
HELM=${HELM3}

function install-helm {
  info "Installing helm3 ${HELM3_VERSION}..."

  if [[ ! -f ${HELM3} ]]; then
    mkdir -p ${TOOLS_HOST_DIR}/tmp-helm3
    curl -fsSL https://get.helm.sh/helm-${HELM3_VERSION}-${SAFEHOSTPLATFORM}.tar.gz | tar -xz -C ${TOOLS_HOST_DIR}/tmp-helm3
    mv ${TOOLS_HOST_DIR}/tmp-helm3/${SAFEHOSTPLATFORM}/helm ${HELM3}
    rm -fr ${TOOLS_HOST_DIR}/tmp-helm3
  else
    echo "helm3 ${HELM3_VERSION} detected."
  fi

  info "Installing helm3 ${HELM3_VERSION}...OK"
}

####################
# Launch kind
####################

# The cluster information
DEPLOY_LOCAL_KUBECONFIG=${DEPLOY_LOCAL_WORKDIR}/kubeconfig
KIND_CONFIG_FILE=${ROOT_DIR}/kind.yaml
KIND_CLUSTER_NAME=capabilities-demo
KUBECONFIG=${HOME}/.kube/config

function kind-up {
  info "kind up..."

  ${KIND} get kubeconfig --name ${KIND_CLUSTER_NAME} >/dev/null 2>&1 || ${KIND} create cluster --name=${KIND_CLUSTER_NAME} --kubeconfig="${KUBECONFIG}" --config="${KIND_CONFIG_FILE}"
  ${KIND} get kubeconfig --name ${KIND_CLUSTER_NAME} > ${DEPLOY_LOCAL_KUBECONFIG}
  ${KUBECTL} --kubeconfig ${KUBECONFIG} config use-context kind-${KIND_CLUSTER_NAME}

  info "kind up...OK"
}

function kind-down {
  info "kind down..."

  ${KIND} delete cluster --name=${KIND_CLUSTER_NAME}

  info "kind down...OK"
}

####################
# Install Crossplane
####################

HELM_RELEASE_NAMESPACE="crossplane-system"
HELM_REPOSITORY_NAME=crossplane-stable
HELM_REPOSITORY_URL=https://charts.crossplane.io/stable
HELM_CHART_VERSION="${CROSSPLANE_VERSION}"
HELM_RELEASE_NAME="crossplane"
HELM_CHART_NAME="crossplane"
HELM_CHART_REF="${HELM_REPOSITORY_NAME}/${HELM_CHART_NAME}"

function install-crossplane {
  info "Installing ${HELM_RELEASE_NAME} ${HELM_CHART_VERSION}..."

  # Update helm repo
  if ! "${HELM}" repo list -o yaml | grep -i "Name:\s*${HELM_REPOSITORY_NAME}\s*$" >/dev/null; then
    ${HELM} repo add "${HELM_REPOSITORY_NAME}" "${HELM_REPOSITORY_URL}"
    ${HELM} repo update
  fi

  # Create namespace if not exists
  ${KUBECTL} --kubeconfig ${KUBECONFIG} get ns "${HELM_RELEASE_NAMESPACE}" >/dev/null 2>&1 || \
    ${KUBECTL} --kubeconfig ${KUBECONFIG} create ns "${HELM_RELEASE_NAMESPACE}"

  # Install helm release
  ${HELM} upgrade --install "${HELM_RELEASE_NAME}" --namespace "${HELM_RELEASE_NAMESPACE}" --kubeconfig "${KUBECONFIG}" \
    "${HELM_CHART_REF}" --version ${HELM_CHART_VERSION} 2>/dev/null

  wait-deployment ${HELM_CHART_NAME} ${HELM_RELEASE_NAMESPACE}

  info "Installing ${HELM_RELEASE_NAME} ${HELM_CHART_VERSION}...OK"
}

####################
# Install OLM
####################

function install-olm {
  info "Installing OLM ${OLM_VERSION}..."

  local target_url=https://github.com/operator-framework/operator-lifecycle-manager/releases/download/$OLM_VERSION/install.sh
  curl -fsSL ${target_url} | sed "s@kubectl@${KUBECTL} --kubeconfig ${KUBECONFIG}@g" | bash -s $OLM_VERSION

  info "Installing OLM ${OLM_VERSION}...OK"
}

####################
# Install ODLM
####################

function install-odlm {
  info "Installing ODLM..."

  ${KUBECTL} --kubeconfig ${KUBECONFIG} apply -f ${ROOT_DIR}/odlm/deployment.yaml
  ${KUBECTL} --kubeconfig ${KUBECONFIG} apply -f ${ROOT_DIR}/odlm/rbac.yaml

  wait-deployment operand-deployment-lifecycle-manager odlm

  info "Installing ODLM...OK"
}

####################
# Install capabilities-shim
####################

CAPABILITIES_SHIM_CONFIGURATION=capabilities-shim

function install-capabilities-shim {
  info "Installing capabilities-shim..."

  # Install capabilities-shim configuration package
  cat << EOF | ${KUBECTL} --kubeconfig ${KUBECONFIG} apply -f -
apiVersion: pkg.crossplane.io/v1
kind: Configuration
metadata:
  name: ${CAPABILITIES_SHIM_CONFIGURATION}
spec:
  ignoreCrossplaneConstraints: false
  package: quay.io/moyingbj/capabilities-shim:${CAPABILITIES_SHIM_VERSION}
  packagePullPolicy: IfNotPresent
  revisionActivationPolicy: Automatic
  revisionHistoryLimit: 0
  skipDependencyResolution: false
EOF

  wait-package ${CAPABILITIES_SHIM_CONFIGURATION}

  # Setup ProviderConfig and cluster-config secret
  cat << EOF | ${KUBECTL} --kubeconfig ${KUBECONFIG} apply -f -
apiVersion: kubernetes.crossplane.io/v1alpha1
kind: ProviderConfig
metadata:
  name: kubernetes-provider
spec:
  credentials:
    source: Secret
    secretRef:
      namespace: crossplane-system
      name: cluster-config
      key: kubeconfig
EOF

  KUBESVC_IP=$(${KUBECTL} --kubeconfig ${KUBECONFIG} get svc kubernetes -o jsonpath='{.spec.clusterIP}')
  CLUSTER_CONFIG=$(cat ${DEPLOY_LOCAL_KUBECONFIG} | sed -e "s|server:\s*.*$|server: https://${KUBESVC_IP}|g")
  ${KUBECTL} --kubeconfig ${KUBECONFIG} -n crossplane-system delete secret cluster-config --ignore-not-found=true
  ${KUBECTL} --kubeconfig ${KUBECONFIG} -n crossplane-system create secret generic cluster-config --from-literal=kubeconfig="${CLUSTER_CONFIG}"

  info "Installing capabilities-shim...OK"
}

####################
# Pull and load images
####################

function pull-and-load-images {
  info "Pulling and loading images..."

  if ! command -v docker >/dev/null 2>&1; then
    echo "docker not installed, exit."
    exit 1
  else
    DOCKER=docker
  fi

  for i in ${REQUIRED_IMAGES[@]+"${REQUIRED_IMAGES[@]}"}; do
    echo "Pulling and loading image: ${i}"
    if echo "${i}" | grep ":master\s*$" >/dev/null || echo "${i}" | grep ":latest\s*$" >/dev/null || \
      ! ${DOCKER} inspect --type=image "${i}" >/dev/null 2>&1; then
      ${DOCKER} pull "${i}"
    fi
    ${DOCKER} save > ${DEPLOY_LOCAL_WORKDIR}/tmp-image.tar "${i}"
    ${KIND} load image-archive --name="${KIND_CLUSTER_NAME}" ${DEPLOY_LOCAL_WORKDIR}/tmp-image.tar
    rm -f ${DEPLOY_LOCAL_WORKDIR}/tmp-image.tar
  done

  info "Pulling and loading images...OK"
}

####################
# Print summary after install
####################

function print-summary {
  cat << EOF

👏 Congratulations! The capabilities-shim demo environment is ready for use!
It launched a kind cluster, installed tools and deployed applitions as following:
- kind ${KIND_VERSION}
- kubectl ${KUBECTL_VERSION}
- helm ${HELM3_VERSION}
- Crossplane ${CROSSPLANE_VERSION}
- OLM ${OLM_VERSION}
- ODLM the latest version
- capabilities-shim ${CAPABILITIES_SHIM_VERSION}

For tools you want to run anywhere, create links in a directory defined in your PATH, e.g:
ln -s -f ${KUBECTL} /usr/local/bin/kubectl
ln -s -f ${KIND} /usr/local/bin/kind
ln -s -f ${HELM} /usr/local/bin/helm

EOF
}

####################
# Main entrance
####################

case $1 in
  "clean")
    install-kind
    kind-down
    ;;
  *)
    start_time=$SECONDS

    install-kind
    install-kubectl
    install-helm
    kind-up
    install-crossplane
    install-olm
    install-odlm
    install-capabilities-shim
    pull-and-load-images
    print-summary

    elapsed_time=$(($SECONDS - $start_time))
    echo "Total elapsed time: $elapsed_time seconds"
    ;;
esac
