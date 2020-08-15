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
import AWSXRayUDPEmitter
import Foundation
import JSONSchema
import NIO
import XCTest

final class EncodingTests: XCTestCase {
    private typealias JSONSchema = [String: Any]
    private typealias Segment = XRayRecorder.Segment
    private typealias SegmentEncoding = XRayUDPEmitter.SegmentEncoding

    override func setUp() {
        #if DEBUG
        preconditionFailure("Use Release configuration")
        #endif
    }

    private let schema: JSONSchema? = {
        // see https://forums.swift.org/t/draft-proposal-package-resources/29941
        let cwd = URL(fileURLWithPath: #file).deletingLastPathComponent()
        let resourceURL = cwd.appendingPathComponent("xray-segmentdocument-schema-v1.0.0.json")
        guard let data = try? Data(contentsOf: resourceURL) else { return nil }
        return try? JSONSerialization.jsonObject(with: data) as? JSONSchema
    }()

    private let segment: Segment = {
        enum TestError: Error {
            case test
        }

        let recorder = XRayRecorder(emitter: XRayNoOpEmitter(), config: .init(logLevel: .error))
        let segment = recorder.beginSegment(name: "Root Segment", context: .init())
        segment.setAnnotation("value", forKey: "keyString")
        segment.setAnnotation(true, forKey: "keyBool")
        segment.setAnnotation(42, forKey: "keyInt")
        segment.setAnnotation(3.14, forKey: "keyDouble")
//        segment.setMetadata(["key": 42]) // TODO: check, part of #61
        segment.addException(message: "Root Segment Exception")
        segment.addError(TestError.test)
        segment.setHTTPRequest(method: .POST, url: "http://www.example.com/api/user")
        segment.setHTTPResponse(status: .ok)
        for i in 1 ... 10 {
            segment.subsegment(name: "Subsegment \(i)") { segment in
                segment.setAnnotation("value", forKey: "keyString")
                segment.setAnnotation(true, forKey: "keyBool")
                segment.setAnnotation(42, forKey: "keyInt")
                segment.setAnnotation(3.14, forKey: "keyDouble")
//                segment.setMetadata(["key": 42]) // TODO: check, part of #61
                segment.addException(message: "Subsegment \(i) Exception")
                segment.addError(TestError.test)
            }
        }
        segment.end()
        return segment
    }()

    private func validateEncoding(_ segment: Segment, encoding: SegmentEncoding, schema: JSONSchema) throws {
        var result: ByteBuffer?
        XCTAssertNoThrow(result = try encoding.encode(segment))
        var buffer = try XCTUnwrap(result)
        let bytes = buffer.readBytes(length: buffer.readableBytes)
        let data: Data = Data(try XCTUnwrap(bytes))
        var obj: Any?
        XCTAssertNoThrow(obj = try JSONSerialization.jsonObject(with: data))
        XCTAssertNil(validate(try XCTUnwrap(obj), schema: schema).errors)
    }

    private func measureEncoding(_ segment: Segment, encoding: SegmentEncoding, count: UInt = 1000) {
        measure {
            for _ in 0 ..< count {
                _ = try! encoding.encode(segment)
            }
        }
    }

    func testEncodingUsingFoundationJSON() throws {
        if let schema = schema {
            try validateEncoding(segment, encoding: .foundationJSON, schema: schema)
        }
        measureEncoding(segment, encoding: .foundationJSON)
    }

    func testEncodingUsingIkigaJSON() throws {
        if let schema = schema {
            try validateEncoding(segment, encoding: .ikigaJSON, schema: schema)
        }
        measureEncoding(segment, encoding: .ikigaJSON)
    }

    func testEncodingUsingPureSwiftJSON() throws {
        if let schema = schema {
            try validateEncoding(segment, encoding: .pureJSON, schema: schema)
        }
        measureEncoding(segment, encoding: .pureJSON)
    }
}
