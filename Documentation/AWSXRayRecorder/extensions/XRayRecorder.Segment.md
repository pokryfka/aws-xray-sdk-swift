**EXTENSION**

# `XRayRecorder.Segment`
```swift
extension XRayRecorder.Segment
```

## Methods
### `subsegment(name:metadata:body:)`

```swift
public func subsegment<T>(name: String, metadata: XRayRecorder.Segment.Metadata? = nil,
                          body: (XRayRecorder.Segment) throws -> T) rethrows -> T
```

### `subsegment(name:metadata:body:)`

```swift
public func subsegment<T>(name: String, metadata: XRayRecorder.Segment.Metadata? = nil,
                          body: () -> EventLoopFuture<T>) -> EventLoopFuture<T>
```

### `setHTTPRequest(method:url:userAgent:clientIP:)`

```swift
public func setHTTPRequest(method: HTTPMethod, url: String, userAgent: String? = nil, clientIP: String? = nil)
```

Records details about an HTTP request that your application served (in a segment) or
that your application made to a downstream HTTP API (in a subsegment).

The IP address of the requester can be retrieved from the IP packet's `Source Address` or, for forwarded requests,
from an `X-Forwarded-For` header.

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

### `setHTTPRequest(_:)`

```swift
public func setHTTPRequest(_ request: HTTPRequestHead)
```

Records details about an HTTP request that your application served (in a segment) or
that your application made to a downstream HTTP API (in a subsegment).

The IP address of the requester is retrieved from an `X-Forwarded-For` header.

- Parameters:
  - request: HTTP request.

#### Parameters

| Name | Description |
| ---- | ----------- |
| request | HTTP request. |

### `setHTTPResponse(_:)`

```swift
public func setHTTPResponse(_ response: HTTPResponseHead)
```

Records details about an HTTP response that your application served (in a segment) or
that your application made to a downstream HTTP API (in a subsegment).

Set one or more of the error fields:
- `error` - if response status code was 4XX Client Error
- `throttle` - if response status code was 429 Too Many Requests
- `fault` - if response status code was 5XX Server Error

- Parameters:
  - response: HTTP  response.

#### Parameters

| Name | Description |
| ---- | ----------- |
| response | HTTP  response. |

### `setHTTPResponse(status:)`

```swift
public func setHTTPResponse(status: HTTPResponseStatus)
```

Records details about an HTTP response that your application served (in a segment) or
that your application made to a downstream HTTP API (in a subsegment).

Set one or more of the error fields:
- `error` - if response status code was 4XX Client Error
- `throttle` - if response status code was 429 Too Many Requests
- `fault` - if response status code was 5XX Server Error

- Parameters:
  - status: HTTP  status.

#### Parameters

| Name | Description |
| ---- | ----------- |
| status | HTTP  status. |

### `encode(to:)`

```swift
public func encode(to encoder: Encoder) throws
```

#### Parameters

| Name | Description |
| ---- | ----------- |
| encoder | The encoder to write data to. |