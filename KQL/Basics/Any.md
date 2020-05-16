# Any

[Document Ling](https://kusto.azurewebsites.net/docs/query/any-aggfunction.html)

Any is a random row generator. When used with a * it returns a random row

    Perf  
    | summarize any(*)

Use with summarize to get sample from each

    Perf  
    | where ObjectName == "LogicalDisk"  
    | summarize any(ObjectName, CounterName, InstanceName)  

Another example used with summarize

    Perf  
    | where ObjectName == "LogicalDisk"  
    | summarize any(*) by CounterName  