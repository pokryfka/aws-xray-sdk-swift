import Logging
import NIO

/// # References
/// - [Sending segment documents to the X-Ray daemon](https://docs.aws.amazon.com/xray/latest/devguide/xray-api-sendingdata.html#xray-api-daemon)
/// - [Using AWS Lambda environment variables](https://docs.aws.amazon.com/lambda/latest/dg/configuration-envvars.html#configuration-envvars-runtime)
internal class XRayUDPEmitter: XRayNIOEmitter {
    static let segmentHeader = "{\"format\": \"json\", \"version\": 1}\n"

    private let config: Config

    private lazy var logger = Logger(label: "net.pokryfka.xray_recorder.udp_emitter")

    private let udpClient: UDPClient

    private let lock = Lock()
    private var _inFlight = [UInt64: EventLoopFuture<Void>]()

    init(config: Config = Config(), eventLoopGroup: EventLoopGroup? = nil) throws {
        self.config = config
        let address = try SocketAddress(string: config.daemonEndpoint)
        if let eventLoopGroup = eventLoopGroup {
            udpClient = UDPClient(eventLoopGroupProvider: .shared(eventLoopGroup), address: address)
        } else {
            udpClient = UDPClient(eventLoopGroupProvider: .createNew, address: address)
        }
        logger.logLevel = config.logLevel
    }

    deinit {
        udpClient.shutdown { error in
            if let error = error {
                self.logger.error("Failed to shutdown: \(error)")
            }
        }
    }

    func send(_ segment: XRayRecorder.Segment) {
        // TODO: check size, consider sending subsegments separately
        // or group a few segments in one datagram
        do {
            let futureId = UInt64.random(in: UInt64.min ... UInt64.max)
            let string = "\(Self.segmentHeader)\(try segment.JSONString())"
            logger.info("Sending segment", metadata: ["id": "\(futureId)"])
            logger.debug("\(string)")
            let future = udpClient.emit(string)
            lock.withLockVoid {
                _inFlight[futureId] = future
            }
            future.whenComplete { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .failure(let error):
                    // TODO: handle errors
                    self.logger.error("Failed to sent: \(error)", metadata: ["id": "\(futureId)"])
                case .success:
                    self.logger.info("Sent", metadata: ["id": "\(futureId)"])
                }
                self.lock.withLockVoid {
                    self._inFlight[futureId] = nil
                }
            }
        } catch {
            // TODO: handle errors
            logger.error("Failed to emit segment: \(error)")
        }
    }

    func flush(_ callback: @escaping (Error?) -> Void) {
        do {
            try flush().always { result in
                switch result {
                case .failure(let error):
                    callback(error)
                case .success:
                    callback(nil)
                }
            }
            .wait()
        } catch {
            callback(error)
        }
    }

    func flush(on eventLoop: EventLoop? = nil) -> EventLoopFuture<Void> {
        logger.info("Flashing...")
        let futures = lock.withLock { Array(_inFlight.values) }
        logger.info("in flight \(futures.count)")
        // TODO: log errors, at the very least
        let eventLoop = eventLoop ?? udpClient.eventLoop
        return EventLoopFuture.andAllComplete(futures, on: eventLoop)
            .always { _ in self.logger.info("All sent") }
    }
}
