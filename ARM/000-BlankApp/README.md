# 000-BlankApp

Starting point for ARM Template development. Copy this 
repository as Zip and start adding Azure resources. 

Folder `deploy` contains `deploy.ps1` deployment
entry script which encapsulates ARM template files 
`azuredeploy.json` (and `azuredeploy.parameters.json`).
You typically publish this folder as build artifact from
VSTS builds.

Development flow:
1. Create Git repository
2. Commit files to the repository
3. Now you should have "clean" working state
4. Start loop
   1. Add/Modify deployment script or ARM template
   2. Execute `deploy.ps1`
   3. Validate the change
   4. Commit you change

Steps to execute deployment using Azure PowerShell: 
```powershell
Login-AzureRmAccount

# *Explicitly* select your working context
Select-AzureRmSubscription -SubscriptionName <YourSubscriptionName>

# Now you're ready!
cd .\deploy\

# Execute deployment with "local" development defaults:
.\deploy.ps1

# Execute deployment with overriding defaults in command-line:
.\deploy.ps1 -ResourceGroupName "blankapp-dev-rg" -Location "North Europe" -DynamicParameter1 "my parameter"

```