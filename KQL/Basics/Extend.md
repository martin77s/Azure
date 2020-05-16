# Extend

[Documentation Link](https://kusto.azurewebsites.net/docs/query/extendoperator.html)

Extend creates a calculated column and adds to the result set

    Perf  
    | where CounterName == "Free Megabytes"  
    | extend FreeGB = CounterValue / 1024

Extend multiple columns

    Perf  
    | where CounterName == "Free Megabytes"  
    | extend FreeGB = CounterValue / 1024 , FreeKB = CounterValue * 1024

Repeat a column

    Perf  
    | where CounterName == "Free Megabytes"  
    | extend FreeGB = CounterValue / 1024, FreeMB = CounterValue, FreeKB = CounterValue * 1024

Create new string columns

    Perf  
    | where TimeGenerated >= ago(1h)  
    | extend ObjectCounter = strcat(ObjectName," - ", CounterName)
