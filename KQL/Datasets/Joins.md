# Join

[Documentation](https://kusto.azurewebsites.net/docs/query/joinoperator.html)

Join joins two tables together when they have a common column name

      Perf
      | where TimeGenerated > ago(2h)
      | take 1000
      | join (Alert) on Computer

Specify column from each table to join on

      Perf
      | where TimeGenerated >= ago(2h)
      | take 1000
      | join (Alert) on $left.Computer == $right.Computer

// more complex join
Perf
| where TimeGenerated >= ago(10d)
| where CounterName == "% Processor Time"
| project Computer
                 , CounterName
                 , CounterValue
                 , PerfTime=TimeGenerated
| join ( Alert
              | where TimeGenerated >= ago(10d)
               | project Computer
                                 , AlertName
                                 , AlertDescription
                                 , ThresholdOperator
                                 , ThresholdValue
                                 , AlertTime=TimeGenerated
                 | where AlertName == "High CPU Alert"
                )
      on Computer

// change the type of join
Perf
| where TimeGenerated >= ago(10d)
| where CounterName == "% Processor Time"
| project Computer
                 , CounterName
                 , CounterValue
                 , PerfTime=TimeGenerated
| join kind=fullouter ( Alert
              | where TimeGenerated >= ago(10d)
               | project Computer
                                 , AlertName
                                 , AlertDescription
                                 , ThresholdOperator
                                 , ThresholdValue
                                 , AlertTime=TimeGenerated
                 | where AlertName == "High CPU Alert"
                )
      on Computer

// Types of joins
// innerunique
//     Only one row from the left is matched for each value on the on key.
//     Output contains a match for each row on the right with a row on the left
//
// inner
//    Output has one row for every combination of left and right
//
// leftouter
//  In addition to every match, there's a row for every row on the left
//
// rightouter / fullouter
//  Same as left outer but with all right rows being returned
//
// leftanti / rightanti
// only returns rows who do not have a match
//
// leftsemi / rightsemi
// returns rows who have a match on both sides, but only includes
// the columns from the left side (or right if rigthsemi used)
 let startTime = ago(1d);
 let endTime = now();
 let ProcData = (
         Perf
         | where TimeGenerated between (startTime .. endTime)
         | where CounterName == "% Processor Time"
         | where ObjectName == "Processor"
         | where InstanceName == "_Total"
         | summarize PctCpuTime = avg(CounterValue) by Computer, bin(TimeGenerated, 1h)
   );
  let MemData = (
          Perf
          | where TimeGenerated between (startTime .. endTime)
          | where CounterName == "Available MBytes"
          | summarize AvailableMB = avg(CounterValue) by Computer , bin(TimeGenerated, 1h)
    );
ProcData 
| join kind = inner (
        MemData
   ) on Computer, TimeGenerated
| project TimeGenerated , Computer , PctCpuTime , AvailableMB
| project TimeGenerated, Computer, PctCpuTime, AvailableMB
| sort by TimeGenerated asc , Computer
