# Project

[Document Link](https://kusto.azurewebsites.net/docs/query/projectoperator.html)

Allows you to select a number of columns
> Perf  
> | project ObjectName, CounterName, InstanceName, CounterValue, TimeGenerated

Combine with extend
> Perf  
> | where CounterName == "Free Megabytes"  
> | project ObjectName, CounterName, InstanceName, CounterValue, TimeGenerated  
> | extend FreeGB = CounterValue / 1024, FreeMB = CounterValue, FreeKB = CounterValue * 1024

The below we remove CounterValue from the result set
> Perf  
> | where CounterName == "Free Megabytes"  
> | extend FreeGB = CounterValue / 1024, FreeMB = CounterValue, FreeKB = CounterValue * 1024  
> | project  
> &nbsp;&nbsp;&nbsp;&nbsp;ObjectName  
> &nbsp;&nbsp;, CounterName  
> &nbsp;&nbsp;, InstanceName  
> &nbsp;&nbsp;, CounterValue  
> &nbsp;&nbsp;, TimeGenerated  
> &nbsp;&nbsp;, FreeGB  
> &nbsp;&nbsp;, FreeMB  
> &nbsp;&nbsp;, FreeKB

Project can simulate Extend

    Perf  
    | where CounterName == "Free Megabytes"  
    | project ObjectName  
            , CounterName  
            , InstanceName  
            , TimeGenerated  
            , FreeGB = CounterValue / 1024  
            , FreeMB = CounterValue  
            , FreeKB = CounterValue * 1024

Project all columns but these

    Perf  
    | where TimeGenerated > ago(1h)  
    | project-away TennantId  
                 , SourceSystem  
                 , CounterPath  
                 , MG

Rename column
> Perf  
> | where TimeGenerated > ago(1h)  
> | project-rename myRenameComputer = Computer
