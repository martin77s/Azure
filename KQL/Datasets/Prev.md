# Prev

Using Prev to get a moving average

    let startTime = ago(1d);  
    let endTime = now();  
    Perf  
    | where TimeGenerated between (startTime .. endTime)  
    | where Computer == "ContosoWeb"  
    | where CounterName == "% Processor Time"  
    | where ObjectName == "Processor"  
    | where InstanceName == " Total"  
    | summarize PctCpuTime = avg(CounterValue) by bin(TimeGenerated,1h)
    | sort by TimeGenerated asc // serialize is implied in any sort  
    | extend movAvg = (PctCpuTime + prev(PctCpuTime, 1, 0) + prev(PctCpuTime, 2, 0))/3.0 
