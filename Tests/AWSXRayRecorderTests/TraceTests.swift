import Foundation
import XCTest

@testable import AWSXRayRecorder

private typealias TraceID = XRayRecorder.TraceID
private typealias TraceContext = XRayRecorder.TraceContext
private typealias TraceError = XRayRecorder.TraceError
private typealias SampleDecision = XRayRecorder.SampleDecision
private typealias SegmentError = XRayRecorder.SegmentError

extension TraceID {
    fileprivate static let length: Int = 1 + 8 + 24 + 2
    fileprivate static let dateLength: Int = 8
    fileprivate static let dateInvalidCharacters = CharacterSet(charactersIn: "abcdef0123456789").inverted
    fileprivate static let identifierLength: Int = 24
    fileprivate static let identifierInvalidCharacters = CharacterSet(charactersIn: "abcdef0123456789").inverted

    func test() {
        XCTAssertEqual(date.count, Self.dateLength)
        XCTAssertNil(date.rangeOfCharacter(from: Self.dateInvalidCharacters))
        XCTAssertEqual(identifier.count, Self.identifierLength)
        XCTAssertNil(identifier.rangeOfCharacter(from: Self.identifierInvalidCharacters))
        XCTAssertEqual(String(describing: self).count, Self.length)
        XCTAssertNoThrow(try TraceID(string: String(describing: self)))
    }
}

final class TraceTests: XCTestCase {
    // MARK: TraceID

    func testTraceRandomId() {
        let numTests = 1000
        var values = Set<TraceID>()
        for _ in 0 ..< numTests {
            let traceId = TraceID()
            traceId.test()
            values.insert(traceId)
        }
        XCTAssertEqual(values.count, numTests)
    }

    func testTraceOldId() {
        let traceId = TraceID(secondsSinceEpoch: 1)
        traceId.test()
    }

    func testTraceOverflowId() {
        let traceId = TraceID(secondsSinceEpoch: 0xA_1234_5678)
        traceId.test()
        XCTAssertEqual(traceId.date, TraceID(secondsSinceEpoch: 0xB_1234_5678).date)
    }

    // MARK: TraceHeader

    func testTraceHeaderNoParentUnknownSampleDecision() {
        let string = "Root=1-5759e988-bd862e3fe1be46a994272793"
        do {
            let value = try TraceContext(tracingHeader: string)
            XCTAssertEqual(string, value.tracingHeader)
            XCTAssertNotNil(value)
            XCTAssertEqual(value.traceId.description, "1-5759e988-bd862e3fe1be46a994272793")
            XCTAssertNil(value.parentId)
            XCTAssertEqual(value.sampled, SampleDecision.unknown)
        } catch {
            XCTFail()
        }
    }

    func testTraceHeaderNoParentSampled() {
        let string = "Root=1-5759e988-bd862e3fe1be46a994272793;Sampled=1"
        do {
            let value = try TraceContext(tracingHeader: string)
            XCTAssertEqual(string, value.tracingHeader)
            XCTAssertNotNil(value)
            XCTAssertEqual(value.traceId.description, "1-5759e988-bd862e3fe1be46a994272793")
            XCTAssertNil(value.parentId)
            XCTAssertEqual(value.sampled, SampleDecision.sampled)
        } catch {
            XCTFail()
        }
    }

    func testTraceHeaderWithParentSampled() {
        let string = "Root=1-5759e988-bd862e3fe1be46a994272793;Parent=53995c3f42cd8ad8;Sampled=1"
        do {
            let value = try TraceContext(tracingHeader: string)
            XCTAssertEqual(string, value.tracingHeader)
            XCTAssertEqual(value.traceId.description, "1-5759e988-bd862e3fe1be46a994272793")
            XCTAssertEqual(value.parentId?.rawValue, "53995c3f42cd8ad8")
            XCTAssertEqual(value.sampled, SampleDecision.sampled)
        } catch {
            XCTFail()
        }
    }

    func testTraceHeaderWithParentNotSampled() {
        let string = "Root=1-5759e988-bd862e3fe1be46a994272793;Parent=53995c3f42cd8ad8;Sampled=0"
        do {
            let value = try TraceContext(tracingHeader: string)
            XCTAssertEqual(string, value.tracingHeader)
            XCTAssertEqual(value.traceId.description, "1-5759e988-bd862e3fe1be46a994272793")
            XCTAssertEqual(value.parentId?.rawValue, "53995c3f42cd8ad8")
            XCTAssertEqual(value.sampled, SampleDecision.notSampled)
        } catch {
            XCTFail()
        }
    }

    func testTraceHeaderWithParentUnkownUnkownSample() {
        let string = "Root=1-5759e988-bd862e3fe1be46a994272793;Parent=53995c3f42cd8ad8"
        do {
            let value = try TraceContext(tracingHeader: string)
            XCTAssertEqual(string, value.tracingHeader)
            XCTAssertEqual(value.traceId.description, "1-5759e988-bd862e3fe1be46a994272793")
            XCTAssertEqual(value.parentId?.rawValue, "53995c3f42cd8ad8")
            XCTAssertEqual(value.sampled, SampleDecision.unknown)
        } catch {
            XCTFail()
        }
    }

    func testTraceHeaderWithParentUnkownRequestedSample() {
        let string = "Root=1-5759e988-bd862e3fe1be46a994272793;Parent=53995c3f42cd8ad8;Sampled=?"
        do {
            let value = try TraceContext(tracingHeader: string)
            XCTAssertEqual(string, value.tracingHeader)
            XCTAssertEqual(value.traceId.description, "1-5759e988-bd862e3fe1be46a994272793")
            XCTAssertEqual(value.parentId?.rawValue, "53995c3f42cd8ad8")
            XCTAssertEqual(value.sampled, SampleDecision.requested)
        } catch {
            XCTFail()
        }
    }

    func testTraceHeaderInvalidFormat() {
        let string = "Root2799;Sampled=1"
        XCTAssertThrowsError(try TraceContext(tracingHeader: string)) { error in
            if case TraceError.invalidTracingHeader(let invalidValue) = error {
                XCTAssertEqual(invalidValue, "Root2799;Sampled=1")
            } else {
                XCTFail()
            }
        }
    }

    func testTraceHeaderInvalidRoot() {
        let string = "Root=-2799;Parent=-15277;Sampled=1"
        XCTAssertThrowsError(try TraceContext(tracingHeader: string)) { error in
            if case TraceError.invalidTraceID(let invalidValue) = error {
                XCTAssertEqual(invalidValue, "-2799")
            } else {
                XCTFail()
            }
        }
    }

    func testTraceHeaderInvalidParent() {
        let string = "Root=1-5759e988-bd862e3fe1be46a994272793;Parent=-15277;Sampled=1"
        XCTAssertThrowsError(try TraceContext(tracingHeader: string)) { error in
            if case TraceError.invalidParentID(let invalidValue) = error {
                XCTAssertEqual(invalidValue, "-15277")
            } else {
                XCTFail()
            }
        }
    }
}
