# View logs and constraints

## Logs
### 1. View Azure policy addon logs by running below command
```bash
kubectl get pods -n kube-system
    - Note the azure-policy pod name.

kubectl logs [azure policy pod name] -n kube-system
```

## Constraints
### 1. To view the list of constraint templates installed
```bash
kubectl get crd

Example output:
NAME                                                 CREATED AT
configs.config.gatekeeper.sh                         2019-10-14T20:04:19Z
constrainttemplates.templates.gatekeeper.sh          2019-10-14T20:04:19Z
k8sallowedrepos.constraints.gatekeeper.sh            2019-10-14T20:05:16Z
k8scontainerallowedports.constraints.gatekeeper.sh   2019-10-15T22:01:38Z
k8scontainerlimits.constraints.gatekeeper.sh         2019-10-15T00:25:22Z
k8scontainernoprivilege.constraints.gatekeeper.sh    2019-10-15T21:53:43Z
```

### 2. To view the list of constraints associated with a template
```bash
Kubectl get <constraintTemplate>

Example: kubectl get k8sallowedrepos.constraints.gatekeeper.sh

Example output:
NAME                                                                                                     AGE
azurepolicy-prodrepoisopenpolicyagent-4179eb30365bed91719e0b30945c4a98900426d5835e2f7423a865499c699d20   1d
```

### 3. To view the constraint and its violations
```bash
Kubectl get [crd name] [constraint name] -o yaml

Example:
kubectl get k8sallowedrepos.constraints.gatekeeper.sh azurepolicy-prodrepoisopenpolicyagent-4179eb30365bed91719e0b30945c4a98900426d5835e2f7423a865499c699d20 -o yaml
```