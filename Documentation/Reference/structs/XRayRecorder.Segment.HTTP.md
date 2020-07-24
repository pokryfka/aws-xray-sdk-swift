**STRUCT**

# `XRayRecorder.Segment.HTTP`

```swift
public struct HTTP: Encodable
```

Use an HTTP block to record details about an HTTP request that your application served (in a segment) or
that your application made to a downstream HTTP API (in a subsegment).
Most of the fields in this object map to information found in an HTTP request and response.

When you instrument a call to a downstream web api, record a subsegment with information about the HTTP request and response.
X-Ray uses the subsegment to generate an inferred segment for the remote API.

# References
- [AWS X-Ray segment documents - HTTP request data](https://docs.aws.amazon.com/xray/latest/devguide/xray-api-segmentdocuments.html#api-segmentdocuments-http)

## Methods
### `init(request:response:)`

```swift
public init(request: Request?, response: Response?)
```
