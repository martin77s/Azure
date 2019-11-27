# Post Deployment script for Windows VMs


# Enable ICMP echo:
New-NetFirewallRule -DisplayName "Allow inbound ICMPv4" -Direction Inbound -Protocol ICMPv4 -IcmpType 8 -Action Allow
New-NetFirewallRule -DisplayName "Allow inbound ICMPv6" -Direction Inbound -Protocol ICMPv6 -IcmpType 8 -Action Allow


# Set VMADMIN password to never expire:
$localAdmin = Get-LocalUser | Where-Object {$_.SID -like 'S-1-5-*-500'} | Select-Object -First 1 -ExpandProperty Name
Set-LocalUser -Name $localAdmin -PasswordNeverExpires 1


# Set the TimeZone:
Set-TimeZone -Id 'Israel Standard Time' 


# Set localization:
$outFile = 'C:\Windows\Temp\locale.xml'
@'
<gs:GlobalizationServices xmlns:gs="urn:longhornGlobalizationUnattend">
 
<!-- user list --> 
    <gs:UserList>
        <gs:User UserID="Current" CopySettingsToDefaultUserAcct="true" CopySettingsToSystemAcct="true"/> 
    </gs:UserList>
 
    <!-- GeoID -->
    <gs:LocationPreferences> 
        <gs:GeoID Value="117"/>
    </gs:LocationPreferences>
 
    <gs:MUILanguagePreferences>
        <gs:MUILanguage Value="en-US"/>
    </gs:MUILanguagePreferences>
 
    <!-- system locale -->
    <gs:SystemLocale Name="he-IL"/>
 
    <!-- input preferences -->
    <gs:InputPreferences>
        <gs:InputLanguageID Action="add" ID="0409:00000409"/>
        <gs:InputLanguageID Action="add" ID="040d:0002040d"/>
      </gs:InputPreferences>
 
    <!-- user locale -->
    <gs:UserLocale>
        <gs:Locale Name="he-IL" SetAsCurrent="true" ResetAllSettings="true">
        </gs:Locale>
    </gs:UserLocale>
 </gs:GlobalizationServices>
'@ | Out-File -FilePath $outFile
C:\Windows\System32\control.exe "intl.cpl,,/f:""$outFile""" | Out-Null


# Restart the VM to complete the changes:
Restart-Computer -Force