# Bin

[Documentation](https://kusto.azurewebsites.net/docs/query/binfunction.html)

Bin allows you to summarize into logical groups. Below we bet the number of entries in 1 day increments

    Perf  
    | summarize NumberOfEntries=count() by bin(TimeGenerated, 1d)

Bin at multiple levels

    Perf  
    | summarize NumberOfEntries=count() by CounterName, bin(TimeGenerated, 1d)

Bin by non-date. Bin is typically used on dates but not always. Below we are looking at % Free Space and getting the count for each 10% interval

- 0\-10%
- 10\-20%
- 20\-30%
- etc..  

Below we bin the Free Space into buckets of 10

    Perf  
    | where CounterName == "% Free Space"  
    | summarize NumberOfRowsAtThisPercentLevel=count() by bin(CounterValue,10)
