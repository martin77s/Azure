# If then else

[Documentation](https://kusto.azurewebsites.net/docs/query/iiffunction.html)

if/then/else logic  Below we look at % Free Space. If value is less than 50 then we label it "Low disk space" and if not we label it "OK!"

    Perf  
    | where CounterName == "% Free Space"  
    | extend FreeState = iif( CounterValue < 50, "Low disk space", "OK!")  
    | project Computer  
            , CounterName  
            , CounterValue  
            , FreeState

Used with dates

    Perf  
    | where CounterName == "% Free Space"  
    | where TimeGenerated between ( ago(5d) .. Now() )  
    | extend CurrentMonth = iif( datepart("month", TimeGenerated) == datepart("month", now() ), "Current Month", " Past Month")  
    | project Computer  
            , InstanceName  
            , CounterValue  
            , CurrentMonth  
            , TimeGenerated
