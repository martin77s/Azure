
$rg = 'rg-web'
$appName = 'martin77s'

$ips = @'
12.34.56.0/16
111.111.111.0/22
1000:aaaa::/32
2000:bbbb::/32
'@  -split "`n"

$api = '2018-11-01' # '2016-08-01'
$priority = 7700

$config = (Get-AzResource -ResourceType Microsoft.Web/sites/config -ResourceName $appName -ResourceGroupName $rg -ApiVersion $api)
$res = $config.Properties.ipSecurityRestrictions

$ips | % {
    $rule = [PSCustomObject]@{
        ipAddress = '{0}' -f $_
        action = "Allow"  
        priority = '{0}' -f $priority++
        name = 'WAF'
        description = "Automatically added ip restriction"
    }
    $res.Add($rule) | Out-Null
}

$config.Properties.ipSecurityRestrictions = $res

Set-AzResource -ResourceId $config.ResourceId -Properties $config.Properties -ApiVersion $api -Force


