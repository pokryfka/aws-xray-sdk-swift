# XRayRecorder.Segment.ID

A 64-bit identifier in **16 hexadecimal digits**.

``` swift
public struct ID:​ RawRepresentable, Hashable, Encodable, CustomStringConvertible
```

## Inheritance

`CustomStringConvertible`, `Encodable`, `Hashable`, `RawRepresentable`

## Initializers

### `init?(rawValue:​)`

``` swift
public init?(rawValue:​ String)
```

### `init()`

Creates new `ID`.

``` swift
public init()
```

## Properties

### `rawValue`

``` swift
let rawValue:​ String
```

### `description`

``` swift
var description:​ String
```
