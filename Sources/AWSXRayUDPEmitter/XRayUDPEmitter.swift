import AWSXRayRecorder
import Logging
import NIO

// TODO: retry if failed to emit, log serialization errors

/// # References
/// - [Sending segment documents to the X-Ray daemon](https://docs.aws.amazon.com/xray/latest/devguide/xray-api-sendingdata.html#xray-api-daemon)
public class XRayUDPEmitter: XRayEmitter {
    public static let defaultAddress = try! SocketAddress(ipAddress: "127.0.0.1", port: 2000)

    static let segmentHeader = "{\"format\": \"json\", \"version\": 1}\n"

    private let udpClient: UDPClient

    private lazy var logger = Logger(label: "XRayEmmiter")

    public init(address: SocketAddress = XRayUDPEmitter.defaultAddress) {
        udpClient = UDPClient(eventLoopGroupProvider: .createNew, address: address)
    }

    deinit {
        udpClient.shutdown { error in
            if let error = error {
                self.logger.error("Failed to shutdown: \(error)")
            }
        }
    }

    public func send(segment: XRayRecorder.Segment) -> EventLoopFuture<Void> {
        do {
            let string = "\(Self.segmentHeader)\(try segment.JSONString())"
            logger.info("Sending segment...\n\(string)")
            return udpClient.emit(string)
        } catch {
            // TODO: propagate the error or just log it?
            logger.error("Failed to emit segment: \(segment)")
            return udpClient.eventLoop.makeSucceededFuture(())
        }
    }

    public func send(segments: [XRayRecorder.Segment]) -> EventLoopFuture<Void> {
        guard segments.isEmpty == false else {
            return udpClient.eventLoop.makeSucceededFuture(())
        }
        let futures = segments.map { self.send(segment: $0) }
        return EventLoopFuture.andAllComplete(futures, on: udpClient.eventLoop)
    }
}
