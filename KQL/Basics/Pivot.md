# Pivot

[Documentation](https://kusto.azurewebsites.net/docs/query/pivotplugin.html)

Pivot to make the Event LevelName the columns
    Event  
    | project Computer , EventLevelName  
    | evaluate pivot(EventLevelName)  
    | sort by Computer asc , EventLevelName asc