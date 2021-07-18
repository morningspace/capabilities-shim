# Play with ODLM

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