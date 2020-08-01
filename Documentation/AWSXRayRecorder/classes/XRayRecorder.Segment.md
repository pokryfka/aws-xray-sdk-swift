**CLASS**

# `XRayRecorder.Segment`

```swift
public class Segment
```

A segment records tracing information about a request that your application serves.
At a minimum, a segment records the name, ID, start time, trace ID, and end time of the request.

# References
- [AWS X-Ray segment documents](https://docs.aws.amazon.com/xray/latest/devguide/xray-api-segmentdocuments.html)

## Properties
### `baggage`

```swift
public var baggage: BaggageContext
```

### `isSampled`

```swift
public var isSampled: Bool
```

### `name`

```swift
public var name: String
```

The logical name of the service that handled the request, up to **200 characters**.
For example, your application's name or domain name.
Names can contain Unicode letters, numbers, and whitespace, and the following symbols: _, ., :, /, %, &, #, =, +, \, -, @

## Methods
### `deinit`

```swift
deinit
```

### `end()`

```swift
public func end()
```

Updates `endTime` of the Segment.

Has no effect if the segment has been already ended or emitted in which case an error will be logged.

### `beginSubsegment(name:metadata:)`

```swift
public func beginSubsegment(name: String, metadata: XRayRecorder.Segment.Metadata? = nil) -> XRayRecorder.Segment
```

### `addException(message:type:)`

```swift
public func addException(message: String, type: String? = nil)
```

### `addError(_:)`

```swift
public func addError(_ error: Error)
```

### `setHTTPRequest(method:url:userAgent:clientIP:)`

```swift
public func setHTTPRequest(method: String, url: String, userAgent: String? = nil, clientIP: String? = nil)
```

Records details about an HTTP request that your application served (in a segment) or
that your application made to a downstream HTTP API (in a subsegment).

The IP address of the requester can be retrieved from the IP packet's `Source Address` or, for forwarded requests,
from an `X-Forwarded-For` header.

Has no effect if the HTTP method is invalid in which case an error will be logged.

- Parameters:
  - method: The request method. For example, `GET`.
  - url: The full URL of the request, compiled from the protocol, hostname, and path of the request.
  - userAgent: The user agent string from the requester's client.
  - clientIP: The IP address of the requester.

#### Parameters

| Name | Description |
| ---- | ----------- |
| method | The request method. For example, `GET`. |
| url | The full URL of the request, compiled from the protocol, hostname, and path of the request. |
| userAgent | The user agent string from the requester’s client. |
| clientIP | The IP address of the requester. |

### `setHTTPResponse(status:contentLength:)`

```swift
public func setHTTPResponse(status: UInt, contentLength: UInt? = nil)
```

Records details about an HTTP response that your application served (in a segment) or
that your application made to a downstream HTTP API (in a subsegment).

Set one or more of the error fields:
- `error` - if response status code was 4XX Client Error
- `throttle` - if response status code was 429 Too Many Requests
- `fault` - if response status code was 5XX Server Error

- Parameters:
  - status: HTTP status of the response.
  - contentLength: the length of the response body in bytes.

#### Parameters

| Name | Description |
| ---- | ----------- |
| status | HTTP status of the response. |
| contentLength | the length of the response body in bytes. |

### `setAnnotation(_:forKey:)`

```swift
public func setAnnotation(_ value: String, forKey key: String)
```

### `setAnnotation(_:forKey:)`

```swift
public func setAnnotation(_ value: Bool, forKey key: String)
```

### `setAnnotation(_:forKey:)`

```swift
public func setAnnotation(_ value: Int, forKey key: String)
```

### `setAnnotation(_:forKey:)`

```swift
public func setAnnotation(_ value: Double, forKey key: String)
```

### `setMetadata(_:)`

```swift
public func setMetadata(_ newElements: Metadata)
```

### `setMetadata(_:forKey:)`

```swift
public func setMetadata(_ value: AnyEncodable, forKey key: String)
```

### `appendMetadata(_:forKey:)`

```swift
public func appendMetadata(_ value: AnyEncodable, forKey key: String)
```
