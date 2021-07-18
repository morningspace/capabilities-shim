# Prepare Environment

Relaunch a new kind (in provider-kubernetes root folder):
```shell
make local.down
make local-dev
```

Launch proxy:
```shell
kubectl proxy --port=8081
```

Pre-load docker images from Docker Hub into kind:
```shell
docker pull kong/kong-operator:v0.8.0
docker pull kong/kubernetes-ingress-controller:1.2
docker pull kong:2.4
docker pull ibmcom/ibm-common-service-catalog:latest
# docker pull docker.elastic.co/elasticsearch/elasticsearch:7.13.3
# docker pull docker.elastic.co/kibana/kibana:7.13.3
kind load docker-image kong/kong-operator:v0.8.0 --name local-dev
kind load docker-image kong/kubernetes-ingress-controller:1.2 --name local-dev
kind load docker-image kong:2.4 --name local-dev
kind load docker-image ibmcom/ibm-common-service-catalog:latest --name local-dev
# kind load docker-image docker.elastic.co/elasticsearch/elasticsearch:7.13.3 --name local-dev
# kind load docker-image docker.elastic.co/kibana/kibana:7.13.3 --name local-dev
docker exec -it local-dev-control-plane crictl images | grep docker.io
```

Config cluster config for crossplane:
```shell
KUBECONFIG=$(kind get kubeconfig --name local-dev | sed -e 's|server:\s*.*$|server: http://localhost:8081|g')
kubectl -n crossplane-system create secret generic cluster-config --from-literal=kubeconfig="${KUBECONFIG}" 
```

Install OLM:
```shell
OLM_VERSION=v0.18.2
curl -L https://github.com/operator-framework/operator-lifecycle-manager/releases/download/$OLM_VERSION/install.sh | sed 's/set -e//g' | bash -s $OLM_VERSION
```

Install ODLM:
```shell
# curl -L https://github.com/morningspace/capabilities-shim/releases/download/v0.0.1/odlm-deployment.yaml | kubectl apply -f -
# curl -L https://github.com/morningspace/capabilities-shim/releases/download/v0.0.1/odlm-rbac.yaml | kubectl apply -f -
kubectl apply -f configuration/odlm/odlm-deployment.yaml
kubectl apply -f configuration/odlm/odlm-rbac.yaml
```

Launch provider outside kind:
```shell
make run
```

Setup provider config and rbac:
```shell
# curl -L https://github.com/morningspace/capabilities-shim/releases/download/v0.0.1/provide-config.yaml | kubectl apply -f -
# curl -L https://github.com/morningspace/capabilities-shim/releases/download/v0.0.1/provide-rbac.yaml | kubectl apply -f -
kubectl apply -f configuration/provider/provider-config.yaml
kubectl apply -f configuration/provider/provider-rbac.yaml
```
