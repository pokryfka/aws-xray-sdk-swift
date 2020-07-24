**STRUCT**

# `Segment.ID`

```swift
public struct ID: RawRepresentable, Hashable, Encodable, CustomStringConvertible
```

A 64-bit identifier in **16 hexadecimal digits**.

## Properties
### `rawValue`

```swift
public let rawValue: String
```

### `description`

```swift
public var description: String
```

## Methods
### `init(rawValue:)`

```swift
public init?(rawValue: String)
```

#### Parameters

| Name | Description |
| ---- | ----------- |
| rawValue | The raw value to use for the new instance. |

### `init()`

```swift
public init()
```
