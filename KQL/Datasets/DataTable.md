# DataTable

[Documentation]()

Practical example of datatable
 
    let computers = datatable ( ComputerName:string, FriendlyName:string ) ["ContosoSQLSrv1", "Contoso SQL Server One", "ContosoWeb", "Contoso Web Server", "ContosoWeb0-Linux", "Contoso Linux Web Server", "ContosoWeb1.ContosoRetail.com", "Contoso Retail Websit", "ContosoWeb2-Linux", "Contoso Linux Web Server backup"];  
    let PerfInfo = Perf  
    | where Computer  in ("ContosoSQLSrv1", "ContosoWeb", "ContosoWeb0-Linux", "ContosoWeb1.ContosoRetail.com", "ContosoWeb2-Linux" )
    | where TimeGenerated >= ago(1h)
    | project Computer
            , TimeGenerated
            , CounterName
            , CounterValue ;
    computers
    | join PerfInfo on $left.ComputerName == $right.Computer
    | project FriendlyName
            , ComputerName
            , TimeGenerated
            , CounterName
            , CounterValue
