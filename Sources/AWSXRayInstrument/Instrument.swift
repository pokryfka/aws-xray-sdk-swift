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
import Baggage
import Instrumentation
import TracingInstrumentation

private enum AmazonHeaders {
    static let traceId = "X-Amzn-Trace-Id"
}

extension XRayRecorder: TracingInstrumentation.TracingInstrument {
    public func extract<Carrier, Extractor>(_ carrier: Carrier, into baggage: inout BaggageContext, using extractor: Extractor) where Carrier == Extractor.Carrier, Extractor: ExtractorProtocol {
        guard let tracingHeader = extractor.extract(key: AmazonHeaders.traceId, from: carrier) else { return }
        if let context = try? XRayRecorder.TraceContext(tracingHeader: tracingHeader) {
            baggage.xRayContext = context
        }
    }

    public func inject<Carrier, Injector>(_ baggage: BaggageContext, into carrier: inout Carrier, using injector: Injector) where Carrier == Injector.Carrier, Injector: InjectorProtocol {
        guard let context = baggage.xRayContext else { return }
        injector.inject(context.tracingHeader, forKey: AmazonHeaders.traceId, into: &carrier)
    }

    public func startSpan(named operationName: String,
                          context: Baggage.BaggageContextCarrier,
                          ofKind _: TracingInstrumentation.SpanKind,
                          at _: TracingInstrumentation.Timestamp) -> Span
    {
        beginSegment(name: operationName, baggage: context.baggage)
    }

    public func forceFlush() {
        // TODO: use NIO flush when using NIO
        wait()
    }
}
