# arg_max

[Documentation](https://kusto.azurewebsites.net/docs/query/arg-max-aggfunction.html)

Get latest value from each computer using arg_max

- Filter to look at Logical Disk Free Space
- Use arg_max to get the last sample (TimeGenerated) for each Computer and InstanceName combination

    Perf  
    | where ObjectName == "LogicalDisk"  
    | where CounterName == "% Free Space"  
    | summarize arg_max(TimeGenerated, *) by Computer, InstanceName  
    | project Computer , InstanceValue , TimeGenerated , CounterValue  
    | order by Computer