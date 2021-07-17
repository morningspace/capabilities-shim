# Play with ODLM

## Preparation

```shell
# Install ODLM
# Create CatalogSource
kubectl apply -f - <<END
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: opencloud-operators
  namespace: olm
spec:
  displayName: IBMCS Operators
  publisher: IBM
  sourceType: grpc
  image: docker.io/ibmcom/ibm-common-service-catalog:latest
  updateStrategy:
    registryPoll:
      interval: 45m
END

# Create Operator Namespace
kubectl apply -f - <<END
apiVersion: v1
kind: Namespace
metadata:
  name: odlm
END

# Create OperatorGroup
kubectl apply -f - <<END
apiVersion: operators.coreos.com/v1alpha2
kind: OperatorGroup
metadata:
  name: odlm-operators
  namespace: odlm
spec:
  targetNamespaces:
  - odlm
END

kubectl apply -f - <<END
apiVersion: v1
data:
  namespaces: odlm,default
kind: ConfigMap
metadata:
  name: odlm-scope
  namespace: odlm
END

# Subscription
kubectl apply -f - <<END
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: operand-deployment-lifecycle-manager
  namespace: odlm
spec:
  channel: v3
  name: ibm-odlm
  source: opencloud-operators
  sourceNamespace: olm
  config:
    env:
    - name: INSTALL_SCOPE
      value: namespaced
END

# Apply rbac
kubectl apply -f configuration/rbac-odlm.yaml

# Check Operator CSV
kubectl get csv -n odlm
```

## Play with ODLM

```shell
# Create OperandConfig instance
kubectl apply -f - <<END
apiVersion: operator.ibm.com/v1alpha1
kind: OperandConfig
metadata:
  name: capabilities
spec:
  services:
  - name: kong
    spec:
      kong: {}
  - name: elastic-cloud-eck
    spec:
      elasticsearch:
        version: 7.13.3
        nodeSets:
        - name: default
          count: 1
          config:
            node.store.allow_mmap: false
      kibana:
        count: 1
        version: 7.13.3
        elasticsearchRef:
          name: elasticsearch-sample
END

# Create OperandRegistry instance
kubectl apply -f - <<END
apiVersion: operator.ibm.com/v1alpha1
kind: OperandRegistry
metadata:
  name: capabilities
spec:
  operators:
  - name: kong
    channel: alpha
    namespace: default
    packageName: kong
    scope: public
    sourceName: operatorhubio-catalog
    sourceNamespace: olm
  - name: elastic-cloud-eck
    channel: stable
    namespace: default
    packageName: elastic-cloud-eck
    scope: public
    sourceName: operatorhubio-catalog
    sourceNamespace: olm
END

# Create OperandRequest instance
kubectl apply -f - <<END
apiVersion: operator.ibm.com/v1alpha1
kind: OperandRequest
metadata:
  name: capabilities
spec:
  requests:
  - registry: capabilities
    registryNamespace: default
    operands:
    - name: kong
      kind: Kong
      apiVersion: charts.helm.k8s.io/v1alpha1
      instanceName: kong-my-networking-stack
      spec: {}
    - name: elastic-cloud-eck
END
```