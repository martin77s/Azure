# Distinct

[Document Link](https://kusto.azurewebsites.net/docs/query/distinctoperator.html)

Returns a list of dedup values for columns from the input dataset

    Perf  
    | distinct ObjectName, CounterName

Get list of all sources that had error event

    Event  
    | where EventLevelName == "Error"  
    | distinct Source