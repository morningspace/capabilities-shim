# The version of kind
KIND_VERSION=${KIND_VERSION:-v0.11.1}
# The version of kubectl
KUBECTL_VERSION=${KUBECTL_VERSION:-v1.17.11}
# The version of helm
HELM3_VERSION=${HELM3_VERSION:-v3.5.3}
# The version of Crossplane
CROSSPLANE_VERSION=${CROSSPLANE_VERSION:-1.3.0}
# The version of OLM
OLM_VERSION=${OLM_VERSION:-v0.18.3}
# The version of capabilities-shim package
CAPABILITIES_SHIM_VERSION=v0.0.1
# The required images to be pulled and loaded
REQUIRED_IMAGES=(
  "docker.io/kong/kong-operator:v0.8.0"
  "docker.io/kong/kubernetes-ingress-controller:1.2"
  "docker.io/kong:2.4"
  "docker.io/ibmcom/ibm-common-service-catalog:latest"
)
