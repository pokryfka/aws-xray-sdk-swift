import NIO

public protocol XRayNIOEmitter: XRayEmitter {
    func flush(on eventLoop: EventLoop?) -> EventLoopFuture<Void>
}
