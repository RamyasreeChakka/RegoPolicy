echo "Welcome to GitHub Actions!"
testResourceGroup=$(echo "testRG`date +"%Y%m%d%H%M%S"`")
echo "Test resource group: ${testResourceGroup}"
az account set -s 44d01367-c909-4ddc-94ef-9c4a4b34ed23
az group create --name ${testResourceGroup} --location westus2
