# Sort

Sort query

    Perf  
    | where TimeGenerated > ago(1h)  
    | where CounterName=="Avg. Disk sec/Read" and InstanceName=="C:"  
    | project Computer  
            , TimeGenerated  
            , ObjectName  
            , CounterName  
            , InstanceName  
            , CounterValue  
    | sort by Computer, TimeGenerated

Reverse the order

    Perf  
    | where TimeGenerated > ago(1h)  
    | where CounterName=="Avg. Disk sec/Read" and InstanceName=="C:"  
    | project Computer  
            , TimeGenerated  
            , ObjectName  
            , CounterName  
            , InstanceName  
            , CounterValue  
    | sort by Computer asc, TimeGenerated asc
