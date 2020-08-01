**STRUCT**

# `XRayUDPEmitter.Config`

```swift
public struct Config
```

## Methods
### `init(daemonEndpoint:logLevel:)`

```swift
public init(daemonEndpoint: String? = nil, logLevel: Logger.Level? = nil)
```

- Parameters:
  - daemonEndpoint: the IP address and port of the X-Ray daemon listener, `127.0.0.1:2000` by default;
  if not specified the value of the `AWS_XRAY_DAEMON_ADDRESS` environment variable is used.
  - logLevel: [swift-log](https://github.com/apple/swift-log) logging level, `info` by default;
  if not specified the value of the `XRAY_RECORDER_LOG_LEVEL` environment variable is used.

#### Parameters

| Name | Description |
| ---- | ----------- |
| daemonEndpoint | the IP address and port of the X-Ray daemon listener, `127.0.0.1:2000` by default; if not specified the value of the `AWS_XRAY_DAEMON_ADDRESS` environment variable is used. |
| logLevel |  logging level, `info` by default; if not specified the value of the `XRAY_RECORDER_LOG_LEVEL` environment variable is used. |