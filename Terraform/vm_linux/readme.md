# Azure Linux VM example

## Set some variables

```code
$demoName = 'maschvar-tfdemo'
$tenantId = 'xxxx-xxxx....'
$subscriptionId = 'xxxx-xxxx....'
```

## Authenticate to Azure

```code
az login -t $tenantId
```

## Select / change the target subscription

```code
az account list --query [*].[name,id] -o tsv
$subscriptionId = 'xxxx-xxxx....'
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

## Remove the deployment

```code
terraform destroy
```

## Remove the service principal

```code
$spId = (az ad sp list --spn http://$demoName -o json | ConvertFrom-Json).objectId
az ad sp delete --id $spId
```
