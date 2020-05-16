# Top-Nested

[Documentation](https://kusto.azurewebsites.net/docs/query/topnestedoperator.html)

Does nested measurements
For example, first get top 3 ObjectNames by count
For each of those get top 3 CounterNames by count

    Perf  
    | top-nested 3 of ObjectName by ObjectCount = count()  
    | top-nested 3 of CounterName by CounterNameCount = count()  
    | sort by ObjectName asc, CounterName asc

You can do different count at each level

    Event  
    | top-nested 5 of Computer by ComputerCount= count()  
    , top-nested 1 of EventLog by EventLogCount = count()  
    , top-nested 3 of Source by SourceCount = count()  
    , top-nested 10 of EventID by EventIDCount = count()  
    | sort by ComputerCount desc , EventLog, EventIDCount  
