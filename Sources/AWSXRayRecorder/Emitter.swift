// TODO: document

public protocol XRayEmitter {
    func send(_ segment: XRayRecorder.Segment)
    func flush(_ callback: @escaping (Error?) -> Void)
}

public struct XRayNoopEmitter: XRayEmitter {
    public func send(_: XRayRecorder.Segment) {}
    public func flush(_: @escaping (Error?) -> Void) {}

    public init() {}
}
