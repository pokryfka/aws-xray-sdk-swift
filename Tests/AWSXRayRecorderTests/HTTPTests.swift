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

import XCTest

@testable import AWSXRayRecorder

private typealias TraceContext = XRayRecorder.TraceContext
private typealias Namespace = XRayRecorder.Segment.Namespace
private typealias HTTP = XRayRecorder.Segment.HTTP

final class HTTPTests: XCTestCase {
    func testCreatingAWSRequest() {
        let recorder = XRayRecorder(emitter: XRayNoOpEmitter())
        let context = TraceContext(traceId: .init(), sampled: .sampled)
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

    func testCreatingRemoteRequest() {
        let recorder = XRayRecorder(emitter: XRayNoOpEmitter())
        let context = TraceContext(traceId: .init(), sampled: .sampled)
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

    func testCreatingResponse() {
        let recorder = XRayRecorder(emitter: XRayNoOpEmitter())
        let context = TraceContext(traceId: .init(), sampled: .sampled)
        let segment = recorder.beginSegment(name: UUID().uuidString, context: context)

        let status: UInt = 200
        let contentLength: UInt = UInt.random(in: 0 ... UInt.max)

        segment.setHTTPResponse(status: status, contentLength: contentLength)
        let response = HTTP.Response(status: status, contentLength: contentLength)
        XCTAssertEqual(response, segment._test_http.response)
    }
}

import NIOHTTP1

final class HTTPNIOTests: XCTestCase {
    func testCreatingAWSRequest() {
        let recorder = XRayRecorder(emitter: XRayNoOpEmitter())
        let context = TraceContext(traceId: .init(), sampled: .sampled)
        let segment = recorder.beginSegment(name: UUID().uuidString, context: context)

        let url = "https://s3.us-east-1.amazonaws.com/"
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
        XCTAssertEqual(Namespace.aws, segment._test_namespace)
    }

    func testCreatingRemoteRequest() {
        let recorder = XRayRecorder(emitter: XRayNoOpEmitter())
        let context = TraceContext(traceId: .init(), sampled: .sampled)
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

    func testCreatingResponse() {
        let recorder = XRayRecorder(emitter: XRayNoOpEmitter())
        let context = TraceContext(traceId: .init(), sampled: .sampled)
        let segment = recorder.beginSegment(name: UUID().uuidString, context: context)

        let responseHead = HTTPResponseHead(version: .init(major: 1, minor: 1), status: .ok)

        segment.setHTTPResponse(responseHead)
        let response = HTTP.Response(status: HTTPResponseStatus.ok.code)
        XCTAssertEqual(response, segment._test_http.response)
    }
}
