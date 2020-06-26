import NIO

public protocol XRayEmitter {
    func send(segment: XRayRecorder.Segment) -> EventLoopFuture<Void>
    func send(segments: [XRayRecorder.Segment]) -> EventLoopFuture<Void>
}
