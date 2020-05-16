# Aggregate function

[Summarize Documentation](https://kusto.azurewebsites.net/docs/query/summarizeoperator.html)  
[Bin Documentation](https://kusto.azurewebsites.net/docs/query/binfunction.html)

Count number of rows by a column. Below give the number of collections by CounterName
> Perf  
> | summarize count() by CounterName

Count by multiple columns. Below give the number of collection by unique ObjectName, CounterName, and InstanceName combinations
> Perf  
> | summarize count() by ObjectName,CounterName,InstanceName

Rename count column
> Perf  
> | summarize PerfCount=count() by ObjectName,CounterName,InstanceName

Add average value
> Perf  
> | where CounterName == "% Free Space"  
> | summarize NumberofEntries=count(), AverageFreeSpace=avg(CounterValue) by ObjectName,CounterName,InstanceName

Bin allows you to summarize into logical groups. Below we bet the number of entries in 1 day increments
> Perf  
> | summarize NumberOfEntries=count() by bin(TimeGenerated, 1d)

Bin at multiple levels

    Perf  
    | summarize NumberOfEntries=count() by CounterName, bin(TimeGenerated, 1d)

Bin by non-date. Bin is typically used on dates but not always. Below we are looking at % Free Space and getting the count for each 10% interval

- 0\-10%
- 10\-20%
- 20\-30%
- etc..

Below we be the count of samples withing each 10 percent bucket

    Perf  
    | where CounterName == "% Free Space"  
    | summarize NumberOfRowsAtThisPercentLevel=count() by bin(CounterValue,10)

Get latest value from each computer using arg_max

- Filter to look at Logical Disk Free Space
- Use arg_max to get the last sample (TimeGenerated) for each Computer and InstanceName combination

Below we get the last disk free space for each unique Computer and Disk combination

    Perf  
    | where ObjectName == "LogicalDisk"  
    | where CounterName == "% Free Space"  
    | summarize arg_max(TimeGenerated, *) by Computer, InstanceName  
    | project Computer , InstanceValue , TimeGenerated , CounterValue  
    | order by Computer