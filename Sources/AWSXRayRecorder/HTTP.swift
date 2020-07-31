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

extension XRayRecorder.Segment {
    internal enum Namespace: String, Encodable {
        /// AWS SDK calls
        case aws
        /// other downstream calls
        case remote
    }

    /// Use an HTTP block to record details about an HTTP request that your application served (in a segment) or
    /// that your application made to a downstream HTTP API (in a subsegment).
    /// Most of the fields in this object map to information found in an HTTP request and response.
    ///
    /// When you instrument a call to a downstream web api, record a subsegment with information about the HTTP request and response.
    /// X-Ray uses the subsegment to generate an inferred segment for the remote API.
    ///
    /// # References
    /// - [AWS X-Ray segment documents - HTTP request data](https://docs.aws.amazon.com/xray/latest/devguide/xray-api-segmentdocuments.html#api-segmentdocuments-http)
    internal struct HTTP: Encodable {
        /// Information about a request.
        struct Request: Encodable {
            /// The request method. For example, `GET`.
            var method: String?
            /// The full URL of the request, compiled from the protocol, hostname, and path of the request.
            var url: String?
            /// The user agent string from the requester's client.
            var userAgent: String?
            /// The IP address of the requester.
            /// Can be retrieved from the IP packet's `Source Address` or, for forwarded requests, from an `X-Forwarded-For` header.
            var clientIP: String?
            /// (segments only) **boolean** indicating that the `client_ip` was read from an `X-Forwarded-For` header and
            /// is not reliable as it could have been forged.
            var xForwardedFor: Bool?
            /// (subsegments only) **boolean** indicating that the downstream call is to another traced service.
            /// If this field is set to `true`, X-Ray considers the trace to be broken until the downstream service uploads a segment with a `parent_id` that
            /// matches the `id` of the subsegment that contains this block.
            var traced: Bool?

            enum CodingKeys: String, CodingKey {
                case method
                case url
                case userAgent = "user_agent"
                case clientIP = "client_ip"
                case xForwardedFor = "x_forwarded_for"
                case traced
            }
        }

        /// Information about a response.
        internal struct Response: Encodable {
            /// number indicating the HTTP status of the response.
            var status: UInt?
            /// number indicating the length of the response body in bytes.
            var contentLength: UInt?

            enum CodingKeys: String, CodingKey {
                case status
                case contentLength = "content_length"
            }
        }

        var request: Request?
        var response: Response?
    }
}

extension XRayRecorder.Segment.HTTP.Request: Equatable {}
extension XRayRecorder.Segment.HTTP.Response: Equatable {}
extension XRayRecorder.Segment.HTTP: Equatable {}
