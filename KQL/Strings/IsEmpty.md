# IsEmpty

[IsEmpty Documentation](https://kusto.azurewebsites.net/docs/query/isemptyfunction.html)  
[IsNull Documentation]https://kusto.azurewebsites.net/docs/query/isnullfunction.html

Matches on empty text. Below we get the count of performance collections that have no InstanceName    

    Perf  
    | where isempty( InstanceName )  
    | count

Below we create a property named InsName that is populated with "NO INSTASNCE NAME" when the InstanceName is empty  

    Perf  
    | where TimeGenerated >= ago(1h)  
    | extend InstName = iif ( isempty(InstanceName), "NO INSTANCE NAME", InstanceName)  
    | project Computer  
            , TimeGenerated
            , InstanceName  
            , InstName  
            , ObjectName  
            , CounterName

For number you use isnull
> Perf  
> | where isnull( SampleCount )  
> | count

Below we create a SampleCountNull property and populate it with "No Sample Count" if the SampleCount is null
> Perf  
> | where TimeGenerated >= ago(1h)  
> | extend SampleCountNull = iif ( isnull(SampleCount), "No Sample Count", tostring(SampleCount))  
> | project 
> &nbsp;&nbsp;&nbsp;&nbsp;Computer  
> &nbsp;&nbsp;, CounterName  
> &nbsp;&nbsp;, SampleCount  
> &nbsp;&nbsp;, SampleCountNull
