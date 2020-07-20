@testable import AWSXRayRecorder

class TestEmitter: XRayEmitter {
    var segments = [XRayRecorder.Segment]()

    func send(_ segment: XRayRecorder.Segment) {
        // TODO: flatten, append subsegments separately
        segments.append(segment)
    }

    func flush(_: @escaping (Error?) -> Void) {}
}
