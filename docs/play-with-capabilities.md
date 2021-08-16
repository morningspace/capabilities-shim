# Play with Capabilities

For OLM:
```shell
# Apply networking capability
kubectl apply -f capabilities/networking/composition/olm.yaml
kubectl apply -f capabilities/networking/definition.yaml
kubectl apply -f demo/examples/networking/olm.yaml

# Apply logging capability
kubectl apply -f capabilities/logging/composition/olm.yaml
kubectl apply -f capabilities/logging/definition.yaml
kubectl apply -f demo/examples/logging/olm.yaml

# Apply all capabilities
kubectl apply -f capabilities/all/composition/olm.yaml
kubectl apply -f capabilities/all/definition.yaml
kubectl apply -f demo/examples/all/olm.yaml

# Verify
kubectl get objects

kubectl get subscription -n operators
kubectl get csv -n operators

kubectl get pods
kubectl get pods -n operators

kubectl get kong

kubectl get elasticsearch
kubectl get kibana

kubectl get networkingclaims
kubectl get networkings

kubectl get loggingclaims
kubectl get loggings

kubectl get allclaims
kubectl get alls
```

For ODLM:
```shell
# Apply networking capability
kubectl apply -f capabilities/networking/composition/odlm.yaml
kubectl apply -f capabilities/networking/definition.yaml
kubectl apply -f demo/examples/networking/odlm.yaml

# Apply logging capability
kubectl apply -f capabilities/logging/composition/odlm.yaml
kubectl apply -f capabilities/logging/definition.yaml
kubectl apply -f demo/examples/logging/odlm.yaml

# Apply all capabilities
kubectl apply -f capabilities/all/composition/odlm.yaml
kubectl apply -f capabilities/all/definition.yaml
kubectl apply -f demo/examples/all/odlm.yaml

# Verify
kubectl get objects

kubectl get subscription
kubectl get csv

kubectl get pods

kubectl get kong

kubectl get elasticsearch
kubectl get kibana

kubectl get opcon
kubectl get opreg
kubectl get opreq

kubectl get networkingclaims
kubectl get networkings

kubectl get loggingclaims
kubectl get loggings

kubectl get allclaims
kubectl get alls
```

Clean up
```shell
# Delete networking capability
kubectl delete networkingclaim my-networking-stack

# Delete logging capability
kubectl delete loggingclaim my-logging-stack

# Delete all capabilities
kubectl delete allclaim my-all-stack
```