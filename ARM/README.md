# ARM Templates and related tools

## VSCode extensions:

1. <a href="https://marketplace.visualstudio.com/items?itemName=msazurermtools.azurerm-vscode-tools" target="_blank">Azure Resource Manager (ARM) Tools</a>
2. <a href="https://marketplace.visualstudio.com/items?itemName=bencoleman.armview" target="_blank">ARM Template Viewer</a>
3. <a href="https://marketplace.visualstudio.com/items?itemName=wilfriedwoivre.arm-params-generator" target="_blank">ARM Params Generator</a>
4. <a href="https://marketplace.visualstudio.com/items?itemName=TabNine.tabnine-vscode" target="_blank">TabNine</a>


## ARM Snippets

Using parameters:
```json
"parameters": {
    "environmentName": {
        "type": "string",
        "allowedValues": [
            "dev",
            "test",
            "prod"
        ],
        "defaultValue": "dev",
        "metadata": {
            "description": "Required. Environment code (dev/test/prod)"
        }
    }
}
```

- - -

Using variables: 
```json
"variables": {
    "environmentSettings": {
        "dev": {
            "appSvcPlanSku": "F1",
            "storageAccountSku": "Standard_LRS"
        },
        "test": {
            "appSvcPlanSku": "F1",
            "storageAccountSku": "Standard_LRS"
        },
        "prod": {
            "appSvcPlanSku": "B1",
            "storageAccountSku": "Standard_ZRS"
        }
    }
 "currentEnvironmentSettings": "[variables('environmentSettings')[parameters('environmentName')]]"
}
```

- - -

Calculating specific environment values:
```json
"sku": {
    "name": "[variables('currentEnvironmentSettings').storageAccountSku]"
}
```

- - -

Get the location for the current resource group:
```json
"[resourceGroup().location]"
```

- - -

Get the subscription ID for the current deployment:
```json
"[subscription().subscriptionId]"
```

- - -

Get the tenant ID for the current deployment :
```json
"[subscription().tenantId]"
```

- - -

Get an App Service host name with reference and resourceId:
```json
"[reference(resourceId('Microsoft.Web/sites', parameters('app_name'))).hostNames[0]]"
```

- - -

Generate a valid URL for an App Service:
```json
"[concat('https://', reference(resourceId('Microsoft.Web/sites', parameters('app_name'))).hostNames[0], '/')]"
```

- - -

Get the outbound public IP addresses for an App Service:
```json
"[reference(resourceId('Microsoft.Web/sites', parameters('app_name'))).outboundIpAddresses]"
```

- - -

Get the Instrumentation Key for Application Insights:
```json
"[reference(resourceId('Microsoft.Insights/components', parameters('app_insight_name'))).InstrumentationKey]"
```

- - -

Generate an Azure SQL DB connection string:
```json
"[concat('Data Source=tcp:', reference(resourceId('Microsoft.Sql/servers', parameters('server_name'))).fullyQualifiedDomainName, ',1433;Initial Catalog=', parameters('db_name'), ';User Id=', parameters('sql_username'), '@', parameters('server_name'), ';Password=', parameters('sql_Password'), ';')]"
```

- - -

Generate an Azure Storage connection string:
```json
"[concat('DefaultEndpointsProtocol=https;AccountName=', parameters('storage_name'), ';AccountKey=', listKeys(resourceId('Microsoft.Storage/storageAccounts', parameters('storage_name')), providers('Microsoft.Storage', 'storageAccounts').apiVersions[0]).keys[0].value)]"
```

- - -

Get the connection string for an Azure Service Bus namespace:
```json
"[listKeys(resourceId('Microsoft.ServiceBus/namespaces/authorizationRules', parameters('namespaces_name'), 'RootManageSharedAccessKey'), providers('Microsoft.ServiceBus', 'namespaces').apiVersions[0]).primaryConnectionString]"
```

- - -

Concat the ResouceId of a resource:
```json
"[concat('/subscriptions/', subscription().subscriptionId, '/resourceGroups/', resourceGroup().name, '/providers/Microsoft.Blah/', variables('blahName'))]",
```

- - -

Conditional resource deployment
```json
    "resources": [
        {
            "condition": "[not(empty(parameters('cuaId')))]",
            "apiVersion": "2018-02-01",
            "name": "[variables('pidName')]",
            "type": "Microsoft.Resources/deployments",
            "properties": {
                "mode": "Incremental",
                "template": {
                    "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
                    "contentVersion": "1.0.0.0",
                    "resources": [
                    ]
                }
            }
        },
    ]
```

- - -

Extract the subscriptionId, ResourceGroup and ResourceName from a ResourceId
```json
"parameters": {
    "vnetResourceId": {
        "type": "string"
    }
}
"variables": {
    "vnetSubscriptionId": "[split(parameters('vnetResourceId'),'/')[2]]",
    "vnetResourceGroupName": "[split(parameters('vnetResourceId'),'/')[4]]",
    "vnetName": "[split(parameters('vnetResourceId'),'/')[8]]",
}
```

- - -

Copy loop example 1:
```json
{
    "type": "Microsoft.Web/sites",
    "apiVersion": "2019-08-01",
    "copy": {
        "name": "webAppsCopy",
        "count": "[length(variables('webApps'))]"
    },
    "name": "[concat(parameters('environment'),variables('applicationPrefix'), '-', variables('webApps')[copyIndex('webAppsCopy')])]",
    "location": "[parameters('location')]",
    "dependsOn": [
        "[resourceId('Microsoft.Web/serverfarms', variables('appServicePlanName'))]"
    ],
    "kind": "app",
    "identity": {
        "type": "SystemAssigned"
    },
    "properties": {
        "enabled": true,
        "serverFarmId": "[resourceId('Microsoft.Web/serverfarms', variables('appServicePlanName'))]",
        "clientAffinityEnabled": true,
        "clientCertEnabled": false,
        "hostNamesDisabled": false,
        "httpsOnly": false
    }
}
```
- - -

Copy loop example 2 (Handle the first item differently):
```json
{
    "type": "Microsoft.Network/routeTables",
    "apiVersion": "2018-11-01",
    "name": "[variables('sqlManagedInstanceRouteTableName')]",
    "location": "[parameters('location')]",
    "properties": {
        "copy": [
            {
                "name": "routes",
                "count": "[length(parameters('sqlManagedInstanceManagementIPs'))]",
                "input": {
                    "name": "[if(equals(copyIndex('routes'),0),'subnet_to_vnetlocal',concat(replace(parameters('sqlManagedInstanceManagementIPs')[copyIndex('routes')],'/','-'),'-next-hop-internet-route'))]",
                    "properties": {
                        "addressPrefix": "[if(equals(copyIndex('routes'),0),parameters('sqlManagedInstanceSubnetAddressRange'),parameters('sqlManagedInstanceManagementIPs')[copyIndex('routes')])]",
                        "nextHopType": "[if(equals(copyIndex('routes'),0),'VnetLocal','Internet')]"
                    }
                }
            }
        ]
    }
}
```

- - - 


Calculate Static IP Address in a CopyLoop:
```json
"parameters": {
    "addressPrefix": {
        "type": "string",
        "defaultValue": "192.168.10.0/24"
    }
}
"variables": {
    "addressPrefixSplit": "[split(parameters('addressPrefix'), '.')]",
    "privateIPAddressOffset": 10
}
"resources": [
    {
        "type": "Microsoft.Network/networkInterfaces",
        "apiVersion": "2018-10-01",
        "copy": {
            "name": "nicLoop",
            "count": "[parameters('vmCount')]"
        },
        "name": "[concat(variables('VmNamePrefix'), copyindex('nicLoop', 1), '-nic')]",
        "location": "[parameters('location')]",
        "properties": {
            "ipConfigurations": [
                {
                    "name": "ipconfig1",
                    "properties": {
                        "subnet": {
                            "id": "[variables('subnetId')]"
                        },
                        "privateIPAllocationMethod": "Static",
                        "privateIPAddress": "[concat(variables('addressPrefixSplit')[0], '.', variables('addressPrefixSplit')[1], '.', variables('addressPrefixSplit')[2], '.', add(variables('privateIPAddressOffset'), copyIndex('nicLoop', 1)))]",
                        "primary": true
                    }
                }
            ]
        }
    }
]
```

- - -

Custom function
```json
"functions": [
    {
        "namespace": "myNameSpace",
        "members": {
            "joinArray": {
                "parameters": [
                    {
                        "name": "items",
                        "type": "array"
                    }
                ],
                "output": {
                    "type": "string",
                    "value": "[replace(replace(replace(string(parameters('items')), '[\"', ''), '\"]', ''), '\",\"', '')]"
                }
            }
        }
    }
]
```