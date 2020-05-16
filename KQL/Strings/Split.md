# Split

[Document Link](https://kusto.azurewebsites.net/docs/query/splitfunction.html)

Break down string into multiple values. Stores them in an array

    Perf  
    | take 100  
    | project Computer  
            , CounterName  
            , CounterValue  
            , CounterPath  
            , CPSplit = split(CounterPath, "\\")

Third parameter lets you call into the array

    Perf  
    | take 100  
    | extend myComputer = split(CounterPath, "\\", 2)  
           , MyObjectInstance = split(CounterPath,"\\",3)  
           , MyCounterName = split(CounterPath,"\\",4)  
    | project Computer  
            , ObjectName  
            , CounterName  
            , InstanceName  
            , myComputer  
            , myObjectInstance  
            , myCounterName

More readable option
> Perf  
> | take 100  
> | extend CounterPathArray = split(CounterPath,"\\")  
> | extend  
> &nbsp;&nbsp;&nbsp;&nbsp;myComputer = CounterPathArray[2]  
> &nbsp;&nbsp;, MyObjectInstance = CounterPathArray[3]  
> &nbsp;&nbsp;, MyCounterName = CounterPathArray[4]  
> | project  
> &nbsp;&nbsp;&nbsp;&nbsp;Computer  
> &nbsp;&nbsp;, ObjectName  
> &nbsp;&nbsp;, CounterName  
> &nbsp;&nbsp;, InstanceName  
> &nbsp;&nbsp;, myComputer  
> &nbsp;&nbsp;, myObjectInstance  
> &nbsp;&nbsp;, myCounterName
