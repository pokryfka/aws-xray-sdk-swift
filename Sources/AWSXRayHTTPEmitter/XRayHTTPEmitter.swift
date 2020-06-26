import AsyncHTTPClient
import AWSXRay
import AWSXRayRecorder
import Logging
import NIO

// TODO: retry, test retry policy in XRay HTTP client

func env(_ name: String) -> String? {
    guard let value = getenv(name) else { return nil }
    return String(cString: value)
}

private let logLevel: Logger.Level = Logger.Level(rawValue: env("XRAY_RECORDER_LOG_LEVEL") ?? "info") ?? .info

@available(*, deprecated)
public typealias XRayEmmiter = XRayHTTPEmitter

public class XRayHTTPEmitter: XRayEmitter {
    private let xray: XRay

    private lazy var logger: Logger = {
        var logger = Logger(label: "net.pokryfka.xray_recorder.http")
        logger.logLevel = logLevel
        return logger
    }()

    var eventLoop: EventLoop { xray.client.eventLoopGroup.next() }

    public init(endpoint: String? = nil, httpClientProvider: AWSClient.HTTPClientProvider = .createNew) {
        xray = XRay(endpoint: endpoint, httpClientProvider: httpClientProvider)
    }

    @available(*, deprecated)
    public init(eventLoop _: EventLoop, endpoint: String? = nil) {
        xray = XRay(endpoint: endpoint, httpClientProvider: .createNew)
    }

    public func send(segment: XRayRecorder.Segment) -> EventLoopFuture<Void> {
        send(segments: [segment])
    }

    public func send(segments: [XRayRecorder.Segment]) -> EventLoopFuture<Void> {
        guard segments.isEmpty == false else {
            return eventLoop.makeSucceededFuture(())
        }

        // TODO: log serialization errors
        let documents = segments.compactMap { try? $0.JSONString() }

        logger.info("Sending \(documents.count) documents")
        logger.debug("\(documents.joined(separator: ",\n"))")
        return xray.putTraceSegments(.init(traceSegmentDocuments: documents))
            .map { result in
                if let unprocessedTraceSegments = result.unprocessedTraceSegments,
                    !unprocessedTraceSegments.isEmpty {
                    // TODO: retry?
                    self.logger.warning("unprocessedTraceSegments: \(unprocessedTraceSegments)")
                }
            }
            .recover { error in
                // log the error but do not fail...
                self.logger.error("Failed to send documents: \(error)")
            }
    }
}
