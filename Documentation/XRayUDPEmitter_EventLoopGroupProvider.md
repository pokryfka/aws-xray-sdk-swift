# XRayUDPEmitter.EventLoopGroupProvider

Specifies how `EventLoopGroup` will be created and establishes lifecycle ownership.

``` swift
public enum EventLoopGroupProvider
```

## Enumeration Cases

### `shared`

`EventLoopGroup` will be provided by the user. Owner of this group is responsible for its lifecycle.

``` swift
case shared(:​ EventLoopGroup)
```

### `createNew`

`EventLoopGroup` will be created by the client. When `syncShutdown` is called, created `EventLoopGroup` will be shut down as well.

``` swift
case createNew
```
