# XRayRecorder.TraceID

``` swift
public struct TraceID:​ CustomStringConvertible
```

# Trace ID Format

A `trace_id` consists of three numbers separated by hyphens.
For example, `1-58406520-a006649127e371903a2de979`. This includes:​

  - The version number, that is, 1.

  - The time of the original request, in Unix epoch time, in **8 hexadecimal digits**.
    For example, 10:​00AM December 1st, 2016 PST in epoch time is `1480615200` seconds, or `58406520` in hexadecimal digits.

  - A 96-bit identifier for the trace, globally unique, in **24 hexadecimal digits**.

# References

  - [Sending trace data to AWS X-Ray - Generating trace IDs](https:​//docs.aws.amazon.com/xray/latest/devguide/xray-api-sendingdata.html#xray-api-traceids)

## Inheritance

`CustomStringConvertible`, `Encodable`, `Hashable`

## Initializers

### `init()`

Creates new Trace ID.

``` swift
public init()
```

## Properties

### `description`

``` swift
var description:​ String
```

## Methods

### `hash(into:​)`

``` swift
public func hash(into hasher:​ inout Hasher)
```

### `encode(to:​)`

``` swift
public func encode(to encoder:​ Encoder) throws
```
