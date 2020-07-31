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
    public func setHTTPRequest(_ request: HTTPRequestHead) {
        let userAgent = request.headers["User-Agent"].first
        let clientIP = request.headers["X-Forwarded-For"].first
        setHTTPRequest(method: request.method.rawValue, url: request.uri, userAgent: userAgent, clientIP: clientIP)
    }

    public func setHTTPResponse(_ response: HTTPResponseHead) {
        setHTTPResponse(status: response.status.code)
    }
}
