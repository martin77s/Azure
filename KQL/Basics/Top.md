# Top

[Document Link](https://kusto.azurewebsites.net/docs/query/topoperator.html)

The first N rows of the dataset when the dataset is sorted

    Perf  
    | top 20 by TimeGenerated desc

Get top 25 Free Megabytes  

    Perf  
    | where CounterName == "Free Megabytes" and TimeGenerated >= ago(1h)  
    | summarize AvgFreeMegabytes=round(avg(CounterValue),0) by Computer  
    | top 25 by AvgFreeMegabytes asc