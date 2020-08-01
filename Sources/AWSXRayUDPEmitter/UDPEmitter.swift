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
import Logging
import NIO

/// # References
/// - [Sending segment documents to the X-Ray daemon](https://docs.aws.amazon.com/xray/latest/devguide/xray-api-sendingdata.html#xray-api-daemon)
/// - [Using AWS Lambda environment variables](https://docs.aws.amazon.com/lambda/latest/dg/configuration-envvars.html#configuration-envvars-runtime)
public class XRayUDPEmitter: XRayNIOEmitter {
    static let segmentHeader = "{\"format\": \"json\", \"version\": 1}\n"

    private let encoding: XRayRecorder.Segment.Encoding

    private lazy var logger = Logger(label: "xray.udp_emitter.\(String.random32())")

    private let udpClient: UDPClient

    private let lock = ReadWriteLock()
    private var _inFlight = [UInt64: EventLoopFuture<Void>]()

    public init(encoding: XRayRecorder.Segment.Encoding, config: Config = Config(),
                eventLoopGroup: EventLoopGroup? = nil) throws
    {
        self.encoding = encoding
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

    public func send(_ segment: XRayRecorder.Segment) {
        // TODO: check size, consider sending subsegments separately
        // or grouping a few segments in one datagram (if possible)
        let futureId = UInt64.random(in: UInt64.min ... UInt64.max)
        do {
            let string = "\(Self.segmentHeader)\(try encoding.encode(segment))"
            logger.info("Sending \(string.utf8.count) bytes", metadata: ["id": "\(futureId)"])
            logger.debug("\(string)", metadata: ["id": "\(futureId)"])
            let future = udpClient.emit(string)
            lock.withWriterLockVoid { _inFlight[futureId] = future }
            future.whenComplete { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .failure(let error):
                    self.logger.error("Failed to emit: \(error)", metadata: ["id": "\(futureId)"])
                case .success:
                    self.logger.info("Sent", metadata: ["id": "\(futureId)"])
                }
                self.lock.withWriterLockVoid { self._inFlight[futureId] = nil }
            }
        } catch {
            logger.error("Failed to send: \(error)", metadata: ["id": "\(futureId)"])
        }
    }

    public func flush(_ callback: @escaping (Error?) -> Void) {
        do {
            try flush().always { result in
                switch result {
                case .failure(let error):
                    self.logger.error("Failed to flush: \(error)")
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

    public func flush(on eventLoop: EventLoop? = nil) -> EventLoopFuture<Void> {
        let futures = lock.withReaderLock { Array(_inFlight.values) }
        logger.info("in flight: \(futures.count)")
        let eventLoop = eventLoop ?? udpClient.eventLoop
        return EventLoopFuture.andAllComplete(futures, on: eventLoop)
            .always { _ in self.logger.info("Done") }
    }
}
