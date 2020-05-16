# Let

[Documentation](https://kusto.azurewebsites.net/docs/query/letstatement.html)

let is commonly used to store a constant value

    let minCounterValue = 300;  
    let counterName = "Free Megabytes";  
    Perf  
    | project Computer  
            , TimeGenerated  
            , CounterName  
            , CounterValue  
    | where CounterName == counterName and CounterValue <= minCounterValue  

Let can also be used to hold datetime value

    let timeago = ago(1h);  
    Perf  
    | where TimeGenerated >= timeago

It can also hold a dataset

    let compName = "ContosoWebSrvr1";  
    let UpdtSum = UpdateSummary  
    | where Computer = compName  
    | project Computer  
            , ComputerEnvironment  
            , ManagementGroupName  
            , OsVersion  
            , Resource  
            , ResourceGroup  
            , SourceSystem  
            , Type  
            , NETRuntimeVersion;  
    let Updt = Update  
    | where Computer == compName  
    | project Computer  
            , ComputerEnvironment  
            , ManagementGroupName  
            , OSVersion  
            , Resource  
            , ResourceGroup  
            , SourceSystem  
            , Type  
            , Title  
            , UpdateState;  
    union withsource = "SourceTable" UpdtSum, Updt

let can hold a function

    let dateDiffInDays = (date1: datetime, date2: datetime = datetime(2018-01-01)) { (date1 - date2) / 1d };
    print dateDiffInDays(now(), todatetime("2018-05-01"))
