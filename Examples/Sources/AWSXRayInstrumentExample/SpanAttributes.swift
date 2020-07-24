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

// TODO: move to https://github.com/slashmo/gsoc-swift-tracing/ at some point

// TODO: not complete

// TODO: map HTTP status code to Span status code as defined by OT and similar to XRayRecorder.Segment.HTTPError

enum OpenTelemetry {
    enum SpanAttributes {
        /// [Semantic conventions for HTTP spans](https://github.com/open-telemetry/opentelemetry-specification/blob/master/specification/trace/semantic_conventions/http.md)
        enum HTTP {
            /// HTTP request method. E.g. "GET". Required.
            static let method = "http.method"

            /// Full HTTP request URL in the form `scheme://host[:port]/path?query[#fragment]`.
            /// Usually the fragment is not transmitted over HTTP, but if it is known, it should be included nevertheless.
            static let url = "http.url"

            /// HTTP response status code. E.g. `200` (integer)
            static let statusCode = "http.status_code"

            /// The size of the response payload body in bytes.
            /// This is the number of bytes transferred excluding headers and is often, but not always, present as the `Content-Length` header.
            /// For requests using transport encoding, this should be the compressed size.
            static let responseContentLength = "http.response_content_length"
        }
    }
}
