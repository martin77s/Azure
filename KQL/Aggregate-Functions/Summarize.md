# Summarize

[Summarize Documentation](https://kusto.azurewebsites.net/docs/query/summarizeoperator.html)  

Count number of rows by a column. Below give the number of collections by CounterName

    Perf  
    | summarize count() by CounterName

Count by multiple columns. Below give the number of collection by unique ObjectName, CounterName, and InstanceName combinations

    Perf  
    | summarize count() by ObjectName,CounterName,InstanceName

Rename count column

    Perf  
    | summarize PerfCount=count() by ObjectName,CounterName,InstanceName

Add average value

    Perf  
    | where CounterName == "% Free Space"  
    | summarize NumberofEntries=count(), AverageFreeSpace=avg(CounterValue) by ObjectName,CounterName,InstanceName
