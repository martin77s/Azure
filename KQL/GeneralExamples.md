# General KQL Examples


## Temp table, base64_decode_tostring

```code
let tempTable = datatable(id:int, encodedString:string)
[
   1, "TWFydGlu",
   2, "bG92ZXM=",
   3, "S1FM",
];

tempTable 
| project id, encodedString, decodedString = base64_decode_tostring(encodedString)
```

- - - 