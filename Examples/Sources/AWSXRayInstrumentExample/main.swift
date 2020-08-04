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

import AWSXRayInstrument
import AWSXRaySDK
import Baggage // BaggageContext
import Instrumentation // InstrumentationSystem
import NIOHTTP1 // HTTPHeaders
import NIOInstrumentation // HTTPHeadersExtractor
import TracingInstrumentation

// create and boostrap the instrument
let instrument = XRayRecorder(config: .init(logLevel: .debug)) // XRayUDPEmitter
defer {
    // TODO: use instrument API when available, see https://github.com/slashmo/gsoc-swift-tracing/issues/85
    instrument.shutdown()
}

InstrumentationSystem.bootstrap(instrument)

// TODO: ?
let tracer = InstrumentationSystem.instrument as! TracingInstrumentation.TracingInstrument // the instrument

// create new trace
let tracingHeader = XRayRecorder.TraceContext().tracingHeader

// extract the context from HTTP headers
let headers = HTTPHeaders([
    ("X-Amzn-Trace-Id", tracingHeader),
])
var baggage = BaggageContext()
tracer.extract(headers, into: &baggage, using: HTTPHeadersExtractor())

// create instrumented HTTP client
let http = BetterHTTPClient()

// create new span
var span = tracer.startSpan(named: "Span 1", context: baggage)
// span.setAttribute("Attribute 1", forKey: "key1")
span.addLink(.init(context: baggage))
span.addEvent(.init(name: "Event"))
span.addEvent(.init(name: "Event 2"))

var span2 = tracer.startSpan(named: "Span 2", context: baggage)
// span2.setAttribute("Attribute 2", forKey: "key2")

// TODO: XRay subsegment parent needs to be sent before, consider sending parent twice - when started and when ended (?)
span.end()

let url = "https://d41u83stcl.execute-api.us-east-1.amazonaws.com/Prod/hello/"
_ = try http.execute(request: try! .init(url: url), baggage: span.baggage).wait()

span2.end()
