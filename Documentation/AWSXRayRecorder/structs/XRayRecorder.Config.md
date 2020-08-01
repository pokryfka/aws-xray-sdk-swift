**STRUCT**

# `XRayRecorder.Config`

```swift
struct Config
```

## Methods
### `init(enabled:contextMissingStrategy:logLevel:serviceVersion:)`

```swift
public init(
    enabled: Bool? = nil,
    contextMissingStrategy: ContextMissingStrategy? = nil,
    logLevel: Logger.Level? = nil,
    serviceVersion: String? = nil
)
```

- Parameters:
  - enabled: set `false` to disable tracing, enabled by default unless `AWS_XRAY_SDK_ENABLED` environment variable is set to false.
  - daemonEndpoint: the IP address and port of the X-Ray daemon listener, `127.0.0.1:2000` by default;
  if not specified the value of the `AWS_XRAY_DAEMON_ADDRESS` environment variable is used.
  - contextMissingStrategy: configures how missing context is handled, `.logError` by default;
  if not specified the value of the `AWS_XRAY_CONTEXT_MISSING` environment variable is used:
    - `RUNTIME_ERROR` - Indicate that a precondition was violated.
    - `LOG_ERROR` - Log an error and continue.
  - logLevel: [swift-log](https://github.com/apple/swift-log) logging level, `info` by default;
  if not specified the value of the `XRAY_RECORDER_LOG_LEVEL` environment variable is used.
  - serviceVersion: A string that identifies the version of your application that served the request, `aws-xray-sdk-swift` by default.

#### Parameters

| Name | Description |
| ---- | ----------- |
| enabled | set `false` to disable tracing, enabled by default unless `AWS_XRAY_SDK_ENABLED` environment variable is set to false. |
| daemonEndpoint | the IP address and port of the X-Ray daemon listener, `127.0.0.1:2000` by default; if not specified the value of the `AWS_XRAY_DAEMON_ADDRESS` environment variable is used. |
| contextMissingStrategy | configures how missing context is handled, `.logError` by default; if not specified the value of the `AWS_XRAY_CONTEXT_MISSING` environment variable is used: |
| logLevel |  logging level, `info` by default; if not specified the value of the `XRAY_RECORDER_LOG_LEVEL` environment variable is used. |
| serviceVersion | A string that identifies the version of your application that served the request, `aws-xray-sdk-swift` by default. |