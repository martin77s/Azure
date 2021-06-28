# Common policy expressions

Cheat-sheet with common policy expressions often used in Azure API Management policies

## Interact with HTTP headers

#### Get HTTP header

```c#
context.Request.Headers.GetValueOrDefault("header-name","optional-default-value")
```

#### Check HTTP header existence

```c#
context.Request.Headers.ContainsKey("header-name") == true
```

#### Check if HTTP header has expected value

```c#
context.Request.Headers.GetValueOrDefault("header-name", "").Equals("expected-header-value", StringComparison.OrdinalIgnoreCase)
```

## Interact with URI parameters


#### Get URI parameter

```c#
context.Request.MatchedParameters.GetValueOrDefault("parameter-name","optional-default-value")
```

#### Check URI parameter existence

```c#
context.Request.MatchedParameters.ContainsKey("parameter-name") == true
```

#### Check if URI parameter has expected value

```c#
context.Request.MatchedParameters.GetValueOrDefault("parameter-name", "").Equals("expected-value", StringComparison.OrdinalIgnoreCase) == true
```

## Interact with query string parameters


#### Get query string parameter

```c#
context.Request.Url.Query.GetValueOrDefault("parameter-name", "optional-default-value")
```

#### Check query string parameter existence

```c#
context.Request.Url.Query.ContainsKey("parameter-name") == true
```

#### Check if query string parameter has expected value

```c#
context.Request.Url.Query.GetValueOrDefault("parameter-name", "").Equals("expected-value", StringComparison.OrdinalIgnoreCase) == true
```

## Interact with policy variables


#### Get policy variable *(assuming type string)*

```c#
context.Variables.GetValueOrDefault<string>("variable-name","optional-default-value")
```

#### Check policy variable existence

```c#
context.Variables.ContainsKey("variable-name") == true
```

#### Check if policy variable has expected value *(assuming type string)*

```c#
context.Variables.GetValueOrDefault<string>("variable-name","").Equals("expected-value", StringComparison.OrdinalIgnoreCase)
```

## Interact with JSON bodies


#### Get value from JSON body

```c#
(string)context.Request.Body.As<JObject>(preserveContent: true).SelectToken("root.child jsonpath")
```

#### Get value from JSON response variable

```c#
(string)((IResponse)context.Variables["response-variable-name"]).Body.As<JObject>().SelectToken("root.child jsonpath")
```

#### Add property to JSON body

```c#
JObject body = context.Request.Body.As<JObject>();
body.Add(new JProperty("property-name", "property-value"));
return body.ToString();
```

## Interact with JSON Web Tokens


#### Read claim from bearer token

```c#
context.Request.Headers.GetValueOrDefault("Authorization")?.Split(' ')?[1].AsJwt()?.Claims["claim-name"].FirstOrDefault()
```

## Interact with client certificates


#### Check client certificate existence

```c#
context.Request.Certificate != null
```

#### Check if client certificate is valid, including a certificate revocation check

```c#
context.Request.Certificate.Verify() == true
```

#### Check if client certificate is valid, excluding a certificate revocation check

```c#
context.Request.Certificate.VerifyNoRevocation() == true
```

#### Check if client certificate issuer has expected value

```c#
context.Request.Certificate.Issuer == "trusted-issuer"
```

#### Check if client certificate subject has expected value

```c#
context.Request.Certificate.SubjectName.Name == "expected-subject-name"
```

#### Check if client certificate thumbprint has expected value

```c#
context.Request.Certificate.Thumbprint == "EXPECTED-THUMBPRINT-IN-UPPER-CASE"
```

#### Check if client certificate is uploaded in API Management, based on thumbprint

```c#
context.Deployment.Certificates.Any(c => c.Value.Thumbprint == context.Request.Certificate.Thumbprint) == true
```

### Rate limit (limit 30 calls in 120 seconds) by the X-Forwarded-For

```c#
<inbound>
    <base />
    <set-header name="x-forwarded-for" exists-action="override">
        <value>@{
            string headerValue = context.Request.Headers.GetValueOrDefault("x-forwarded-for","0");
            string[] tokens = headerValue.Split(':');
            if(tokens.Length == 2) { headerValue = tokens[0]; } return headerValue;
            }</value>
    </set-header>
    <rate-limit-by-key calls="30" renewal-period="120" counter-key="@(context.Request.Headers.GetValueOrDefault("x-forwarded-for","0"))" />
</inbound>
```