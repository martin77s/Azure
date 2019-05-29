function Get-ADUserExtendedAttribute {
    param($Path, $Attribute = 'extensionAttribute10')
    if( -not (Test-Path -Path $Path)) {
        throw 'input file does not exist!'
    } else {
        $users = Get-Content -Path $Path
        $users | ForEach-Object {
            Get-ADUser -Identity $_ -Properties $Attribute |
                 Select-Object SamAccountName, UserPrincipalName, $Attribute
        }
    }
}


function Set-ADUserExtendedAttribute {
    param($Path, $Attribute = 'extensionAttribute10', $Value = 'AADSync')
    if( -not (Test-Path -Path $Path)) {
        throw 'input file does not exist!'
    } else {
        $users = Get-Content -Path $Path
        $users | ForEach-Object {
            Set-ADUser -Identity $_ -Add @{$Attribute=$Value}
        }
    }
}


function Clear-ADUserExtendedAttribute {
    param($Path, $Attribute = 'extensionAttribute10')
    if( -not (Test-Path -Path $Path)) {
        throw 'input file does not exist!'
    } else {
        $users = Get-Content -Path $Path
        $users | ForEach-Object {
            Set-ADUser -Identity $_ -Clear $Attribute
        }
    }
}


Get-ADUserExtendedAttribute -Path 'C:\Temp\users.txt' -Attribute 'extensionAttribute10'

Set-ADUserExtendedAttribute -Path 'C:\Temp\users.txt' -Attribute 'extensionAttribute10' -Value 'AADSync' 
Get-ADUserExtendedAttribute -Path 'C:\Temp\users.txt' -Attribute 'extensionAttribute10'

Clear-ADUserExtendedAttribute -Path 'C:\Temp\users.txt' -Attribute 'extensionAttribute10'
Get-ADUserExtendedAttribute -Path 'C:\Temp\users.txt' -Attribute 'extensionAttribute10'