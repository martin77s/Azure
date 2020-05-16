# Top events collected per month

Below we will get the most common events collected for each month

    Event  
    | where TimeGenerated between ( ago(365d) .. startofmonth(now() ) )
    | summarize EventCount = count() by calMonth=startofmonth(TimeGenerated), EventID  
    | where EventCount > 5000  
    | sort by calMonth desc, EventCount  
    | extend MonthNumber = datetime_part("month", calMonth), YearNumber = datetime_part("year", calMonth)  
    | extend MonthName = case(
          MonthNumber == 1, "Jan "  
        , MonthNumber == 2, "Feb "  
        , MonthNumber == 3, "Mar "  
        , MonthNumber == 4, "Apr "  
        , MonthNumber == 5, "May "  
        , MonthNumber == 6, "Jun "  
        , MonthNumber == 7, "Jul "  
        , MonthNumber == 8, "Aug "  
        , MonthNumber == 9, "Sep "  
        , MonthNumber == 10, "Oct "  
        , MonthNumber == 11, "Nov "  
        , MonthNumber == 12, "Dec "  
        , "Unknown Month")  
    | extend YearMonth = strcat( MonthName, " - ", YearNumber)  
    | project YearMonth, EventID , EventCount