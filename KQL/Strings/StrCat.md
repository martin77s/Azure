# StrCat

[Document Link](https://kusto.azurewebsites.net/docs/query/strcatfunction.html)

Combine fields together

    Perf  
    | take 100  
    | extend CompObjCounter = strcat(Computer, " - ", ObjectName, " - " , CounterName)  
    | project CompObjCounter  
            , TimeGenerated  
            , CounterValue

We can utilize this for charting. Below we combine the computer name with the disk name so we can easily chart the values

    Perf  
    | where ObjectName == "LogicalDisk"  
    | where CounterName == "% Free Space"  
    | where TimeGenerated >= ago(1d)  
    | extend ChartName = iif( ObjectName == "LogicalDisk", strcat(Computer, " - ", InstanceName), Computer)  
    | project ChartName  
            , TimeGenerated  
            , CounterValue
