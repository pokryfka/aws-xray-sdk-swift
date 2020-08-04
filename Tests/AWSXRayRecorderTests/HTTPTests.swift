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

import Logging
import XCTest

@testable import AWSXRayRecorder

private typealias TraceContext = XRayRecorder.TraceContext
private typealias Segment = XRayRecorder.Segment
private typealias Namespace = XRayRecorder.Segment.Namespace
private typealias HTTP = XRayRecorder.Segment.HTTP

final class HTTPTests: XCTestCase {
    func testRecordingAWSRequest() {
        let recorder = XRayRecorder(emitter: XRayNoOpEmitter())
        let context = TraceContext(traceId: .init(), sampled: true)
        let segment = recorder.beginSegment(name: UUID().uuidString, context: context)

        let method = "POST"
        let url = "https://s3.us-east-1.amazonaws.com/"
        let userAgent = UUID().uuidString
        let clientIP = UUID().uuidString

        segment.setHTTPRequest(method: method, url: url, userAgent: userAgent, clientIP: clientIP)
        let request = HTTP.Request(method: method, url: url, userAgent: userAgent, clientIP: clientIP)
        XCTAssertEqual(request, segment._test_http.request)
        XCTAssertEqual(Namespace.aws, segment._test_namespace)
    }

    func testRecordingRemoteRequest() {
        let recorder = XRayRecorder(emitter: XRayNoOpEmitter())
        let context = TraceContext(traceId: .init(), sampled: true)
        let segment = recorder.beginSegment(name: UUID().uuidString, context: context)

        let method = "GET"
        let url = "https://www.example.com/health"
        let userAgent = UUID().uuidString
        let clientIP = UUID().uuidString

        segment.setHTTPRequest(method: method, url: url, userAgent: userAgent, clientIP: clientIP)
        let request = HTTP.Request(method: method, url: url, userAgent: userAgent, clientIP: clientIP)
        XCTAssertEqual(request, segment._test_http.request)
        XCTAssertEqual(Namespace.remote, segment._test_namespace)
    }

    func testRecordingResponse() {
        let recorder = XRayRecorder(emitter: XRayNoOpEmitter())
        let context = TraceContext(traceId: .init(), sampled: true)
        let segment = recorder.beginSegment(name: UUID().uuidString, context: context)

        let status: UInt = 200
        let contentLength: UInt = UInt.random(in: 0 ... UInt.max)

        segment.setHTTPResponse(status: status, contentLength: contentLength)
        let response = HTTP.Response(status: status, contentLength: contentLength)
        XCTAssertEqual(response, segment._test_http.response)
    }

    func testRecordingClientError() {
        let recorder = XRayRecorder(emitter: XRayNoOpEmitter())
        let context = TraceContext(traceId: .init(), sampled: true)
        let segment = recorder.beginSegment(name: UUID().uuidString, context: context)

        let status: UInt = 404
        let contentLength: UInt = UInt.random(in: 0 ... UInt.max)

        segment.setHTTPResponse(status: status, contentLength: contentLength)
        let response = HTTP.Response(status: status, contentLength: contentLength)
        XCTAssertEqual(response, segment._test_http.response)

        var error: Bool?
        var throttle: Bool?
        var fault: Bool?
        segment._test_error(error: &error, throttle: &throttle, fault: &fault)
        XCTAssertEqual(true, error)
        XCTAssertNil(throttle)
        XCTAssertNil(fault)
    }

    func testRecordingThrottleError() {
        let recorder = XRayRecorder(emitter: XRayNoOpEmitter())
        let context = TraceContext(traceId: .init(), sampled: true)
        let segment = recorder.beginSegment(name: UUID().uuidString, context: context)

        let status: UInt = 429
        let contentLength: UInt = UInt.random(in: 0 ... UInt.max)

        segment.setHTTPResponse(status: status, contentLength: contentLength)
        let response = HTTP.Response(status: status, contentLength: contentLength)
        XCTAssertEqual(response, segment._test_http.response)

        var error: Bool?
        var throttle: Bool?
        var fault: Bool?
        segment._test_error(error: &error, throttle: &throttle, fault: &fault)
        XCTAssertEqual(true, error)
        XCTAssertEqual(true, throttle)
        XCTAssertNil(fault)
    }

    func testRecordingServerError() {
        let recorder = XRayRecorder(emitter: XRayNoOpEmitter())
        let context = TraceContext(traceId: .init(), sampled: true)
        let segment = recorder.beginSegment(name: UUID().uuidString, context: context)

        let status: UInt = 500
        let contentLength: UInt = UInt.random(in: 0 ... UInt.max)

        segment.setHTTPResponse(status: status, contentLength: contentLength)
        let response = HTTP.Response(status: status, contentLength: contentLength)
        XCTAssertEqual(response, segment._test_http.response)

        var error: Bool?
        var throttle: Bool?
        var fault: Bool?
        segment._test_error(error: &error, throttle: &throttle, fault: &fault)
        XCTAssertNil(error)
        XCTAssertNil(throttle)
        XCTAssertEqual(true, fault)
    }

    func testLoggingErrors() {
        let logHandler = TestLogHandler()
        let logger = Logger(label: "test", factory: { _ in logHandler })

        let segment = Segment(id: .init(), name: UUID().uuidString, context: .init(), baggage: .init(), logger: logger)
        XCTAssertTrue(segment.isSampled)

        let invalidHTTPMethod = "abc"
        let url = "https://www.example.com/health"
        segment.setHTTPRequest(method: invalidHTTPMethod, url: url)
        XCTAssertNil(segment._test_http.request)
        XCTAssertEqual(1, logHandler.errorMessages.count)
    }
}

import NIOHTTP1

final class HTTPNIOTests: XCTestCase {
    func testRecordingAWSRequestWithHTTPMethod() {
        let recorder = XRayRecorder(emitter: XRayNoOpEmitter())
        let context = TraceContext(traceId: .init(), sampled: true)
        let segment = recorder.beginSegment(name: UUID().uuidString, context: context)

        let method = HTTPMethod.POST
        let url = "https://s3.us-east-1.amazonaws.com/"
        let userAgent = UUID().uuidString
        let clientIP = UUID().uuidString

        segment.setHTTPRequest(method: method, url: url, userAgent: userAgent, clientIP: clientIP)
        let request = HTTP.Request(method: method.rawValue, url: url, userAgent: userAgent, clientIP: clientIP)
        XCTAssertEqual(request, segment._test_http.request)
        XCTAssertEqual(Namespace.aws, segment._test_namespace)
    }

    func testRecordingRemoteRequestWithHTTPRequestHead() {
        let recorder = XRayRecorder(emitter: XRayNoOpEmitter())
        let context = TraceContext(traceId: .init(), sampled: true)
        let segment = recorder.beginSegment(name: UUID().uuidString, context: context)

        let url = "https://www.example.com/health"
        let userAgent = UUID().uuidString
        let clientIP = UUID().uuidString
        let headers: HTTPHeaders = [
            "User-Agent": userAgent,
            "X-Forwarded-For": clientIP,
        ]
        let requestHead = HTTPRequestHead(version: .init(major: 1, minor: 1), method: .GET, uri: url, headers: headers)

        segment.setHTTPRequest(requestHead)
        let request = HTTP.Request(method: HTTPMethod.GET.rawValue, url: url, userAgent: userAgent, clientIP: clientIP)
        XCTAssertEqual(request, segment._test_http.request)
        XCTAssertEqual(Namespace.remote, segment._test_namespace)
    }

    func testRecordingResponseWithHTTPResponseHead() {
        let recorder = XRayRecorder(emitter: XRayNoOpEmitter())
        let context = TraceContext(traceId: .init(), sampled: true)
        let segment = recorder.beginSegment(name: UUID().uuidString, context: context)

        let responseHead = HTTPResponseHead(version: .init(major: 1, minor: 1), status: .ok)

        segment.setHTTPResponse(responseHead)
        let response = HTTP.Response(status: HTTPResponseStatus.ok.code)
        XCTAssertEqual(response, segment._test_http.response)
    }

    func testRecordingResponseWithHTTPResponseStatus() {
        let recorder = XRayRecorder(emitter: XRayNoOpEmitter())
        let context = TraceContext(traceId: .init(), sampled: true)
        let segment = recorder.beginSegment(name: UUID().uuidString, context: context)

        segment.setHTTPResponse(status: .ok)
        let response = HTTP.Response(status: HTTPResponseStatus.ok.code)
        XCTAssertEqual(response, segment._test_http.response)
    }
}
