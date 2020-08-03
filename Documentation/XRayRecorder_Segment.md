# XRayRecorder.Segment

A segment records tracing information about a request that your application serves.
At a minimum, a segment records the name, ID, start time, trace ID, and end time of the request.

``` swift
public class Segment
```

# References

  - [AWS X-Ray segment documents](https:​//docs.aws.amazon.com/xray/latest/devguide/xray-api-segmentdocuments.html)

## Inheritance

`Encodable`

## Nested Type Aliases

### `Metadata`

Segments and subsegments can include a metadata object containing one or more fields with values of any type, including objects and arrays.
X-Ray does not index metadata, and values can be any size, as long as the segment document doesn't exceed the maximum size (64 kB).
You can view metadata in the full segment document returned by the BatchGetTraces API.
Field keys (debug in the following example) starting with `AWS.` are reserved for use by AWS-provided SDKs and clients.

``` swift
public typealias Metadata = [String:​ AnyEncodable]
```

## Properties

### `baggage`

Context baggage containing `XRayContext`.

``` swift
var baggage:​ BaggageContext
```

### `isSampled`

Indicates if the segment is recording information.

``` swift
var isSampled:​ Bool
```

### `name`

The logical name of the service that handled the request, up to **200 characters**.
For example, your application's name or domain name.
Names can contain Unicode letters, numbers, and whitespace, and the following symbols:​ \_, ., :​, /, %, &, \#, =, +, , -, @

``` swift
var name:​ String
```

## Methods

### `subsegment(name:​metadata:​body:​)`

Creates new subsegment.

``` swift
@inlinable public func subsegment<T>(name:​ String, metadata:​ XRayRecorder.Segment.Metadata? = nil, body:​ (XRayRecorder.Segment) throws -> T) rethrows -> T
```

#### Parameters

  - name:​ - name:​ segment name
  - metadata:​ - metadata:​ segment metadata
  - body:​ - body:​ subsegment body

### `subsegment(name:​metadata:​body:​)`

Creates new subsegment.

``` swift
@inlinable public func subsegment<T>(name:​ String, metadata:​ XRayRecorder.Segment.Metadata? = nil, body:​ () -> EventLoopFuture<T>) -> EventLoopFuture<T>
```

#### Parameters

  - name:​ - name:​ segment name
  - metadata:​ - metadata:​ segment metadata
  - body:​ - body:​ segment body

### `setHTTPRequest(method:​url:​userAgent:​clientIP:​)`

Records details about an HTTP request that your application served (in a segment) or
that your application made to a downstream HTTP API (in a subsegment).

``` swift
public func setHTTPRequest(method:​ HTTPMethod, url:​ String, userAgent:​ String? = nil, clientIP:​ String? = nil)
```

The IP address of the requester can be retrieved from the IP packet's `Source Address` or, for forwarded requests,
from an `X-Forwarded-For` header.

#### Parameters

  - method:​ - method:​ The request method. For example, `GET`.
  - url:​ - url:​ The full URL of the request, compiled from the protocol, hostname, and path of the request.
  - userAgent:​ - userAgent:​ The user agent string from the requester's client.
  - clientIP:​ - clientIP:​ The IP address of the requester.

### `setHTTPRequest(_:​)`

Records details about an HTTP request that your application served (in a segment) or
that your application made to a downstream HTTP API (in a subsegment).

``` swift
public func setHTTPRequest(_ request:​ HTTPRequestHead)
```

The IP address of the requester is retrieved from an `X-Forwarded-For` header.

#### Parameters

  - request:​ - request:​ HTTP request.

### `setHTTPResponse(_:​)`

Records details about an HTTP response that your application served (in a segment) or
that your application made to a downstream HTTP API (in a subsegment).

``` swift
public func setHTTPResponse(_ response:​ HTTPResponseHead)
```

Set one or more of the error fields:​

  - `error` - if response status code was 4XX Client Error

  - `throttle` - if response status code was 429 Too Many Requests

  - `fault` - if response status code was 5XX Server Error

#### Parameters

  - response:​ - response:​ HTTP  response.

### `setHTTPResponse(status:​)`

Records details about an HTTP response that your application served (in a segment) or
that your application made to a downstream HTTP API (in a subsegment).

``` swift
public func setHTTPResponse(status:​ HTTPResponseStatus)
```

Set one or more of the error fields:​

  - `error` - if response status code was 4XX Client Error

  - `throttle` - if response status code was 429 Too Many Requests

  - `fault` - if response status code was 5XX Server Error

#### Parameters

  - status:​ - status:​ HTTP  status.

### `end()`

Updates `endTime` of the Segment.

``` swift
public func end()
```

Has no effect if the segment has been already ended or emitted in which case an error will be logged.

### `beginSubsegment(name:​metadata:​)`

Creates new subsegment.

``` swift
public func beginSubsegment(name:​ String, metadata:​ XRayRecorder.Segment.Metadata? = nil) -> XRayRecorder.Segment
```

#### Parameters

  - name:​ - name:​ segment name
  - metadata:​ - metadata:​ segment metadata

### `addException(message:​type:​)`

Records an excaption.

``` swift
public func addException(message:​ String, type:​ String? = nil)
```

#### Parameters

  - message:​ - message:​ exception message
  - type:​ - type:​ excetion type

### `addError(_:​)`

Records and error.

``` swift
public func addError(_ error:​ Error)
```

#### Parameters

  - error:​ - error:​ error

### `setHTTPRequest(method:​url:​userAgent:​clientIP:​)`

Records details about an HTTP request that your application served (in a segment) or
that your application made to a downstream HTTP API (in a subsegment).

``` swift
public func setHTTPRequest(method:​ String, url:​ String, userAgent:​ String? = nil, clientIP:​ String? = nil)
```

The IP address of the requester can be retrieved from the IP packet's `Source Address` or, for forwarded requests,
from an `X-Forwarded-For` header.

Has no effect if the HTTP method is invalid in which case an error will be logged.

#### Parameters

  - method:​ - method:​ The request method. For example, `GET`.
  - url:​ - url:​ The full URL of the request, compiled from the protocol, hostname, and path of the request.
  - userAgent:​ - userAgent:​ The user agent string from the requester's client.
  - clientIP:​ - clientIP:​ The IP address of the requester.

### `setHTTPResponse(status:​contentLength:​)`

Records details about an HTTP response that your application served (in a segment) or
that your application made to a downstream HTTP API (in a subsegment).

``` swift
public func setHTTPResponse(status:​ UInt, contentLength:​ UInt? = nil)
```

Set one or more of the error fields:​

  - `error` - if response status code was 4XX Client Error

  - `throttle` - if response status code was 429 Too Many Requests

  - `fault` - if response status code was 5XX Server Error

#### Parameters

  - status:​ - status:​ HTTP status of the response.
  - contentLength:​ - contentLength:​ the length of the response body in bytes.

### `setAnnotation(_:​forKey:​)`

Sets an annotation.

``` swift
public func setAnnotation(_ value:​ String, forKey key:​ String)
```

Keys must be alphanumeric in order to work with filters. Underscore is allowed. Other symbols and whitespace are not allowed.

X-Ray indexes up to 50 annotations per trace.

#### Parameters

  - value:​ - value:​ annotation value
  - key:​ - key:​ annotation key

### `setAnnotation(_:​forKey:​)`

Sets an annotation.

``` swift
public func setAnnotation(_ value:​ Bool, forKey key:​ String)
```

Keys must be alphanumeric in order to work with filters. Underscore is allowed. Other symbols and whitespace are not allowed.

X-Ray indexes up to 50 annotations per trace.

#### Parameters

  - value:​ - value:​ annotation value
  - key:​ - key:​ annotation key

### `setAnnotation(_:​forKey:​)`

Sets an annotation.

``` swift
public func setAnnotation(_ value:​ Int, forKey key:​ String)
```

Keys must be alphanumeric in order to work with filters. Underscore is allowed. Other symbols and whitespace are not allowed.

X-Ray indexes up to 50 annotations per trace.

#### Parameters

  - value:​ - value:​ annotation value
  - key:​ - key:​ annotation key

### `setAnnotation(_:​forKey:​)`

Sets an annotation.

``` swift
public func setAnnotation(_ value:​ Double, forKey key:​ String)
```

Keys must be alphanumeric in order to work with filters. Underscore is allowed. Other symbols and whitespace are not allowed.

X-Ray indexes up to 50 annotations per trace.

#### Parameters

  - value:​ - value:​ annotation value
  - key:​ - key:​ annotation key

### `setMetadata(_:​)`

Sets a metadata object.

``` swift
public func setMetadata(_ newElements:​ Metadata)
```

Keys starting with `AWS.` are reserved for use by AWS-provided SDKs and clients.

#### Parameters

  - newElements:​ - newElements:​ metadata object

### `setMetadata(_:​forKey:​)`

Sets a metadata value.

``` swift
public func setMetadata(_ value:​ AnyEncodable, forKey key:​ String)
```

Overwrites previous value.

Keys starting with `AWS.` are reserved for use by AWS-provided SDKs and clients.

#### Parameters

  - value:​ - value:​ metadata value
  - key:​ - key:​ metadata key

### `appendMetadata(_:​forKey:​)`

``` swift
public func appendMetadata(_ value:​ AnyEncodable, forKey key:​ String)
```

### `encode(to:​)`

``` swift
public func encode(to encoder:​ Encoder) throws
```
