# Between

[Documentation](https://kusto.azurewebsites.net/docs/query/betweenoperator.html)

Get all values between to values

    Perf  
    | where CounterName == "% Free Space"  
    | where CounterValue between (70.0 .. 100.0)

Can also be between dates

    Perf  
    | where CounterName == "% Free Space"  
    | where TimeGenerated between ( startofday(datetime(2018-08-16)) .. endofday(datetime(2018-08-17)) )