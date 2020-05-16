# Count

[Document Link](https://kusto.azurewebsites.net/docs/query/countoperator.html)

Returns the number of rows from query

    Perf  
    | count

Combine with any query

    Perf  
    |  where TimeGenerated >= ago(1h)  
    | where (CounterName == "Bytes Received/sec" or CounterName == "% Processor Time")  
    | where CounterValue > 10  
    | count