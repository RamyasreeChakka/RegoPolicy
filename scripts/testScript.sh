#
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT license.
#
subscription="44d01367-c909-4ddc-94ef-9c4a4b34ed23"
az account set -s 44d01367-c909-4ddc-94ef-9c4a4b34ed23
echo "This script creates a test AKS Engine cluster in subscription ${subscription}"

location="westus2"
testResourceGroup=$(echo "testRG`date +"%Y%m%d%H%M%S"`")
echo "Creating test resource group: ${testResourceGroup}"
az group create --name ${testResourceGroup} --location ${location}

echo "Fetching AKS Engine binary"
curl -o get-akse.sh https://raw.githubusercontent.com/Azure/aks-engine/master/scripts/get-akse.sh
chmod 700 get-akse.sh
./get-akse.sh

echo "Create AKS Engine cluster"
aks-engine version
if [ $? -eq 0 ]
then
  echo "Successfully created AKS Engine cluster"
else
  echo "Failed to create AKS Engine cluster"
  exit 1
fi
