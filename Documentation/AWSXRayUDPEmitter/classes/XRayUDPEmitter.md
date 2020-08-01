**CLASS**

# `XRayUDPEmitter`

```swift
public class XRayUDPEmitter: XRayNIOEmitter
```

# References
- [Sending segment documents to the X-Ray daemon](https://docs.aws.amazon.com/xray/latest/devguide/xray-api-sendingdata.html#xray-api-daemon)
- [Using AWS Lambda environment variables](https://docs.aws.amazon.com/lambda/latest/dg/configuration-envvars.html#configuration-envvars-runtime)

## Methods
### `init(encoding:config:eventLoopGroup:)`

```swift
public init(encoding: XRayRecorder.Segment.Encoding, config: Config = Config(),
            eventLoopGroup: EventLoopGroup? = nil) throws
```

### `deinit`

```swift
deinit
```

### `send(_:)`

```swift
public func send(_ segment: XRayRecorder.Segment)
```

### `flush(_:)`

```swift
public func flush(_ callback: @escaping (Error?) -> Void)
```

### `flush(on:)`

```swift
public func flush(on eventLoop: EventLoop? = nil) -> EventLoopFuture<Void>
```
