# ToDynamic

[Document Link](https://kusto.azurewebsites.net/docs/query/todynamicfunction.html)

Takes json stored in a string and lets you address its individual values

- Below SecurityAlert has a field named ExtProps that is in JSON
- We use todynamic to tell Kusto to parse it as JSON
- We can then call into the JSON using the field names

    SecurityAlert  
    | extend ExtProps=todynamic(ExtendedProperties)  
    | project AlertName  
            , TimeGenerated  
            , ExtProps["Alert Start Time (UTC)"]  
            , ExtProps["Source"]  
            , ExtProps["Non-Existent Users"]  
            , ExtProps["Failed Attempts"]  
            , ExtProps["Successful Logins"]  
            , ExtProps["Successful User Logons"]  
            , ExtProps["Account Logon Ids"]  
            , ExtProps["Failed User Logons"]  
            , ExtProps["End Time UTC"]  
            , ExtProps["ActionTaken"]  
            , ExtProps["resourceType"]  
            , ExtProps["ServiceId"]  
            , ExtProps["ReportingSystem"]  
            , ExtProps["OccuringDatacenter"]
