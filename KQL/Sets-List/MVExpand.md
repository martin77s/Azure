# MVExpand

[Documentation](https://kusto.azurewebsites.net/docs/query/mvexpandoperator.html)

Takes a dynamic value (like a set or list) and converts it back into rows

    SecurityAlert  
    | extend ExtProps=todynamic(ExtendedProperties)  
    | mvexpand ExtProps  
    | project  TimeGenerated  
             , DisplayName  
             , AlertName  
             , AlertSeverity  
             , AlertSeverity  
             , ExtProps