# Sum and SumIf

[Sum Documentation](https://kusto.azurewebsites.net/docs/query/sum-aggfunction.html)  
[SumIf Documentation](https://kusto.azurewebsites.net/docs/query/sumif-aggfunction.html)

Sum is simply the grand total for the column

    Perf  
    | where CounterName == "Free Megabytes"  
    | summarize sum(CounterValue)

sumif just adds a condition. Below if the only if the Counter Name = Free Megabytes do we add to the total

    Perf  
    | summarize sumif(CounterValue, CounterName == "Free Megabytes")