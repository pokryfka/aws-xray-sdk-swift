import NIO

// TODO: remove NIO from the public interface?
// TODO: implement noop emitter?

public protocol XRayEmitter {
    var eventLoop: EventLoop { get }
    func send(segment: XRayRecorder.Segment) -> EventLoopFuture<Void>
    func send(segments: [XRayRecorder.Segment]) -> EventLoopFuture<Void>
}
