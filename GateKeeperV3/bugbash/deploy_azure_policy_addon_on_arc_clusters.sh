#!/usr/bin/env bash
#
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT license.
#
# Execute this script in bash in Cloud Shell in Azure Portal or in https://shell.azure.com
# This script deploys Azure Policy Add-on on Azure Arc Kubernetes cluster
#
# Pre-requisites
#   1. Kubecontext setup for the Kubernetes cluster
#   2. Kubernetes cluster onboarded to Azure Arc
#   3. Helm 3 installed
#
# In bash, run this script as 
# bash deploy_azure_policy_addon_on_arc_clusters.sh <azureArcClusterResourceId>
# For example
# bash deploy_azure_policy_addon_on_arc_clusters.sh /subscriptions/44d01367-c909-4ddc-94ef-9c4a4b34ed23/resourceGroups/ramya-rg-test211-arc/providers/Microsoft.Kubernetes/connectedClusters/ramya-rg-test211-arc-cluster

if [ $# -ne 1 ]
then
  echo "Error: This script should be invoked with one argument which is Azure Arc Cluster Resource Id"
  exit 1
fi

echo "This script installs Azure policy add-on and OPA Gatekeeper in Azure Arc Kubernetes cluster"

arcClusterResourceId=${1}
echo "Arc Cluster resource id given to script input: ${arcClusterResourceId}"

subscriptionId="$(echo ${1} | cut -d'/' -f3)"
echo "Subscription Id of the Arc cluster: $subscriptionId"
az account set -s $subscriptionId

echo "Registering 'Microsoft.PolicyInsights' RP in the subscription $subscriptionId"
az provider register --namespace 'Microsoft.PolicyInsights' --wait

echo "Creating a service principal for Azure Policy add-on to use to communicate to Azure Policy service"
echo "Assigning the service principal 'Policy Insights Data Writer (Preview)' permissions to Arc cluster resource scope"
sp="$(az ad sp create-for-rbac --role "Policy Insights Data Writer (Preview)" --scopes $arcClusterResourceId)"
clientId=$(echo $sp | jq .'appId' -r)
clientSecret=$(echo $sp | jq .'password' -r)
tenant=$(echo $sp | jq .'tenant' -r)
echo "Service principal appId: $clientId"
echo "Service principal secret: $clientSecret"
echo "Service principal tenant: $tenant"
echo "Waiting for 30 seconds for service principal to be available"
sleep 30

echo "Adding 'control-plane' label to 'kube-system' namespace to exclude kube-system resources from policy evaluation and auditing"
kubectl label namespaces kube-system control-plane=controller-manager

echo "Adding 'control-plane' label to 'azure-arc' namespace to exclude azure-arc resources from policy evaluation and auditing"
kubectl label namespaces azure-arc control-plane=controller-manager

echo "Using helm chart, install the Azure Policy add-on and Gatekeeper on Azure Arc Kubernetes cluster"
helm repo add azure-policy https://raw.githubusercontent.com/RamyasreeChakka/RegoPolicy/master/Kubernetes/helmcharts
helm install azure-policy/azure-policy-addon-arc-connected-clusters --set azurepolicy.env.resourceid=$arcClusterResourceId,azurepolicy.env.clientid=$clientId,azurepolicy.env.clientsecret=$clientSecret,azurepolicy.env.tenantid=$tenant --generate-name