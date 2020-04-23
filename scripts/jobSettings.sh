#!/usr/bin/env bash
#
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT license.
#
# This script is executed as one of the steps in GitHub workflow.
# It generates settings that can be shared across steps with in the workflow job.
#
currentDateTime=`date +"%Y%m%d%H%M%S"`

clientId=$(echo "$AZURE_CREDENTIALS" | jq .'clientId' -r)
clientSecret=$(echo "$AZURE_CREDENTIALS" | jq .'clientSecret' -r)
tenantId=$(echo "$AZURE_CREDENTIALS" | jq .'tenantId' -r)
subscriptionId=$(echo "$AZURE_CREDENTIALS" | jq .'subscriptionId' -r)
resourceGroupName=$(echo "testRG${currentDateTime}")

if [ $ClusterType == "aks-engine" ]
then
  clusterName=$(echo "${resourceGroupName}")
else
  clusterName=$(echo "testCluster${currentDateTime}")
fi

echo "::set-output name=ClientId::${clientId}"
echo "::set-output name=ClientSecret::add-mask::${clientSecret}"
echo "::set-output name=TenantId::${tenantId}"
echo "::set-env name=SubscriptionId::${subscriptionId}"
echo "::set-output name=ResourceGroupName::${resourceGroupName}"
echo "::set-output name=ClusterName::${clusterName}"
