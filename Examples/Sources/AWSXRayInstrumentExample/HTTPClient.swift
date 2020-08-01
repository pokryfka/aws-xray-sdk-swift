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

import AsyncHTTPClient
import Baggage
import Instrumentation
import NIO
import NIOInstrumentation
import TracingInstrumentation

private typealias TracingInstrument = TracingInstrumentation.TracingInstrument
private typealias Span = TracingInstrumentation.Span

class BetterHTTPClient {
    private let client: HTTPClient

    init(eventLoopGroup: EventLoopGroup? = nil) {
        if let eventLoopGroup = eventLoopGroup {
            client = HTTPClient(eventLoopGroupProvider: .shared(eventLoopGroup))
        } else {
            client = HTTPClient(eventLoopGroupProvider: .createNew)
        }
    }

    deinit {
        try? client.syncShutdown()
    }

    func execute(request: HTTPClient.Request, baggage: BaggageContext) -> NIO.EventLoopFuture<AsyncHTTPClient.HTTPClient.Response> {
        // TODO: ?
        let tracer = InstrumentationSystem.instrument as! TracingInstrument
        var span = tracer.startHTTPSpan(request: request, context: baggage)
        var request = request
        tracer.inject(span.baggage, into: &request.headers, using: HTTPHeadersInjector())
        return client.execute(request: request)
            .always { result in
                switch result {
                case .success(let response):
                    span.setHTTPAttributes(response: response)
                case .failure(let error):
                    // TODO: span does not expose a way to recoer an error at the moment, see https://github.com/slashmo/gsoc-swift-tracing/issues/90
                    span.addEvent(.init(name: "Error \(error)"))
                }
                span.end()
            }
    }
}

private extension TracingInstrument {
    func startHTTPSpan(request: HTTPClient.Request, context: BaggageContext) -> Span {
        // TODO: create name per https://github.com/open-telemetry/opentelemetry-specification/blob/master/specification/trace/semantic_conventions/http.md
        var span = startSpan(named: "HTTP \(request.url)", context: context)
        // TODO: preferably the attributes would be passed in ctor
        span.setHTTPAttributes(request: request)
        return span
    }
}

private extension Span {
    mutating func setHTTPAttributes(request: HTTPClient.Request) {
        // TODO: missing
//        setAttribute(request.method.rawValue, forKey: OpenTelemetry.SpanAttributes.HTTP.method)
//        setAttribute(request.url.absoluteString, forKey: OpenTelemetry.SpanAttributes.HTTP.url)
    }

    mutating func setHTTPAttributes(response: HTTPClient.Response) {
        // TODO: missing
//        setAttribute(response.status.code, forKey: OpenTelemetry.SpanAttributes.HTTP.statusCode)
//        setAttribute(response.body?.readableBytes ?? -1, forKey: OpenTelemetry.SpanAttributes.HTTP.responseContentLength)
    }
}
