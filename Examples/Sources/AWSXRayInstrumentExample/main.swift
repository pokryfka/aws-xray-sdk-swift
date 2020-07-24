import AWSXRayInstrument
import AWSXRayRecorder
import Baggage // BaggageContext
import Instrumentation // InstrumentationSystem
import NIOHTTP1 // HTTPHeaders
import NIOInstrumentation // HTTPHeadersExtractor

// create and boostrap the instrument
let instrument = XRayRecorder(emitter: XRayLogEmitter(), config: .init(logLevel: .debug))
InstrumentationSystem.bootstrap(instrument)

let tracer = InstrumentationSystem.tracer // the instrument

// extract the context from HTTP headers
let headers = HTTPHeaders([
    ("X-Amzn-Trace-Id", "Root=1-5759e988-bd862e3fe1be46a994272793;Sampled=1"),
])
var baggage = BaggageContext()
tracer.extract(headers, into: &baggage, using: HTTPHeadersExtractor())

// create instrumented HTTP client
let http = BetterHTTPClient()

// create new span
var span = tracer.startSpan(named: "Span 1", context: baggage)
span.setAttribute("Attribute 1", forKey: "key1")
span.addEvent(.init(name: "Event"))

var span2 = tracer.startSpan(named: "Span 2", context: baggage)
span2.setAttribute("Attribute 2", forKey: "key2")

// TODO: XRay subsegment parent needs to be sent before, consider sending parent twice - when started and when ended (?)
span.end()

_ = try http.execute(request: try! .init(url: "https://swift.org"), baggage: span.baggage).wait()
_ = try http.execute(request: try! .init(url: "https://aws.amazon.com"), baggage: span.baggage).wait()

span2.end()

// (tracer as? XRayRecorder)?.wait()
instrument.wait()
