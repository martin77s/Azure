# Daily data cap percentage check

The below query is used to determine if you are approaching the daily data cap and warn users about it.

###Scenario
You have setup a daily cap (_Suggestion_ setup a daily data cap that is 50% over the maximum of the last 6 month to avoid seasonality data if budget permit) 

The following query calculate the data usage starting from when the data cap counter is reset.

```kql
let datacapstarthour=5;
let todaycap= make_datetime(datetime_part("year",now()), datetime_part("month",now()), datetime_part("day",now()),datacapstarthour,0);
let yesterdaycap= make_datetime(datetime_part("year",now()), datetime_part("month",now()), datetime_part("day",now()-1d),datacapstarthour,0);
Usage 
| where IsBillable == true
| where QuantityUnit == "MBytes"
| extend datacapstart=iff(datetime_part("hour",now()) > datacapstarthour,todaycap,yesterdaycap)
| extend todaycap,yesterdaycap,datacapstart
| where (TimeGenerated > datacapstart)
| summarize DataVolume = sum(Quantity) 
```

