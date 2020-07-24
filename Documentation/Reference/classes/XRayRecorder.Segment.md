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
### `context`

```swift
public var context: TraceContext
```

### `id`

```swift
public var id: ID
```

A 64-bit identifier for the segment, unique among segments in the same trace, in **16 hexadecimal digits**.

### `name`

```swift
public var name: String
```

The logical name of the service that handled the request, up to **200 characters**.
For example, your application's name or domain name.
Names can contain Unicode letters, numbers, and whitespace, and the following symbols: _, ., :, /, %, &, #, =, +, \, -, @
