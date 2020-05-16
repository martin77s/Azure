# rowcumsum

[Documentation](https://kusto.azurewebsites.net/docs/query/rowcumsumfunction.html)  

Cumulative summary for values in a data set  
Add up the amount of bytes received over the last few hours use second parameter (reset). Below we reset when the computer name changes  

    let fromTime = ago(3h);  
    let thruTime = now();  
    Perf  
    | where TimeGenerated between (fromTime .. thruTime)  
    | where ObjectName == "Network Adapter"  
    | where CounterName == "Bytes Received/sec"  
    | summarize BytesRecPerHour = sum(CounterValue) by Computer, bin TimeGenerated, 1h)  
    | sort by Computer asc, TimeGenerated asc
    | serialize BytesRecToCurrentHour = row_cumsum(BytesRecPerHour)

Use second parameter (reset). Below we reset when the computer name changes

    let fromTime = ago(3h);  
    let thruTime = now();  
    Perf  
    | where TimeGenerated between (fromTime .. thruTime)  
    | where ObjectName == "Network Adapter"  
    | where CounterName == "Bytes Received/sec"  
    | summarize BytesRecPerHour = sum(CounterValue) by Computer, bin(TimeGenerated, 1h)  
    | sort by Computer asc, TimeGenerated asc  
    | serialize BytesRecToCurrentHour = row_cumsum(BytesRecPerHour, Computer != prev(Computer))