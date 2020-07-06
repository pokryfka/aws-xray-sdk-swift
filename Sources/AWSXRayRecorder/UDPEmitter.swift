import Dispatch // TODO: move to Lock
import Logging
import NIO

// TODO: retry if failed to emit, log serialization errors

private func env(_ name: String) -> String? {
    guard let value = getenv(name) else { return nil }
    return String(cString: value)
}

/// # References
/// - [Sending segment documents to the X-Ray daemon](https://docs.aws.amazon.com/xray/latest/devguide/xray-api-sendingdata.html#xray-api-daemon)
/// - [Using AWS Lambda environment variables](https://docs.aws.amazon.com/lambda/latest/dg/configuration-envvars.html#configuration-envvars-runtime)
internal class XRayUDPEmitter: XRayEmitter {
    static let defaultAddress = try! SocketAddress(ipAddress: "127.0.0.1", port: 2000)

    static let segmentHeader = "{\"format\": \"json\", \"version\": 1}\n"

    private let udpClient: UDPClient

    var eventLoop: EventLoop { udpClient.eventLoop }

    private lazy var logger: Logger = {
        var logger = Logger(label: "net.pokryfka.xray_recorder.udp")
        logger.logLevel = env("XRAY_RECORDER_LOG_LEVEL").flatMap(Logger.Level.init) ?? .info
        return logger
    }()

    init(address: SocketAddress = XRayUDPEmitter.defaultAddress) {
        udpClient = UDPClient(eventLoopGroupProvider: .createNew, address: address)
    }

    convenience init(endpoint: String?) {
        if let endpoint = endpoint {
            let ipPort = endpoint.split(separator: ":")
            guard
                ipPort.count == 2,
                let port = Int(ipPort[1]),
                let address = try? SocketAddress(ipAddress: String(ipPort[0]), port: port)
            else {
                preconditionFailure("Invalid AWS_XRAY_DAEMON_ADDRESS: \(endpoint)")
            }
            self.init(address: address)
        } else {
            self.init(address: XRayUDPEmitter.defaultAddress)
        }
    }

    deinit {
        let semaphore = DispatchSemaphore(value: 0)
        udpClient.shutdown { error in
            if let error = error {
                self.logger.error("Failed to shutdown: \(error)")
            }
            semaphore.signal()
        }
        semaphore.wait()
    }

    func send(segment: XRayRecorder.Segment) -> EventLoopFuture<Void> {
        do {
            // TODO: check size
            let string = "\(Self.segmentHeader)\(try segment.JSONString())"
            logger.info("Sending segment")
            logger.debug("\(string)")
            return udpClient.emit(string)
        } catch {
            // TODO: propagate the error or just log it?
            logger.error("Failed to emit segment: \(segment)")
            return udpClient.eventLoop.makeSucceededFuture(())
        }
    }

    func send(segments: [XRayRecorder.Segment]) -> EventLoopFuture<Void> {
        guard segments.isEmpty == false else {
            return udpClient.eventLoop.makeSucceededFuture(())
        }
        let futures = segments.map { self.send(segment: $0) }
        return EventLoopFuture.andAllComplete(futures, on: udpClient.eventLoop)
    }
}
