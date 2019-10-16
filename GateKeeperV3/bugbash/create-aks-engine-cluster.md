# Create AKS Engine cluster

### 1. Log on to Azure portal and launch cloud shell.

### 2. Set Azure subscription in cloud shell
```bash
	az account set -s [subscription ID]
    
    Example: az account set -s 44d01367-c909-4ddc-94ef-9c4a4b34ed23
```

### 3. Create a resource group.
```bash
	az group create --name [resource group name] --location [location]
    
    Example: az group create --name ramya-perf30-akse-test1 --location westus2
```

### 4. Create a service principal and assign contributor permissions on above resource group.
```bash
    az ad sp create-for-rbac --role "Contributor" --scopes [resource group ID]

	Example: az ad sp create-for-rbac --role "Contributor" --scopes "/subscriptions/44d01367-c909-4ddc-94ef-9c4a4b34ed23/resourceGroups/ramya-perf30-akse-test1"
```

### 5. Note the appID and password generated from the output of the above command.
```bash
    Example output:

	{
	  "appId": "132c8de5-3818-41c2-9a38-16d1f70ed0eb",
	  "displayName": "azure-cli-2019-10-08-18-03-33",
	  "name": "http://azure-cli-2019-10-08-18-03-33",
	  "password": "11111111-2d09-4878-9c35-a5b966187633",
	  "tenant": "72f988bf-86f1-41af-91ab-2d7cd011db47"
	}
```
	
### 6. Note appID and password of the service principal. These values will be used in below commands.
	
### 7. Copy https://github.com/Azure/aks-engine/blob/master/examples/kubernetes.json to your desktop and upload it to cloud shell.

### 8. Create the cluster using below command.
```bash
	aks-engine deploy --subscription-id [subscription ID] --dns-prefix [cluster name] --resource-group [resource group name] --location [location] --api-model kubernetes.json --client-id [app ID] --client-secret [password]

	Example: aks-engine deploy --subscription-id 44d01367-c909-4ddc-94ef-9c4a4b34ed23 --dns-prefix ramya-perf30-akse-test1 --resource-group ramya-perf30-akse-test1 --location westus2 --api-model kubernetes.json --client-id 132c8de5-3818-41c2-9a38-16d1f70ed0eb --client-secret 9d6e05ca-2d09-4878-9c35-a5b966187633
```
AKS Engine reference link: https://github.com/Azure/aks-engine/blob/master/docs/tutorials/quickstart.md
	
### 9. Connect to cluster using kubectl command by copying the kubeconfig to the kube folder.
```bash
	cp _output/<clusterName>/kubeconfig/kubeconfig.<location>.json  ~/.kube/config

	Example: cp _output/ramya-perf30-akse-test1/kubeconfig/kubeconfig.westus2.json  ~/.kube/config
```
### 10. Test the kubectl connection to cluster by running below command "kubectl cluster-info"
```bash
kubectl cluster-info

Example output:
Kubernetes master is running at https://ramya-perf30-akse-test1.westus2.cloudapp.azure.com
CoreDNS is running at https://ramya-perf30-akse-test1.westus2.cloudapp.azure.com/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
kubernetes-dashboard is running at https://ramya-perf30-akse-test1.westus2.cloudapp.azure.com/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy
Metrics-server is running at https://ramya-perf30-akse-test1.westus2.cloudapp.azure.com/api/v1/namespaces/kube-system/services/https:metrics-server:/proxy
```