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

/// Sends `XRayRecorder.Segment`s to the X-Ray daemon, which will buffer them and upload to the X-Ray API in batches.
/// The X-Ray SDK sends segment documents to the daemon to avoid making calls to AWS directly.
///
/// The IP address and port of the X-Ray daemon is configured using `AWS_XRAY_DAEMON_ADDRESS` environment variable, `127.0.0.1:2000` by default.
///
/// # References
/// - [Sending segment documents to the X-Ray daemon](https://docs.aws.amazon.com/xray/latest/devguide/xray-api-sendingdata.html#xray-api-daemon)
public class XRayUDPEmitter: XRayNIOEmitter {
    /// A type representing the ability to encode a `XRayRecorder.Segment` to a String with its JSON representation.
    public struct SegmentEncoding {
        /// How to encode a segment  to JSON string.
        public let encode: (XRayRecorder.Segment) throws -> ByteBuffer
        /// Creates new instance.
        /// - Parameter encode: How to encode a segment  to JSON string.
        public init(encode: @escaping (XRayRecorder.Segment) throws -> ByteBuffer) {
            self.encode = encode
        }
    }

    /// Specifies how `EventLoopGroup` will be created and establishes lifecycle ownership.
    public enum EventLoopGroupProvider {
        /// `EventLoopGroup` will be provided by the user. Owner of this group is responsible for its lifecycle.
        case shared(EventLoopGroup)
        /// `EventLoopGroup` will be created by the client. When `syncShutdown` is called, created `EventLoopGroup` will be shut down as well.
        case createNew
    }

    private static let segmentHeader: StaticString = "{\"format\": \"json\", \"version\": 1}\n"

    private let logger: Logger
    private let encoding: SegmentEncoding
    private let udpClient: UDPClient

    private let lock = ReadWriteLock()
    private var _inFlight = [UInt64: EventLoopFuture<Void>]()

    internal init(encoding: SegmentEncoding,
                  eventLoopGroupProvider: EventLoopGroupProvider, address: SocketAddress,
                  logger: Logger)
    {
        self.logger = logger
        self.encoding = encoding
        switch eventLoopGroupProvider {
        case .createNew:
            udpClient = UDPClient(eventLoopGroupProvider: .createNew, address: address)
        case .shared(let eventLoopGroup):
            udpClient = UDPClient(eventLoopGroupProvider: .shared(eventLoopGroup), address: address)
        }
    }

    /// Creates an instance of `XRayUDPEmitter`.
    ///
    /// - Parameters:
    ///   - encoding: Contains encoder used to encode `XRayRecorder.Segment` to JSON string.
    ///   - eventLoopGroupProvider: Specifies how `EventLoopGroup` will be created and establishes lifecycle ownership.
    ///   - config: configuration, **overrides** enviromental variables.
    /// - Throws: may throw if the UDP Daemon endpoint cannot be parsed.
    public convenience init(encoding: SegmentEncoding,
                            eventLoopGroupProvider: EventLoopGroupProvider = .createNew,
                            config: Config = Config()) throws
    {
        let address = try SocketAddress(string: config.daemonEndpoint)
        var logger = Logger(label: "xray.udp_emitter.\(String.random32())")
        logger.logLevel = config.logLevel
        self.init(encoding: encoding, eventLoopGroupProvider: eventLoopGroupProvider, address: address, logger: logger)
    }

    public func send(_ segment: XRayRecorder.Segment) {
        // TODO: check size, consider sending subsegments separately
        // or grouping a few segments in one datagram (if possible)
        // see https://github.com/pokryfka/aws-xray-sdk-swift/issues/25
        let futureId = UInt64.random(in: UInt64.min ... UInt64.max)
        do {
            var buffer = ByteBuffer(staticString: Self.segmentHeader)
            var segmentBuffer = try encoding.encode(segment)
            buffer.writeBuffer(&segmentBuffer)
            logger.info("Sending \(buffer.readableBytes) bytes", metadata: ["id": "\(futureId)"])
            let future = udpClient.emit(buffer)
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

    public func shutdown(_ callback: @escaping (Error?) -> Void) {
        udpClient.shutdown { error in
            if let error = error {
                self.logger.error("Failed to shutdown: \(error)")
            }
            callback(error)
        }
    }
}
