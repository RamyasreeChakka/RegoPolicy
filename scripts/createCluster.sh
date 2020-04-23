#!/usr/bin/env bash
#
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT license.
#
# This script creates a Kubernetes cluster and will be executed as one of the steps in GitHub workflow.
# This script should be run with below command line arguments:
#   1. Cluster type
#   2. Subscription ID
#   3. Resource group name
#   4. Cluster name
#   5. Client ID
#   6. Client Secret
#
# To execute this script outside of workflow:
#   - Create new environment variable $GITHUB_WORKSPACE and set its value to root of the GitHub project.
#   - Use aks or aks-engine or arc for ClusterType input.
#   - Client ID should have at least contributor permissions on the subscription to create the cluster.
#

if [ $# -ne 6 ]
then
  echo "Error: This script should be invoked with 6 command line arguments."
  exit 1
fi

clusterType=${1}
subscriptionId=${2}
resourceGroupName=${3}
clusterName=${4}
clientId=${5}
clientSecret=${6}
location="westus2"
kubeConfig=""

echo "This script creates a Kubernetes cluster of type ${clusterType} in resource group ${resourceGroupName} in subscription ${subscriptionId}."
echo "Selecting subscription: ${subscriptionId}"
az account set -s $subscriptionId

echo "Creating resource group: ${resourceGroupName} in location: ${location}"
az group create --name ${resourceGroupName} --location ${location}

if [ "$clusterType" == "aks-engine" ]
then
  echo "Fetching AKS Engine binary"
  curl -o get-akse.sh https://raw.githubusercontent.com/Azure/aks-engine/master/scripts/get-akse.sh
  chmod 700 get-akse.sh
  ./get-akse.sh
  
  echo "Creating AKS Engine cluster"
  aks-engine deploy --subscription-id $subscriptionId --dns-prefix $resourceGroupName --resource-group $resourceGroupName --location $location --api-model $GITHUB_WORKSPACE/scripts/kubernetes_tls_compliant.json --client-id $clientId --client-secret $clientSecret

  if [ $? -ne 0 ]
  then
    echo "Failed to create AKS Engine cluster"
    exit 1
  fi
  
  kubeConfig=$(cat _output/$resourceGroupName/kubeconfig/kubeconfig.$location.json)

elif [ "$clusterType" == "aks" ]
then
  echo "Creating AKS cluster"
elif [ "$clusterType" == "arc" ]
then
  echo "Creating Arc cluster"
fi

echo "Setting kubeConfig as output varibale for the script"
echo "::set-output name=KubeConfig::${kubeConfig}"

