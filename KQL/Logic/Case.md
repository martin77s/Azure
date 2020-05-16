# Case

[Case Documentation](https://kusto.azurewebsites.net/docs/query/casefunction.html)

Used to create labels based on values.  Here we look at % Free Space. If the value is Less than 10 then we label it "Critical", if it is less than 30 but greater then 10 we label it "Warning", anything else we lable it "OK!"

    Perf  
    | where CounterName == "% Free Space"  
    | extend FreeLevel = case( CounterValue < 10, "Critical", CounterValue < 30, "Warning", "OK!")
    | project Computer  
            , InstanceName  
            , FreeLevel

Using case with summarize
> Perf  
> | where CounterName == "% Free Space"  
> | summarize AvgFree=avg(CounterValue) by Computer, InstanceName  
> | extend FreeLevel = case( AvgFree < 10, "Critical", AvgFree < 30, "Warning", "OK!")  
> | project Computer , InstanceName , AvgFree , FreeLevel 