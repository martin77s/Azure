# Azure Kubernetes Services (AKS) example

## Set some variables

```code
$demoName = 'maschvar-tfdemo-aks'
$tenantId = 'xxxx-xxxx....'
$subscriptionId = 'xxxx-xxxx....'
$resourceGroupName = 'aksdemo-rg'
$clusterName = 'aksdemo'
```

## Authenticate to Azure

```code
az login -t $tenantId
```

## Select / change the target subscription

```code
az account list --query [*].[name,id] -o tsv
$subscriptionId = 'xxxx-xxxx....'
az account set -s $subscriptionId
```

## Create the service principal

```code
$sp = az ad sp create-for-rbac --role="Contributor" --scopes="/subscriptions/$subscriptionId" -n $demoName | ConvertFrom-Json
```

## Save the environment variables

```code
$env:ARM_SUBSCRIPTION_ID = $subscriptionId
$env:ARM_CLIENT_ID = $sp.appId
$env:ARM_CLIENT_SECRET = $sp.password
$env:ARM_TENANT_ID = $sp.tenant
```

## Create an SSH key pair (WSL or CloudShell)

```code
ssh-keygen -m PEM -t rsa -b 4096
```

## Copy the SSH key pair locally

```code
copy \\wsl$\Ubuntu\home\sadmind\.ssh\id* .\.ssh\ -passthru
```

## Initialize Terraform

```code
terraform init
```

## Validate the configuration

```code
terraform plan
```

## Apply the deployment

```code
terraform apply
```

## Get the cluster credentials

```code
az aks get-credentials -g $resourceGroupName -n $clusterName
```

## Remove the deployment

```code
terraform destroy
```

## Remove the service principal

```code
$spId = (az ad sp list --spn http://$demoName -o json | ConvertFrom-Json).objectId
az ad sp delete --id $spId
```
