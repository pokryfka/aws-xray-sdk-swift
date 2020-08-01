**EXTENSION**

# `XRayRecorder.TraceContext`
```swift
extension XRayRecorder.TraceContext
```

## Properties
### `tracingHeader`

```swift
public var tracingHeader: String
```

Tracing header value.

## Methods
### `init(tracingHeader:)`

```swift
public init(tracingHeader: String) throws
```

Parses and validates string with Tracing Header.

### `==(_:_:)`

```swift
public static func == (lhs: Self, rhs: Self) -> Bool
```

#### Parameters

| Name | Description |
| ---- | ----------- |
| lhs | A value to compare. |
| rhs | Another value to compare. |