# azMigrateRBAC

## Step #1 - Backup Role Assignments

Backup all the role assignments from the source tenant using the PowerShell commands below to login to Azure to the current ("old") tenant, export the roles and permissions, login again to the target ("new") tenant and export the list of users to be used for the mappings.

```powershell
Import-Module AzMigrateRBAC
Initialize-AzureContext -TenantId $oldTenantId
Export-RBAC -Path C:\TargetFolder -SubscriptionId $subscriptionIdToMove
Initialize-AzureContext -TenantId $newTenantId
Export-UserList -Path C:\TargetFolder
```

## Step #2 - Edit the mappings file

Locate the **UserMappings.csv** file and edit it to map the old users in the old tenant to the users in the new tenant. These users need to exist prior the next step.
You can use the **NewTenantUserList.csv** (created in the previous step by running the Export-UserList command) located in the target folder.
Actually, the only mappings you need to have in the **UserMappings.csv** file are the mappings for the identities listed in the **RBAC.htm** file. All the rest can be removed.

## Step #3 - Initiate the transfer

At this step, the Subscription owner in the source tenant can proceed to "Transfer" the subscription from the source tenant to the target tenant.
Do not perform this step without performing step #1 as executing this step will reset all the role assignments in the source tenant and those deleted role assignments cannot be restored from that point of time on-wards.

## Step #4 - Restore Role Assignments

Restore all the role assignments on to the target tenant using the PowerShell commands below to login to Azure to the new tenant

```powershell
Import-Module AzMigrateRBAC
Initialize-AzureContext -TenantId $newTenantId
Import-RBAC -Path C:\TargetFolder
```

## Important notes

- The user initiating the subscription transfer needs to be invited from the source tenant to the destination tenant
- Verify target Management group structure and policies
- Recreate Managed Identities where needed
  See https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/known-issues#will-managed-identities-be-recreated-automatically-if-i-move-a-subscription-to-another-directory
- AKS:
  - Before the import, make sure you update the servicePrincipal for the AKS using:

    ```bash
    AKS_RG=<TheResourceGroupName>
    AKS_NAME=<AksNAme>
    SP_APP_ID=<SpApplicationId>
    SP_PASSWD=<SpPassword>

    az aks update-credentials --resource-group $AKS_RG --name $AKS_NAME --reset-service-principal --service-principal $SP_APP_ID --client-secret $SP_PASSWD
    ```

  - If you need to recreate the ServicePrincipal (and grant the pull permissions on the ACR while you are at it), you can use:

    ```bash

    ACR_NAME=<TheAcrName>
    SERVICE_PRINCIPAL_NAME=<SpName>
    ROLE=acrpull

    ACR_REGISTRY_ID=$(az acr show --name $ACR_NAME --query id --output tsv)
    echo "ACR ID: $ACR_REGISTRY_ID"

    SP_PASSWD=$(az ad sp create-for-rbac --name http://$SERVICE_PRINCIPAL_NAME --scopes $ACR_REGISTRY_ID --role $ROLE --query password --output tsv)
    SP_APP_ID=$(az ad sp show --id http://$SERVICE_PRINCIPAL_NAME --query appId --output tsv)

    echo "Service principal ID: $SP_APP_ID"
    echo "Service principal password: $SP_PASSWD"
    ```

- Azure DevOps:
  - Switch directory at the organization level
  - Update Service Connections if using Service Principals (at the project level as well)
  - Update administrator and users (at the project level as well)
  See https://docs.microsoft.com/en-us/azure/devops/organizations/accounts/faq-azure-access?view=azure-devops#faq-connect

- Checkpoint Cluster
  - If you moved your NVAs to a different tenant, you need to change the credentials used by the cluster to authenticate Azure API calls.
  - Make sure the modified service principal is designated as a Contributor to the cluster resource group.
  - Use the following command to change the credentials used by the Azure HA deamon:

    ```bash
    [Expert@HostName:0]# azure-ha-conf --client-id '00000000-0000-0000-0000-000000000000' --client-secret 'TH3_4PP1D_P4$$W0RD_G03$_H3R3' --force
    ```

    Note: Use single quotes to avoid shell expansion

  - If you are using an older version, you might need to edit the $FWDIR/conf/azure-ha.json file and modify the **client_id** and the **client_secret** attributes.
  - After you modify the changes apply the changes by running:

    ```bash
    [Expert@HostName:0]# $FWDIR/scripts/azure_ha_cli.py reconf
    ```

  - Verify the new configuration by running:

    ```bash
    [Expert@HostName:0]# $FWDIR/scripts/azure_ha_test.py
    ```

  - For more information on the above, see the **Changing the Credentials** section in https://supportcenter.checkpoint.com/supportcenter/portal?eventSubmit_doGoviewsolutiondetails=&solutionid=sk110194#Azure%20HA%20daemon
