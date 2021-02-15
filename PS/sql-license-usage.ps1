# ----------------------------------------------------------------------------------
#
# Copyright Microsoft Corporation
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ---------------------------------------------------------------------------------
#
# This script provided a simple solution to analyze and track the consolidated utilization of SQL Server licenses 
# by all of the SQL resources in a specific subscription or the entire the account. By default, the script scans 
# all subscriptions the user account has access. Alternatively, you can specify a single subscription or a .CSV file 
# with a list of subscription. The usage report includes the following information for each scanned subscription.
#
# The following resources are in scope for the license utilization analysis:
# - Azure SQL databases (vCore-based purchasing model only) 
# - Azure SQL elastic pools (vCore-based purchasing model only)
# - Azure SQL managed instances
# - Azure SQL instance pools
# - Azure Data Factory SSIS integration runtimes
# - SQL Servers in Azure virtual machines 
# - SQL Servers in Azure virtual machines hosted in Azure dedicated host
#
# NOTE: The script does not calculate usage for Azure SQL resources that use the DTU-based purchasing model
#
# The script accepts the following command line parameters:
# 
# -SubId [subscription_id] | [csv_file_name]        (Accepts a .csv file with the list of subscriptions)
# -UseInRunbook [True] | [False]                    (Required when executed as a Runbook)
# -Server [protocol:]server[instance_name][,port]   (Required to save data to the database)
# -Database [database_name]                         (Required to save data to the database)
# -Cred [credential_object]                         (Required to save data to the database)
# -FilePath [csv_file_name]                         (Required to save data in a .csv format. Ignored if database parameters are specified)
#
# 

param (
    [Parameter (Mandatory= $false)] 
    [string] $SubId, 
    [Parameter (Mandatory= $false)]
    [string] $Server, 
    [Parameter (Mandatory= $false)]
    [PSCredential] $Cred, 
    [Parameter (Mandatory= $false)]
    [string] $Database, 
    [Parameter (Mandatory= $false)]
    [string] $FilePath, 
    [Parameter (Mandatory= $false)]
    [bool] $UseInRunbook = $false, 
    [Parameter (Mandatory= $false)]
    [bool] $IncludeEC = $false
)

function Load-Module ($m) {

    # This function ensures that the specified module is imported into the session
    # If module is already imported - do nothing

    if (!(Get-Module | Where-Object {$_.Name -eq $m})) {
         # If module is not imported, but available on disk then import
        if (Get-Module -ListAvailable | Where-Object {$_.Name -eq $m}) {
            Import-Module $m 
        }
        else {

            # If module is not imported, not available on disk, but is in online gallery then install and import
            if (Find-Module -Name $m | Where-Object {$_.Name -eq $m}) {
                Install-Module -Name $m -Force -Verbose -Scope CurrentUser
                Import-Module $m
            }
            else {

                # If module is not imported, not available and not in online gallery then abort
                write-host "Module $m not imported, not available and not in online gallery, exiting."
                EXIT 1
            }
        }
    }
}

#The following block is required for runbooks only
if ($UseInRunbook){

    # Ensures you do not inherit an AzContext in your runbook
    Disable-AzContextAutosave –Scope Process

    $connection = Get-AutomationConnection -Name AzureRunAsConnection

    # Wrap authentication in retry logic for transient network failures
    $logonAttempt = 0
    while(!($connectionResult) -and ($logonAttempt -le 10))
    {
        $LogonAttempt++
        # Logging in to Azure...
        $connectionResult = Connect-AzAccount `
                            -ServicePrincipal `
                            -Tenant $connection.TenantID `
                            -ApplicationId $connection.ApplicationID `
                            -CertificateThumbprint $connection.CertificateThumbprint

        Start-Sleep -Seconds 5
    }
}else{
    # Ensure that the required modules are imported
    # In Runbooks these modules must be added to the automation account manually

    $requiredModules = @(
        "Az.Accounts",
        "Az.Compute",
        "Az.DataFactory",
        "Az.Resources",
        "Az.Sql",
        "Az.SqlVirtualMachine"
    )

    foreach ($module in $requiredModules){
        Load-Module ($module)
    }
}

# Subscriptions to scan

if ($SubId -like "*.csv") {
    $subscriptions = Import-Csv $SubId
}elseif($SubId -ne $null){
    $subscriptions = [PSCustomObject]@{SubscriptionId = $SubId} | Get-AzSubscription 
}else{
    $subscriptions = Get-AzSubscription
}

write-host $subscriptions

[bool] $useDatabase = $PSBoundParameters.ContainsKey("Server") -and $PSBoundParameters.ContainsKey("Cred") -and $PSBoundParameters.ContainsKey("Database")

#Initialize tables and arrays

if ($useDatabase){
    
    #Database setup

    #$cred = New-Object System.Management.Automation.PSCredential($Username,$Password)
    
    [String] $tableName = "Usage-per-subscription"
    [String] $testSQL = "SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES 
                    WHERE TABLE_SCHEMA = 'dbo' 
                    AND  TABLE_NAME = '$tableName'"
    [String] $createSQL = "CREATE TABLE [dbo].[$tableName](
                    [Date] [date] NOT NULL,
                    [Time] [time](7) NOT NULL,
                    [SubscriptionName] [nvarchar](50) NOT NULL,
                    [SubscriptionID] [nvarchar](50) NOT NULL,
                    [AHB_EC] [int] NULL,
                    [PAYG_EC] [int] NULL,
                    [AHB_STD_vCores] [int] NULL,
                    [AHB_ENT_vCores] [int] NULL,
                    [PAYG_STD_vCores] [int] NULL,
                    [PAYG_ENT_vCores] [int] NULL,
                    [HADR_STD_vCores] [int] NULL,
                    [HADR_ENT_vCores] [int] NULL,
                    [Developer_vCores] [int] NULL,
                    [Express_vCores] [int] NULL)"
    [String] $insertSQL = "INSERT INTO [dbo].[$tableName](
                    [Date],
                    [Time],
                    [SubscriptionName],
                    [SubscriptionID],
                    [AHB_EC],
                    [PAYG_EC],
                    [AHB_STD_vCores],
                    [AHB_ENT_vCores],
                    [PAYG_STD_vCores],
                    [PAYG_ENT_vCores],
                    [HADR_STD_vCores],
                    [HADR_ENT_vCores],
                    [Developer_vCores],
                    [Express_vCores]) 
                    VALUES 
                    ('{0}','{1}','{2}','{3}','{4}','{5}','{6}','{7}','{8}','{9}','{10}','{11}','{12}','{13}')"        
    $propertiesToSplat = @{
        Database = $Database
        ServerInstance = $Server
        User = $Cred.Username
        Password = $Cred.GetNetworkCredential().Password
        Query = $testSQL
    }
       
    # Create table if does not exist
    if ((Invoke-SQLCmd @propertiesToSplat).Column1 -eq 0) {
        $propertiesToSplat.Query = $createSQL
        Invoke-SQLCmd @propertiesToSplat
    }

}else{

    #File setup 
    if (!$PSBoundParameters.ContainsKey("FilePath")) {
        $FilePath = '.\sql-license-usage.csv'
    }

    [System.Collections.ArrayList]$usageTable = @()
    $usageTable += ,(@("Date", "Time", "Subscription Name", "Subscription ID", "AHB ECs", "PAYG ECs", "AHB Std vCores", "AHB Ent vCores", "PAYG Std vCores", "PAYG Ent vCores", "HADR Std vCores", "HADR Ent vCores", "Developer vCores", "Express vCores"))
}

$subtotal = [pscustomobject]@{ahb_std=0; ahb_ent=0; payg_std=0; payg_ent=0; hadr_std=0; hadr_ent=0; developer=0; express=0}
$total = [pscustomobject]@{}
$subtotal.psobject.properties.name | %{$total | Add-Member -MemberType NoteProperty -Name $_ -Value 0}

#Save the VM SKU table for future use

$VM_SKUs = Get-AzComputeResourceSku

Write-Host ([Environment]::NewLine + "-- Scanning subscriptions --")

# Calculate usage for each subscription 

foreach ($sub in $subscriptions){

    if ($sub.State -ne "Enabled") {continue}

    try {
        Set-AzContext -SubscriptionId $sub.Id
    }catch {
        write-host "Invalid subscription: " $sub.Id
        {continue}
    }

    # Reset the subtotals     
    $subtotal.psobject.properties.name | %{$subtotal.$_ = 0}
        
    #Get all logical servers
    $servers = Get-AzSqlServer 

    #Get all SQL database resources in the subscription
    $databases = $servers | Get-AzSqlDatabase

    # Process the vCore-based databases 
    foreach ($db in $databases ){
        if ($db.SkuName -eq "ElasticPool") {continue}

        if ($db.LicenseType -eq "LicenseIncluded") {
            if ($db.Edition -eq "BusinessCritical") {
                $subtotal.ahb_ent += $db.Capacity
            } elseif ($db.Edition -eq "GeneralPurpose") {
                $subtotal.ahb_std += $db.Capacity
            }
        }else{
            if ($db.Edition -eq "BusinessCritical") {
                $subtotal.payg_ent += $db.Capacity
            } elseif ($db.Edition -eq "GeneralPurpose") {
                $subtotal.payg_std += $db.Capacity
            }
        } 
    }

    #Get all SQL elastic pool resources in the subscription
    $pools = $servers | Get-AzSqlElasticPool

    # Process the vCore-based elastic pools 
    foreach ($pool in $pools){
        if ($pool.LicenseType -eq "LicenseIncluded") {
            if ($pool.Edition -eq "BusinessCritical") {
                $subtotal.ahb_ent += $pool.Capacity
            } elseif ($pool.Edition -eq "GeneralPurpose") {
                $subtotal.ahb_std += $pool.Capacity
            }
        }else{
            if ($pool.Edition -eq "BusinessCritical") {
                $subtotal.payg_ent += $pool.Capacity
            } elseif ($pool.Edition -eq "GeneralPurpose") {
                $subtotal.payg_std += $pool.Capacity
            }
        }
    }

    #Get all SQL managed instance resources in the subscription
    $instances = Get-AzSqlInstance

    # Process the SQL managed instances with License Included and add to VCore count
    foreach ($ins in $instances){
        if ($ins.InstancePoolName -eq $null){
            if ($ins.LicenseType -eq "LicenseIncluded") {
                if ($ins.Sku.Tier -eq "BusinessCritical") {
                    $subtotal.ahb_ent += $ins.VCores
                } elseif ($ins.Sku.Tier -eq "GeneralPurpose") {
                    $subtotal.ahb_std += $ins.VCores
                }
            }else{
                if ($ins.Edition -eq "BusinessCritical") {
                    $subtotal.payg_ent += $pool.Capacity
                } elseif ($ins.Edition -eq "GeneralPurpose") {
                    $subtotal.payg_std += $ins.Capacity
                }        
            }
        }
    }

    #Get all instance pool resources in the subscription
    $ipools = Get-AzSqlInstancePool

    # Process the instance pools 
    foreach ($ip in $ipools){
        if ($ip.LicenseType -eq "LicenseIncluded") {
            if ($ip.Edition -eq "BusinessCritical") {
                $subtotal.ahb_ent += $ip.VCores
            } elseif ($ip.Edition -eq "GeneralPurpose") {
                $subtotal.ahb_std += $ip.VCores
            }
        }else{
            if ($ip.Edition -eq "BusinessCritical") {
                $subtotal.payg_ent += $ip.Capacity
            } elseif ($ip.Edition -eq "GeneralPurpose") {
                $subtotal.payg_std += $ip.Capacity
            }        
        }
    }

     
    #Get all SSIS imtegration runtime resources in the subscription
    $ssis_irs = Get-AzResourceGroup | Get-AzDataFactoryV2 | Get-AzDataFactoryV2IntegrationRuntime

    # Get the VM size, match it with the corresponding VCPU count and add to VCore count
    foreach ($ssis_ir in $ssis_irs){
        # Select first size and get the VCPus available
        $size_info = $VM_SKUs | where { $_.Name -like $ssis_ir.NodeSize} | Select-Object -First 1
        
        # Save the VCPU count
        $vcpu= $size_info.Capabilities | Where-Object {$_.name -eq "vCPUsAvailable"}

        if ($ssis_ir.State -eq "Started"){      
            if ($ssis_ir.LicenseType -like "LicenseIncluded"){
                if ($ssis_ir.Edition -like "Enterprise"){
                    $subtotal.ahb_ent += $vcpu.value
                }elseif ($ssis_ir.Edition -like "Standard"){
                    $subtotal.ahb_std += $vcpu.value
                }
            }elseif ($data.license -like "BasePrice"){ 
                if ($ssis_ir.Edition -like "Enterprise"){
                    $subtotal.payg_ent += $vcpu.value
                }elseif ($ssis_ir.Edition -like "Standard"){
                    $subtotal.payg_std += $vcpu.value
                }elseif ($ssis_ir.Edition -like "Developer"){
                    $subtotal.developer += $vcpu.value             
                }elseif ($ssis_ir.Edition -like "Express"){
                    $subtotal.express += $vcpu.value
                }
            }
        }
    }
    
    
    #Get All SQL VMs resources in the subscription
    $sql_vms = Get-AzSqlVM 

    # Get the VM size, match it with the corresponding VCPU count and add to VCore count
    foreach ($sql_vm in $sql_vms){
        $vm = Get-AzVm -Name $sql_vm.Name -ResourceGroupName $sql_vm.ResourceGroupName
        $vm_size = $vm.HardwareProfile.VmSize
        # Select first size and get the VCPus available
        $size_info = $VM_SKUs | where {$_.ResourceType.Contains('virtualMachines') -and $_.Name -like $vm_size} | Select-Object -First 1
        # Save the VCPU count
        $vcpu= $size_info.Capabilities | Where-Object {$_.name -eq "vCPUsAvailable"}

        if ($vcpu){
            $data = [pscustomobject]@{vm_resource_uri=$vm.Id;sku=$sql_vm.Sku;license=$sql_vm.LicenseType;size=$vm_size;vcpus=$vcpu.value}
        
            if ($data.license -like "DR"){          
                if ($data.sku -like "Enterprise"){
                    $subtotal.hadr_ent += $data.vcpus
                }elseif ($data.sku -like "Standard"){
                    $subtotal.hadr_std += $data.vcpus
                }
            }elseif ($data.license -like "AHUB"){
                if ($data.sku -like "Enterprise"){
                    $subtotal.ahb_ent += $data.vcpus
                }elseif ($data.sku -like "Standard"){
                    $subtotal.ahb_std += $data.vcpus
                }
            }elseif ($data.license -like "PAYG"){ 
                if ($data.sku -like "Enterprise"){
                    $subtotal.payg_ent += $data.vcpus
                }elseif ($data.sku -like "Standard"){
                    $subtotal.payg_std += $data.vcpus
                }elseif ($data.sku -like "Developer"){
                    $subtotal.developer += $data.vcpus             
                }elseif ($data.sku -like "Express"){
                    $subtotal.express += $data.vcpus
                }
            }
        }
    }
    
    # Get All VMs hosts in the subscription
    $host_groups = Get-AzHostGroup 
    
    # Get the dedicated host size, match it with the corresponding VCPU count and add to VCore count
    
    foreach ($host_group in $host_groups){
        
        $vm_hosts = $host_group | Select-Object -Property @{Name = 'HostGroupName'; Expression = {$_.Name}},@{Name = 'ResourceGroupName'; Expression = {$_.ResourceGroupName}} | Get-AzHost
    
        foreach ($vm_host in $vm_hosts){

            $token = (Get-AzAccessToken).Token
            $params = @{
                Uri         = "https://management.azure.com/subscriptions/" + $sub + 
                            "/resourceGroups/" + $vm_host.ResourceGroupName.ToLower() + 
                            "/providers/Microsoft.Compute/hostGroups/" + $host_group.Name + 
                            "/hosts/" + $vm_host.Name + 
                            "/providers/Microsoft.SoftwarePlan/hybridUseBenefits/SQL_" + $host_group.Name + "_" + $vm_host.Name + "?api-version=2019-06-01-preview"
                Headers     = @{ 'Authorization' = "Bearer $token" }
                Method      = 'GET'
                ContentType = 'application/json'
            }
            
            $softwarePlan = Invoke-RestMethod @params
            if ($softwarePlan.Sku.Name -like "SQL*"){
                $size_info = $VM_SKUs | Where-Object {$_.ResourceType.Contains('hostGroups/hosts') -and $_.Name.Contains($vm_host.Sku.Name)} | Select-Object -First 1   
                $cores= $size_info.Capabilities | Where-Object {$_.name -eq "Cores"}     
                $subtotal.ahb_ent += $cores.Value
            }
        }
    }
    
    # Increment the totals and add subtotals to the usage array
    
    $subtotal.psobject.properties.name | %{$total.$_ += $subtotal.$_}
     
    $Date = Get-Date -Format "yyy-MM-dd"
    $Time = Get-Date -Format "HH:mm:ss"
    if ($IncludeEC){
        $ahb_ec = ($subtotal.ahb_std + $subtotal.ahb_ent*4)
        $payg_ec = ($subtotal.payg_std + $subtotal.payg_ent*4)
    }else{
        $ahb_ec = 0
        $payg_ec = 0
    }
    if ($useDatabase){
        $propertiesToSplat.Query = $insertSQL -f $Date, $Time, $sub.Name, $sub.Id, $ahb_ec, $payg_ec, $subtotal.ahb_std, $subtotal.ahb_ent, $subtotal.payg_std, $subtotal.payg_ent, $subtotal.hadr_std, $subtotal.hadr_ent, $subtotal.developer, $subtotal.express
        Invoke-SQLCmd @propertiesToSplat
    }else{
        $usageTable += ,(@( $Date, $Time, $sub.Name, $sub.Id, $ahb_ec, $payg_ec, $subtotal.ahb_std, $subtotal.ahb_ent, $subtotal.payg_std, $subtotal.payg_ent, $subtotal.hadr_std, $subtotal.hadr_ent, $subtotal.developer, $subtotal.express))
    }
}

if ($useDatabase){
    Write-Host ([Environment]::NewLine + "-- Added the usage data to $tableName table --")  
}else{
    
    # Write usage data to the .csv file

     (ConvertFrom-Csv ($usageTable | %{$_ -join ','})) | Export-Csv $FilePath -Append -NoType
    Write-Host ([Environment]::NewLine + "-- Added the usage data to $FilePath --")
}

