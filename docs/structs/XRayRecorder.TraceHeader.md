**STRUCT**

# `XRayRecorder.TraceHeader`

```swift
public struct TraceHeader
```

All requests are traced, up to a configurable minimum.
After reaching that minimum, a percentage of requests are traced to avoid unnecessary cost.
The sampling decision and trace ID are added to HTTP requests in **tracing headers** named `X-Amzn-Trace-Id`.
The first X-Ray-integrated service that the request hits adds a tracing header, which is read by the X-Ray SDK and included in the response.

# Example Tracing header with root trace ID and sampling decision:
```
X-Amzn-Trace-Id: Root=1-5759e988-bd862e3fe1be46a994272793;Sampled=1
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
X-Amzn-Trace-Id: Root=1-5759e988-bd862e3fe1be46a994272793;Parent=53995c3f42cd8ad8;Sampled=1
```

 # References
- [AWS X-Ray concepts - Tracing header](https://docs.aws.amazon.com/xray/latest/devguide/xray-concepts.html#xray-concepts-tracingheader)

## Properties
### `root`

```swift
public let root: TraceID
```

root trace ID

### `parentId`

```swift
public let parentId: String?
```

parent segment ID

### `sampled`

```swift
public let sampled: XRayRecorder.SampleDecision
```

sampling decision
