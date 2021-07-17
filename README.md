# capabilities-shim

Demo transcript:
```
# Relaunch a new kind
make local.down
make local-dev

# Pre-load docker images on Docker Hub
docker pull kong/kong-operator:v0.8.0
docker pull kong/kubernetes-ingress-controller:1.2
docker pull kong:2.4
# docker pull docker.elastic.co/elasticsearch/elasticsearch:7.13.3
# docker pull docker.elastic.co/kibana/kibana:7.13.3
kind load docker-image kong/kong-operator:v0.8.0 --name local-dev
kind load docker-image kong/kubernetes-ingress-controller:1.2 --name local-dev
kind load docker-image kong:2.4 --name local-dev
# kind load docker-image docker.elastic.co/elasticsearch/elasticsearch:7.13.3 --name local-dev
# kind load docker-image docker.elastic.co/kibana/kibana:7.13.3 --name local-dev
docker exec -it local-dev-control-plane crictl images | grep docker.io

# Config cluster config for crossplane
KUBECONFIG=$(kind get kubeconfig --name local-dev | sed -e 's|server:\s*.*$|server: http://localhost:8081|g')
kubectl -n crossplane-system create secret generic cluster-config --from-literal=kubeconfig="${KUBECONFIG}" 

# Install OLM
OLM_VERSION=v0.18.2
curl -L https://github.com/operator-framework/operator-lifecycle-manager/releases/download/$OLM_VERSION/install.sh | sed 's/set -e//g' | bash -s $OLM_VERSION

# Launch proxy
kubectl proxy --port=8081

# Launch out-cluster provider
make run
```