**TYPEALIAS**

# `Segment.Metadata`

```swift
public typealias Metadata = [String: AnyEncodable]
```

Segments and subsegments can include a metadata object containing one or more fields with values of any type, including objects and arrays.
X-Ray does not index metadata, and values can be any size, as long as the segment document doesn't exceed the maximum size (64 kB).
You can view metadata in the full segment document returned by the BatchGetTraces API.
Field keys (debug in the following example) starting with `AWS.` are reserved for use by AWS-provided SDKs and clients.