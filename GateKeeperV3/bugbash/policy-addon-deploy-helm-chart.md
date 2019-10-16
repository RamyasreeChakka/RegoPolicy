# Deploy Azure policy addon on AKS Engine using helm chart

## Prerequisites
### 1. AKS Engine already created.
If you didn't create an AKS Engine already, follow the steps specified at https://github.com/RamyasreeChakka/RegoPolicy/blob/master/GateKeeperV3/bugbash/create-aks-engine-cluster.md

### 2. Configure helm on AKS Engine cluster
Helm installation includes the helm client and server side tiller component. Install helm by running below commands in cloud shell.
```bash
curl -LO https://git.io/get_helm.sh

chmod 700 get_helm.sh

./get_helm.sh

kubectl create serviceaccount --namespace kube-system tiller

kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller

helm init --service-account tiller
```

## Azure policy addon onboarding steps
### 1. Install Gatekeeper
```bash
kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/master/deploy/gatekeeper.yaml
```
NOTE: This step will be replaced with the Gatekeeper helm chart deployment.

### 2. Get the service principal associated with the AKS Engine cluster
If you do not know the service principal used for configuring AKS Engine cluster, then run below kubectl commands to get the service principal details.
```bash
Kubectl get pods -n kube-system
    - Note the kube-apiserver pod name

kubectl exec [kube apiserver pod name] -n kube-system cat /etc/kubernetes/azure.json
    - Note the aadClientId value in output
```

### 3. Create a role assignment for the cluster's resource group to enable the cluster to communicate with policy data plane service to fetch policies and to report compliance results.
```bash
az role assignment create --assignee [cluster service principal app id] --scope [cluster resource group ID] --role "Policy Insights Data Writer (Preview)"
```

### 4. Install Azure policy addon using a helm chart by running below commands
```bash
helm repo add azure-policy https://raw.githubusercontent.com/RamyasreeChakka/RegoPolicy/master/Kubernetes/helmcharts

helm install azure-policy/aks-engine-azure-policy-addon --name azure-policy-addon --set azurepolicy.env.resourceid="<cluster resource group id>"
```

### 5. Install sync config for Gatekeeper
```bash
kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/master/demo/basic/sync.yaml
```
NOTE: Currently this step is not part of Azure policy addon helm chart, will include this in the helm chart deployment.

### 6. Add control-plane label to the kube-system namespace
```bash
kubectl label namespaces kube-system control-plane=controller-manager
```
NOTE: Currently this step is not part of Azure policy addon helm chart, will include this in the helm chart deployment.

## Uninstall Azure policy addon and Gatekeeper

### 1. Uninstall Gatekeeper
```bash
kubectl delete -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/master/deploy/gatekeeper.yaml
```

### 2. Uninstall Azure policy addon
```bash
helm del --purge azure-policy-addon
```