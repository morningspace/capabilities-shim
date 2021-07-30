# Play with Capabilities

For OLM:
```shell
# Apply networking capability
kubectl apply -f configuration/networking/composition/kong-olm.yaml
kubectl apply -f configuration/networking/definition.yaml
kubectl apply -f examples/networking.yaml

# Apply logging capability
kubectl apply -f configuration/logging/composition/eck-olm.yaml
kubectl apply -f configuration/logging/definition.yaml
kubectl apply -f examples/logging.yaml

# Verify
kubectl get networkingclaims
kubectl get networkings
kubectl get kong

kubectl get loggingclaims
kubectl get loggings
kubectl get elasticsearch
kubectl get kibana

kubectl get subscription -n operators
kubectl get csv -n operators

kubectl get objects
```

For ODLM:
```shell
# Apply networking capability
kubectl apply -f configuration/networking/composition/kong-odlm.yaml
kubectl apply -f configuration/networking/definition.yaml
kubectl apply -f examples/networking.yaml

# Apply logging capability
kubectl apply -f configuration/logging/composition/eck-odlm.yaml
kubectl apply -f configuration/logging/definition.yaml
kubectl apply -f examples/logging.yaml

# Verify
kubectl get networkingclaims
kubectl get networkings
kubectl get kong

kubectl get loggingclaims
kubectl get loggings
kubectl get elasticsearch
kubectl get kibana

kubectl get opcon
kubectl get opreg
kubectl get opreq
kubectl get subscription
kubectl get csv

kubectl get objects
```

Clean up
```shell
# Delete networking capability
kubectl delete networkingclaim my-networking-stack

# Delete logging capability
kubectl delete loggingclaim my-logging-stack
```