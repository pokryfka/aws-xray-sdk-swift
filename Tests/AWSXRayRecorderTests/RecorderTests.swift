import NIO
import XCTest

@testable import AWSXRayRecorder

private typealias Segment = XRayRecorder.Segment

final class AWSXRayRecorderTests: XCTestCase {
//    func testRecordingOneSegment() {
//        let recorder = XRayRecorder(emitter: XRayNoopEmitter())
//
//        let segmentName = UUID().uuidString
//        let segmentParentId = Segment.generateId()
//
//        let segment = recorder.beginSegment(name: segmentName, parentId: segmentParentId)
//        XCTAssertNotNil(recorder.allSegments.first)
//        XCTAssertEqual(recorder.allSegments.first?.name, segmentName)
//        XCTAssertEqual(recorder.allSegments.first?.parentId, segmentParentId)
//        XCTAssertEqual(recorder.allSegments.first?.inProgress, true)
//        segment.end()
//        XCTAssertNotEqual(recorder.allSegments.first?.inProgress, true)
//        XCTAssertNotNil(recorder.allSegments.first?.endTime)
//        XCTAssertLessThan(recorder.allSegments.first!.endTime!, Date().timeIntervalSince1970)
//    }

//    func testRecordingOneSegmentClosure() {
//        let recorder = XRayRecorder(emitter: XRayNoopEmitter())
//
//        let segmentName = UUID().uuidString
//        let segmentParentId = Segment.generateId()
//
//        recorder.segment(name: segmentName, parentId: segmentParentId) { _ in
//            XCTAssertNotNil(recorder.allSegments.first)
//            XCTAssertEqual(recorder.allSegments.first?.name, segmentName)
//            XCTAssertEqual(recorder.allSegments.first?.parentId, segmentParentId)
//            XCTAssertEqual(recorder.allSegments.first?.inProgress, true)
//        }
//        XCTAssertNotEqual(recorder.allSegments.first?.inProgress, true)
//        XCTAssertNotNil(recorder.allSegments.first?.endTime)
//        XCTAssertLessThan(recorder.allSegments.first!.endTime!, Date().timeIntervalSince1970)
//    }

    // TODO: more tests
}
