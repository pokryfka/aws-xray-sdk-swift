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

import NIOHTTP1

extension XRayRecorder.Segment {
    /// Records details about an HTTP request that your application served (in a segment) or
    /// that your application made to a downstream HTTP API (in a subsegment).
    ///
    /// The IP address of the requester can be retrieved from the IP packet's `Source Address` or, for forwarded requests,
    /// from an `X-Forwarded-For` header.
    ///
    /// - Parameters:
    ///   - method: The request method. For example, `GET`.
    ///   - url: The full URL of the request, compiled from the protocol, hostname, and path of the request.
    ///   - userAgent: The user agent string from the requester's client.
    ///   - clientIP: The IP address of the requester.
    public func setHTTPRequest(method: HTTPMethod, url: String, userAgent: String? = nil, clientIP: String? = nil) {
        setHTTPRequest(method: method.rawValue, url: url, userAgent: userAgent, clientIP: clientIP)
    }

    /// Records details about an HTTP request that your application served (in a segment) or
    /// that your application made to a downstream HTTP API (in a subsegment).
    ///
    /// The IP address of the requester is retrieved from an `X-Forwarded-For` header.
    ///
    /// - Parameters:
    ///   - request: HTTP request.
    public func setHTTPRequest(_ request: HTTPRequestHead) {
        let userAgent = request.headers["User-Agent"].first
        let clientIP = request.headers["X-Forwarded-For"].first
        setHTTPRequest(method: request.method.rawValue, url: request.uri, userAgent: userAgent, clientIP: clientIP)
    }

    /// Records details about an HTTP response that your application served (in a segment) or
    /// that your application made to a downstream HTTP API (in a subsegment).
    ///
    /// Set one or more of the error fields:
    /// - `error` - if response status code was 4XX Client Error
    /// - `throttle` - if response status code was 429 Too Many Requests
    /// - `fault` - if response status code was 5XX Server Error
    ///
    /// - Parameters:
    ///   - response: HTTP  response.
    public func setHTTPResponse(_ response: HTTPResponseHead) {
        setHTTPResponse(status: response.status.code)
    }
}
