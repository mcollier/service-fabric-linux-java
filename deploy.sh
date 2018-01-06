#!/bin/bash

declare subscriptionName="ShareshiftSubscription"
declare keyVaultName="sf-lx-vault"
declare certificateName="mcollier-sf2018-lx-kv"
declare certificatePfxFileName="mcollier-sf2018-lx-kv.pfx"
declare certificatePemFileName="mcollier-sf2018-lx-kv.pem"
declare resourceGroupLocation="eastus2"
declare resourceGroupName="mcollier-sf2018-lx-kv"
declare sfClusterName="mcollier-sf2018-lx-kv"

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
az group deployment create -g $resourceGroupName --template-file azuredeploy-linux-secure.json --parameters @azuredeploy-linux-secure.parameters.json --parameters clusterName=$sfClusterName sourceVaultValue=$sourceVaultId certificateUrlValue=$keyVaultUrl certificateThumbprint=$certThumbprint --verbose
