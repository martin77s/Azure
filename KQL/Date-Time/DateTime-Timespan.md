# Working with Dates

How long ago was this counter generated

    Perf  
    | where CounterName == "Avg. Disk sec/Read"  
    | where CounterValue > 0  
    | take 100  
    | extend HowLongAgo=( now() - TimeGenerated )  
    | project Computer  
            , CounterName  
            , CounterValue  
            , TimeGenerated  
            , HowLongAgo

Time since specific date

    Perf  
    | where CounterName == "Avg. Disk sec/Read"  
    | where CounterValue > 0  
    | take 100  
    | extend SinceStartofYear=( TimeGenerated - datetime(2018-01-01) )
    | project Computer  
            , CounterName  
            , CounterValue  
            , TimeGenerated  
            , SinceStartofYear

Convert to hours
> Perf  
> | where CounterName == "Avg. Disk sec/Read"  
> | where CounterValue > 0  
> | take 100  
> | extend HowLongAgo=( now() - TimeGenerated ), TimeSinceStartOfYear = ( TimeGenerated - datetime(2018-01-01) )  
> | extend TimeSineStartOfYearInHours = ( TimeSinceStartOfYear / 1h )  
> | project  
> &nbsp;&nbsp;&nbsp;&nbsp;Computer  
> &nbsp;&nbsp;, CounterName  
> &nbsp;&nbsp;, CounterValue  
> &nbsp;&nbsp;, TimeGenerated  
> &nbsp;&nbsp;, HowLongAgo  
> &nbsp;&nbsp;, TimeSinceStartOfYear  
> &nbsp;&nbsp;, TimeSineStartOfYearInHours 
