# DateTime_Part

[Documentation](https://kusto.azurewebsites.net/docs/query/datetime-partfunction.html)

Extracts part of a date time

    Perf  
    | take 100  
    | project CounterName  
            , CounterValue  
            , TimeGenerated  
            , year = datetime_part("year", TimeGenerated)  
            , quarter = datetime_part("quarter", TimeGenerated)  
            , month = datetime_part("month", TimeGenerated)  
            , weekOfYear = datetime_part("weekOfYear", TimeGenerated)  
            , day = datetime_part("day", TimeGenerated)  
            , dayOfYear = datetime_part("dayOfYear", TimeGenerated)  
            , hour = datetime_part("hour", TimeGenerated)  
            , minute = datetime_part("minute", TimeGenerated)

Group number of events by part of calendar

    Event  
    | where TimeGenerated >= ago(7d)  
    | extend HourOfDay = datetime_part("hour",TimeGenerated)  
    | project HourOfDay  
    | summarize EventCount = count() by HourOfDay  
    | sort by HourOfDay asc
