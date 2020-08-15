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
import AWSXRayInstrument
import AWSXRaySDK
import Baggage // BaggageContext
import BaggageLogging // LoggingBaggageContextCarrier
import Instrumentation // InstrumentationSystem
import Logging // Logger
import NIOHTTP1 // HTTPHeaders
import NIOInstrumentation // HTTPHeadersExtractor
import TracingInstrumentation

extension BaggageContext: LoggingBaggageContextCarrier {
    public var logger: Logger {
        get { Logger(label: "", factory: { _ in Logging.SwiftLogNoOpLogHandler() }) }
        set(newValue) {}
    }
}

// create and boostrap the instrument
let instrument = XRayRecorder(config: .init(logLevel: .debug)) // XRayUDPEmitter
defer { instrument.shutdown() }
InstrumentationSystem.bootstrap(instrument)

// get the tracer
let tracer = InstrumentationSystem.tracingInstrument

// create new trace
let tracingHeader = XRayRecorder.TraceContext().tracingHeader

// extract the context from HTTP headers
let headers = HTTPHeaders([
    ("X-Amzn-Trace-Id", tracingHeader),
])
var baggage = BaggageContext()
tracer.extract(headers, into: &baggage, using: HTTPHeadersExtractor())

// create instrumented HTTP client
let http = HTTPClient(eventLoopGroupProvider: .createNew)
defer { http.shutdown { _ in } }

// create new span
var span = tracer.startSpan(named: "Span 1", context: baggage)
span.attributes["key"] = "value"
span.addLink(.init(context: baggage))
span.addEvent(.init(name: "Event"))
span.addEvent(.init(name: "Event 2"))

var span2 = tracer.startSpan(named: "Span 2", context: baggage)
span.attributes["key2"] = 2

// TODO: XRay subsegment parent needs to be sent before, consider sending parent twice - when started and when ended (?)
span.end()

tracer.forceFlush()

let url = "https://nf5g0bsxz5.execute-api.us-east-1.amazonaws.com/dev/hello"
_ = try http.get(url: url, context: span.context).wait()

span2.end()
