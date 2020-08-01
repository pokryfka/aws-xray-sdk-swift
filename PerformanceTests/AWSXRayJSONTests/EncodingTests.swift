//===----------------------------------------------------------------------===//
//
// This source file is part of the aws-xray-sdk-swift open source project
//
// Copyright (c) 2020 pokryfka and the aws-xray-sdk-swift project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import AWSXRayRecorder
import Foundation
import IkigaJSON
import PureSwiftJSON
import XCTest

private typealias Segment = XRayRecorder.Segment

private protocol SegmentEncoder {
    func encode(_ value: Segment) throws -> Data
}

extension PureSwiftJSON.PSJSONEncoder {
    public func encode<T>(_ value: T) throws -> Data where T: Encodable {
        let bytes: [UInt8] = try encode(value)
        return Data(bytes)
    }
}

extension Foundation.JSONEncoder: SegmentEncoder {}
extension IkigaJSON.IkigaJSONEncoder: SegmentEncoder {} // has dependency on Foundation.Data
extension PureSwiftJSON.PSJSONEncoder: SegmentEncoder {}

final class EncodingTests: XCTestCase {
    override func setUp() {
        #if DEBUG
        preconditionFailure("Use Release configuration")
        #endif
    }

    private let segment: Segment = {
        let recorder = XRayRecorder(emitter: XRayNoOpEmitter(), config: .init(logLevel: .error))
        let segment = recorder.beginSegment(name: "Root Segment", context: .init())
        // TODO: add metadata?
        for i in 1 ... 10 {
            segment.subsegment(name: "Subsegment \(i)") { _ in }
        }
        segment.end()
        return segment
    }()

    private func measureEncoding(_ segment: Segment, encoder: SegmentEncoder, count: UInt = 1000) {
        measure {
            for _ in 0 ..< count {
                _ = try! encoder.encode(segment)
            }
        }
    }

    func testEncodingUsingFoundationJSON() {
        measureEncoding(segment, encoder: Foundation.JSONEncoder())
    }

    func testEncodingUsingIkigaJSON() {
        measureEncoding(segment, encoder: IkigaJSON.IkigaJSONEncoder())
    }

    func testEncodingUsingPureSwiftJSON() {
        measureEncoding(segment, encoder: PureSwiftJSON.PSJSONEncoder())
    }
}
