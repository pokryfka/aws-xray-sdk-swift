# XRayRecorder.TraceContext

XRay Trace Context propagated in a tracing header.

``` swift
public struct TraceContext
```

# Tracing header

All requests are traced, up to a configurable minimum.
After reaching that minimum, a percentage of requests are traced to avoid unnecessary cost.
The sampling decision and trace ID are added to HTTP requests in **tracing headers** named `X-Amzn-Trace-Id`.
The first X-Ray-integrated service that the request hits adds a tracing header, which is read by the X-Ray SDK and included in the response.

# Example Tracing header with root trace ID and sampling decision:​

``` 
X-Amzn-Trace-Id:​ Root=1-5759e988-bd862e3fe1be46a994272793;Sampled=1
```

# Tracing Header Security

A tracing header can originate from the X-Ray SDK, an AWS service, or the client request.
Your application can remove `X-Amzn-Trace-Id` from incoming requests to avoid issues caused by users adding trace IDs
or sampling decisions to their requests.

The tracing header can also contain a parent segment ID if the request originated from an instrumented application.
For example, if your application calls a downstream HTTP web API with an instrumented HTTP client,
the X-Ray SDK adds the segment ID for the original request to the tracing header of the downstream request.
An instrumented application that serves the downstream request can record the parent segment ID to connect the two requests.

# Example Tracing header with root trace ID, parent segment ID and sampling decision

``` 
X-Amzn-Trace-Id:​ Root=1-5759e988-bd862e3fe1be46a994272793;Parent=53995c3f42cd8ad8;Sampled=1
```

# References

  - [AWS X-Ray concepts - Tracing header](https:​//docs.aws.amazon.com/xray/latest/devguide/xray-concepts.html#xray-concepts-tracingheader)

## Inheritance

`Equatable`

## Initializers

### `init(traceId:​parentId:​sampled:​)`

Creates new Trace Context.

``` swift
public init(traceId:​ XRayRecorder.TraceID = .init(), parentId:​ XRayRecorder.Segment.ID? = nil, sampled:​ XRayRecorder.SampleDecision = .sampled)
```

#### Parameters

  - traceId:​ - traceId:​ root trace ID
  - parentId:​ - parentId:​ parent segment ID
  - sampled:​ - sampled:​ sampling decision

### `init(tracingHeader:​)`

Parses and validates string with Tracing Header.

``` swift
public init(tracingHeader:​ String) throws
```

## Properties

### `traceId`

root trace ID

``` swift
let traceId:​ TraceID
```

### `parentId`

parent segment ID

``` swift
var parentId:​ Segment.ID?
```

### `sampled`

sampling decision

``` swift
var sampled:​ XRayRecorder.SampleDecision
```

### `tracingHeader`

Tracing header value.

``` swift
var tracingHeader:​ String
```

## Methods

### `==(lhs:​rhs:​)`

``` swift
public static func ==(lhs:​ Self, rhs:​ Self) -> Bool
```
