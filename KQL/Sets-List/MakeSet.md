# Makeset

[Documentation](https://kusto.azurewebsites.net/docs/query/makeset-aggfunction.html)

Creates an array of json object by flattening a hierarchy so instead of a row for each unique ObjectName/CounterName combination you get a row for each ObjectName with an array of the CounterNames for it

    Perf  
    | summarize Counters = makeset(CounterName) by ObjectName

Get a list of PCs low on disk space. So puts the values into a single row instead of multiple rows

    Perf  
    | where ObjectName == "LogicalDisk"  
    | where CounterName == "% Free Space"  
    | summarize arg_max(TimeGenerated, CouterValue) by Computer  
    | where CouterValue <= 30  
    | summarize Computers = makeset(Computer)