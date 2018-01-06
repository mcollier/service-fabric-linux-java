#!/bin/bash

declare subscriptionName="ShareshiftSubscription"
declare keyVaultName="sf-lx-vault"
declare certificateName="mcollier-sf2018-lx-kv-lad3"
declare certificatePfxFileName="mcollier-sf2018-lx-kv-lad3.pfx"
declare certificatePemFileName="mcollier-sf2018-lx-kv-lad3.pem"
declare resourceGroupLocation="eastus2"
declare resourceGroupName="mcollier-sf2018-lx-kv-lad3"
declare sfClusterName="mcollier-sf2018-lx-kv-lad3"

declare diagStorageAccountName="sfladappdiag201801061"

#az login
#az account set --subscription $subscriptionName

# -- Key Vault-generated Certificates --
# Create a cert with the default policy
az keyvault certificate create --vault-name $keyVaultName --name $certificateName -p @policy.json

# Download the secrete (private key information) associated with the cert
az keyvault secret download --vault-name $keyVaultName --name $certificateName --encoding base64 --file $certificatePfxFileName

# Convert from PFX to PEM. Password is blank. (Likely not needed if on Linux.)
openssl pkcs12 -in $certificatePfxFileName -out $certificatePemFileName -nodes

# -- Get the values from Key Vault to use in the ARM template --
# Source vault ID
declare sourceVaultId=$(az keyvault show --name $keyVaultName --query id -o tsv)

# Certificate thumbprint
declare certThumbprint=$(az keyvault certificate show --vault-name $keyVaultName --name $certificateName --query x509ThumbprintHex -o tsv)

# Certificate URL
declare keyVaultUrl=$(az keyvault certificate show --vault-name $keyVaultName --name $certificateName --query sid -o tsv)

az group create --location $resourceGroupLocation --name $resourceGroupName --tags "alias=mcollier" "deleteAfter=03/31/2018"

# LAD setup
# Create the storage account. May be a better way to do this with nested ARM templates?
# az storage account check-name --name sfladappdiag20180106 --query nameAvailable -o tsv
az storage account create -g $resourceGroupName -l $resourceGroupLocation --name $diagStorageAccountName --kind StorageV2
declare sasToken=$(az storage account generate-sas --account-name $diagStorageAccountName --expiry 9999-12-31T23:59Z --permissions wlacu --resource-types co --services bt -o tsv)

az group deployment create -g $resourceGroupName --template-file azuredeploy-linux-secure-lad3.json --parameters @azuredeploy-linux-secure.parameters.json --parameters clusterName=$sfClusterName sourceVaultValue=$sourceVaultId certificateUrlValue=$keyVaultUrl certificateThumbprint=$certThumbprint applicationDiagnosticsStorageAccountName=$diagStorageAccountName applicationDiagnosticsStorageAccountSasToken=$sasToken --verbose
