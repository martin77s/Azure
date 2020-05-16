# Search

[Document Link](https://kusto.azurewebsites.net/docs/query/searchoperator.html)

Search for anything in Perf with Memory in the name (not case sensative)  
> Perf  
> | search "memory"

Same search but case sensative  
> Perf  
> | search kind=case_sensitive "memory"

Search entire database across all tables  
> Search "Memory"

Search within specific tables  
> Search in (Perf, Event, Alert) "Contoso"

Search specific column within table  
> Perf  
> | search CounterName=="Available MBytes"

Search anywhere in specific column  
> Perf  
> | search CounterName:"MBytes"

Search on wildcards
> Perf  
> | search "*Bytes*"

Search using startswith  
> Perf  
> | search * startswith "Bytes"

Search using endswith  
> Perf  
> | search * endswith "Bytes"

Search with wildcard in middle of string
> Perf  
> | search "Free*Bytes"

Combining search logic

    Perf  
    | search "Free*Bytes" and ("C:" or "D:")

Search with regular expression

    Perf  
    | search InstanceName matches regex "[A-Z]:"