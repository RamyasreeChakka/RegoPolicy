#!/usr/bin/env bash
#
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT license.
#
# Execute this script in bash in Cloud Shell in Azure Portal or in https://shell.azure.com
# This script creates a AKS Engine cluster and onboards it to Azure Arc
#
# In bash, run this script as 
# bash create_akse_and_onboard_to_arc.sh <resourceGroupName>

if [ $# -ne 1 ]
then
  echo "Error: This script should be invoked with one argument which is resource group name"
  exit 1
fi

echo "This scripts creates a AKS Engine cluster and onboards it to Azure Arc"

resourceGroup=${1}
echo "Resource group name given to script input: ${resourceGroup}"

echo "Using subscription ID '44d01367-c909-4ddc-94ef-9c4a4b34ed23' for creating the AKS Engine cluster"
subscriptionId=44d01367-c909-4ddc-94ef-9c4a4b34ed23
az account set -s $subscriptionId

echo "Using 'westus2' as the resource group region"
region=westus2

echo "Creating resource group ${resourceGroup}"
az group create --name $resourceGroup --location $region

echo "Download AKS Engine cmdlets"
curl -Lo get-akse.sh https://raw.githubusercontent.com/Azure/aks-engine/master/scripts/get-akse.sh
chmod 700 get-akse.sh
./get-akse.sh

echo "Download AKS Engine Azure TLS compliant cluster json"
curl -LO https://raw.githubusercontent.com/RamyasreeChakka/RegoPolicy/master/GateKeeperV3/bugbash/kubernetes_tls_compliant.json

echo "Creating a service principal to use in AKS Engine cluster creation"
echo "Assigning the service principal contibutor permissions to cluster resource group scope"
sp="$(az ad sp create-for-rbac --role "Contributor" --scopes "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup")"
clientId=$(echo $sp | jq .'appId' -r)
clientSecret=$(echo $sp | jq .'password' -r)
echo "Service principal appId: $clientId"
echo "Service principal secret: $clientSecret"
echo "Waiting for 30 seconds for service principal to be available"
sleep 30

echo "Creating AKS Engine cluster"
aks-engine deploy --subscription-id $subscriptionId --dns-prefix $resourceGroup --resource-group $resourceGroup --location $region --api-model kubernetes_tls_compliant.json --client-id $clientId --client-secret $clientSecret
echo "AKS Engine cluster creation completed."

echo "Setting kube context to point to AKS Engine cluster"
cp _output/$resourceGroup/kubeconfig/kubeconfig.$region.json  ~/.kube/config

arcClusterName=${resourceGroup}-arc-cluster
echo "Onboarding AKS Engine cluster to Azure Arc with cluster name: $arcClusterName"

echo "Downloading Arc Azure CLI extensions"
curl -LO https://raw.githubusercontent.com/RamyasreeChakka/RegoPolicy/master/GateKeeperV3/bugbash/connectedk8s-0.1.0-py2.py3-none-any.whl
curl -LO https://raw.githubusercontent.com/RamyasreeChakka/RegoPolicy/master/GateKeeperV3/bugbash/k8sconfiguration-0.1.1-py2.py3-none-any.whl

echo "Adding Arc Azure CLI extensions"
az extension add --source connectedk8s-0.1.0-py2.py3-none-any.whl --yes
az extension add --source k8sconfiguration-0.1.1-py2.py3-none-any.whl --yes

echo "Creating Azure Arc connected cluster with name: $arcClusterName"
az connectedk8s connect --name $arcClusterName --resource-group $resourceGroup
echo "Azure Arc connected cluster creation completed."

arcClusterResourceId="/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.Kubernetes/connectedClusters/$arcClusterName"
echo "Azure Arc connected cluster resource id: $arcClusterResourceId"
echo "Kube config context: $resourceGroup"