# Play with Capabilities (ODLM)

## Install Capabilities

After you launch the demo environment, you can install each primary capability individually as below:
```shell
kubectl apply -f demo/examples/networking/odlm.yaml
kubectl apply -f demo/examples/logging/odlm.yaml
```

You can also install the composite capability with all primary capabilities included as below:
```shell
kubectl apply -f demo/examples/all/odlm.yaml
```

## Verify Installation

To verify the installation, run below command to list all `objects` created by capabilities-shim:
```shell
kubectl get objects
```
These `objects` are used to manage the corresponding custom resources recogonized by ODLM to drive the actual installation done by ODLM. When the installation is finished, the column `SYNCED` and `READY` for all `objects` should turn into `TRUE`.

Run below commands to list all `subscription` and `csv` resources created by ODLM:
```shell
kubectl get subscription
kubectl get csv
```
For each primary capability, there should be one `subscription` and one `csv` mapped to it.


Run below command to list all operator pods created by ODLM and the actual workload pods created by the operators:
```shell
kubectl get pods
```

Run below commands to list the OperandConfig, OperandRegistry, and OperandRequest instances created by capabilities-shim to trigger the corresponding custom resource creation driven by ODLM:
```shell
kubectl get opcon
kubectl get opreg
kubectl get opreq
```

Run below commands to list all custom resources created by ODLM to trigger the corresponding workload pods creation driven by the operators:
```shell
kubectl get kong
kubectl get elasticsearch
kubectl get kibana
```

If you install the primary capability individually, you can run below commands to check the readiness for each capability.
```shell
# Check networking capability
kubectl get networkingclaims
kubectl get networkings
```

```shell
# Check logging capability
kubectl get loggingclaims
kubectl get loggings
```
When the installation is finished, the column `READY` for each capability should turn into `TRUE`.


If you install the composite capability with all primary capabilities included, you can run below commands to check the readiness for all capabilities:
```shell
# All capabilities
kubectl get allclaims
kubectl get alls
```
When the installation is finished, the column `READY` for all capabilities should turn into `TRUE`.

## Uninstall Capabilities

To uninstall the capabilities that you have installed on the cluster, just delete the capability claims that you applied. After a few minutes, you should see all the workloads will be terminated and the related custom resources will be deleted.

If you install the primary capability individually, you can run below commands to delete the corresponding capability claims:
```shell
# Delete networking capability
kubectl delete networkingclaim my-networking-stack
# Delete logging capability
kubectl delete loggingclaim my-logging-stack
```

If you install the composite capability with all primary capabilities included, you can run below command to delete the corresponding capability claim:
```shell
# Delete all capabilities
kubectl delete allclaim my-all-stack
```
