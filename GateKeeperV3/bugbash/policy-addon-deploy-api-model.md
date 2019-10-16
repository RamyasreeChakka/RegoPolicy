# Create AKS Engine cluster with Azure policy addon using apimodel

With api model, a newly created cluster is deployed with Gatekeeper and Azure policy addon. Currently this scenario is tested using private bits of aks-engine and hence using the desktop instead of cloud shell.

### 1. Install Azure CLI on your desktop
Install from location https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-windows?view=azure-cli-latest

### 2. Download aks-engine binary
1. Download the file from 
https://sertacstorage.blob.core.windows.net/aks-engine-policy-addon-windows/aks-engine
2. Add .exe extension to the file downloaded above

### 3. Open command prompt to the folder location above file downloaded.

### 4. Set Azure subscription in cloud shell
```bash
az account set -s [subscription ID]

Example: az account set -s 44d01367-c909-4ddc-94ef-9c4a4b34ed23
```

### 5. Create a resource group.
```bash
az group create --name [resource group name] --location [location]

Example: az group create --name ramya-perf30-akse-test1 --location westus2
```

### 6. Create a service principal and assign contributor permissions on above resource group.
```bash
az ad sp create-for-rbac --role "Contributor" --scopes [resource group ID]

Example: az ad sp create-for-rbac --role "Contributor" --scopes "/subscriptions/44d01367-c909-4ddc-94ef-9c4a4b34ed23/resourceGroups/ramya-perf30-akse-test1"
```

### 7. Note the appID and password generated from the output of the above command.
```bash
Example output:

{
	  "appId": "8b936c45-8014-4c41-bac9-4ff614301288",
	  "displayName": "azure-cli-2019-10-10-22-32-39",
	  "name": "http://azure-cli-2019-10-10-22-32-39",
	  "password": "111111-bed8-457f-bf4c-5bcec9ac5a72",
	  "tenant": "72f988bf-86f1-41af-91ab-2d7cd011db47"
}
```
	
### 8. Note appID and password of the service principal. These values will be used in below commands.

### 9. Create a role assignment on the service principal to enable Azure policy add-on to communicate to the data plane service to fetch policies and to report compliance results.
```bash
az role assignment create --assignee <cluster service principal app id> --scope <cluster resource group id> --role "Policy Insights Data Writer (Preview)"
```

### 10. Download the api model https://raw.githubusercontent.com/sozercan/aks-engine/azure-policy-addon/examples/addons/azure-policy/azure-policy.json to your desktop

### 11. Create the cluster using below command.
```bash
aks-engine deploy --subscription-id [subscription ID] --dns-prefix [cluster name] --resource-group [resource group name] --location [location] --api-model azure-policy.json --client-id [app ID] --client-secret [password]

Example:
aks-engine deploy --subscription-id 44d01367-c909-4ddc-94ef-9c4a4b34ed23 --dns-prefix ramya-perf30-akse-apimodel-test1 --resource-group ramya-perf30-akse-apimodel-test1 --location westus2 --api-model aks-engine/azure-policy.json --force-overwrite --client-id 8b936c45-8014-4c41-bac9-4ff614301288 --client-secret d0708eca-bed8-457f-bf4c-5bcec9ac5a72
```

### 12. The above command should have created _output folder and a folder with cluster name inside it. Copy the kubeconfig file to $HOME/.kube directory as below
```bash
copy .\_output\ramya-perf30-akse-apimodel-test1\kubeconfig\kubeconfig.westus2.json c:\users\ramya\.kube\config
```

### 13. Test cluster connection by running below command. You should see your cluster information.
```bash
Kubectl cluster-info
```

### 14. Verify Azure policy add-on is installed in kube-system namespace
```bash
kubectl get pods -n kube-system
```