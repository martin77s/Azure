# Take

[Document Link](https://kusto.azurewebsites.net/docs/query/takeoperator.html)

Take is used to grab a random number of rows

    Perf  
    | take 10

Combine it with any query

    Perf  
    |  where TimeGenerated >= ago(1h)  
    | where (CounterName == "Bytes Received/sec" or CounterName == "% Processor Time")  
    | where CounterValue > 0  
    | take 5
