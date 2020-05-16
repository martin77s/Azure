# Union

[Documentation](https://kusto.azurewebsites.net/docs/query/unionoperator.html)

Join vs Union
> Join Table A &  Table B  
> &nbsp;&nbsp; Row: Table A.Col1, Table A.Col2, Table A.Col3, Table B.Col1, Table B.Col2, TableB.Col3  
> Union A & B  
> &nbsp;&nbsp; Row: Table A.Col1, Table A.Col2, Table A.Col3  
> &nbsp;&nbsp; Row: Table B.Col1, Table B.Col2, Table B.Col3  

Below we'll do a union between UpdateSummary and Update

    UpdateSummary  
    | union withsource="SourceTable" Update   

Below we use an outer union betwwn the same two tables
    union kind=outer withsource="SourceTable" UpdateSummary, Update

This is a more realistic union with us selecting to columns to display

    union withsource="SourceTable" ( UpdateSummary  
    | project Computer  
            , ComputerEnvironment  
            , ManagementGroupName  
            , OsVersion  
            , Resource  
            , ResourceGroup  
            , SourceSystem  
            , Type  
            , NETRuntimeVersion)  
    , ( Update | project Computer  
                       , ComputerEnvironment  
                       , ManagementGroupName  
                       , OSVersion  
                       , Resource  
                       , ResourceGroup  
                       , SourceSystem  
                       , Type  
                       , Title  
                       , UpdateState)
    , ( Perf | project Computer  
                     , CounterName  
                     , CounterValue)
