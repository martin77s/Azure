# Formating Date Time

[Format Date Time](https://kusto.azurewebsites.net/docs/query/format-datetimefunction.html)
[Format Time Span](https://kusto.azurewebsites.net/docs/query/format-timespanfunction.html)

Return specific date format

    Perf  
    | take 100  
    | project CounterName  
            , CounterValue  
            , TimeGenerated  
            , format_datetime(TimeGenerated, "y-M-d")  
            , format_datetime(TimeGenerated, "yyyy-MM-dd")  
            , format_datetime(TimeGenerated, "MM/dd/yyyy")  
            , format_datetime(TimeGenerated, "MM/dd/yyyy hh:mm:ss tt") , format_datetime(TimeGenerated, "MM/dd/yyyy HH:mm:ss")  
            , format_datetime(TimeGenerated, "MM/dd/yyyy HH:mm:ss.ffff")

Supported syntax - one letter is singe number, two letters two numbers

- d \- Day, 1 to 31
- dd \- Day 01 to 31
- M \- Month 1 to 12
- MM \- Month 01 to 12
- y \- Year 0 to 9999
- yy \- Year 00 to 9999
- yyyy \- Year 0000 to 9999
- h \- Hour, 1 to 12
- hh \- Hour 01 to 12
- H \- Hour 1 to 23
- HH \- Hour 01 to 23
- m \- Minute 0 to 59
- mm \- Minute 00 to 59
- s \- Second 0 to 59
- ss \- Second 00 to 59
- tt \- am/pm

format_timespan formats a timespan

    Perf  
    | take 100  
    | project CounterName  
            , CounterValue  
            , TimeGenerated  
            , format_timespan(totimespan(TimeGenerated), "hh:mm:ss")

timespan are typically used with datetime math

    Perf  
    | where TimeGenerated between ( ago(7d) .. Ago(2d) )  
    | extend TimeGen = now() - TimeGenerated  
    | project CounterName  
            , CounterValue  
            , TimeGenerated  
            , TimeGen  
            , format_timespan(TimeGen, "hh:mm:ss")  
            , format_timespan(TimeGen, "HH:mm:ss")  
            , format_timespan(TimeGen, "h:m:s")  
            , format_timespan(TimeGen, "H:m:s")
