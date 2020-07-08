@testable import AWSXRayRecorder

class TestEmitter: XRayEmitter {
    @Synchronized var segments = [XRayRecorder.Segment]()

    func send(_ segment: XRayRecorder.Segment) {
        segments.append(segment)
    }

    func flush(_: @escaping (Error?) -> Void) {
        // do nothing
    }
}
