# Example - Last Value

In the below query we will look for the disk space for each computer. We only want to show the last sample for each unique Computer - Disk so we can see an almost real-time value for disk free space. Once we have the last value we will use the case statement to categorize the value as Critical, Warning, or OK!

	Perf  
	| where ObjectName == "LogicalDisk"  
	| where CounterName == "% Free Space"
	| where (InstanceName != "_Total" and InstanceName !startswith "HarddiskVolume" )
	| summarize arg_max(TimeGenerated, *) by Computer, InstanceName  
	| project Computer , InstanceName, TimeGenerated , CounterValue  
	| extend FreeLevel = case( CounterValue < 20, "Critical",CounterValue < 50, "Warning", "OK!")  
	| where FreeLevel != "OK!"  
	| order by Computer, InstanceName asc