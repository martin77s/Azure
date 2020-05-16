# Parse

[Document Link](https://kusto.azurewebsites.net/docs/query/parseoperator.html)

Takes parts of string and makes new columns. In the below example the RenderedDescription contains fields we want as columns.  
Parse works this way:

- First we look for "Event code: " 
- Once we find this value then the field starts until it finds the next search criteria (" Event message: "). We store the result as myEventCode
- This continues until we find " Event occurence: " which will end our parsing of the RenderedDescription 

Below we parser the Rendered Description of an Event

    Event  
    | where RenderedDescription startswith "Event code: "  
    | parse RenderedDescription with  
        "Event code: " myEventCode  
        " Event message: " myEventMessage  
        " Event time: " myEventTime  
        " Event time (UTC): " myEventTimeUTC  
        " Event ID: " myEventID  
        " Event sequence: " myEventSequence  
        " Event occurrence: " *  
    | project myEventCode , myEventMessage  , myEventTime , myEventTimeUTC , myEventID , myEventSequence