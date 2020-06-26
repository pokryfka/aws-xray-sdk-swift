import AsyncHTTPClient
import AWSXRay
import AWSXRayRecorder
import Logging
import NIO

@available(*, deprecated)
public typealias XRayEmmiter = XRayHTTPEmitter

public class XRayHTTPEmitter: XRayEmitter {
    private let eventLoop: EventLoop
    private let httpClient: HTTPClient
    private let xray: XRay

    private lazy var logger = Logger(label: "XRayEmmiter")

    public init(eventLoop: EventLoop, endpoint: String? = nil) {
        self.eventLoop = eventLoop
        httpClient = HTTPClient(eventLoopGroupProvider: .shared(eventLoop))
        xray = XRay(endpoint: endpoint, httpClientProvider: .shared(httpClient))
    }

    deinit {
        try? httpClient.syncShutdown()
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

        logger.info("Sending documents...\n\(documents.joined(separator: ",\n"))")
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
