# Where

[Document Link](https://kusto.azurewebsites.net/docs/query/whereoperator.html)

Like search but doesn't look across columns. Where limits base on condition

    Perf  
    | where TimeGenerated >= ago(1h)

ago time based values

- d \- days
- h \- hours
- m \- minutes
- s \- seconds
- ms \- milliseconds
- microsecond \- microseconds

Logically add two conditions together

    Perf  
    | where TimeGenerated >= ago(1h)  
    and CounterName == "Bytes Received/sec"  
    and CounterValue > 0

Utilize OR

    Perf  
    | where TimeGenerated >= ago(1h)  
    and (CounterName == "Bytes Received/sec" or CounterName == "% Processor Time")  
    and CounterValue > 0

Multiple where clauses

    Perf  
    |  where TimeGenerated >= ago(1h)  
    | where (CounterName == "Bytes Received/sec" or CounterName == "% Processor Time")  
    | where CounterValue > 0

Simulate search with where

    Perf  
    | where * has "Bytes"

Simulate starts with

    Perf  
    | where * hasprefix "Bytes"

Simulate ends with

    Perf  
    | where * hassuffix "Bytes"

Using contains in where clause
> Perf  
> | where * contains "Bytes"

Where supports regex
> Perf  
> | where InstanceName matches regex "[A-Z]:"
