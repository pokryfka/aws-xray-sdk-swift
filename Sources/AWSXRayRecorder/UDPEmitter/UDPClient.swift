//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftStatsdClient open source project
//
// Copyright (c) 2019 the SwiftStatsdClient project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftStatsdClient project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import NIO
import NIOConcurrencyHelpers

/// A `EventLoopGroupProvider` defines how the underlying `EventLoopGroup` used to create the `EventLoop` is provided.
///
/// When `shared`, the `EventLoopGroup` is provided externally and its lifecycle will be managed by the caller.
/// When `createNew`, the library will create a new `EventLoopGroup` and manage its lifecycle.
enum EventLoopGroupProvider {
    case shared(EventLoopGroup)
    case createNew
}

/// Based on the NIO UDP Client implementation in swift-statsd-client
/// with dependency on Metrics removed.
/// # References
/// - [swift-statsd-client](https://github.com/apple/swift-statsd-client)
final class UDPClient {
    private let eventLoopGroupProvider: EventLoopGroupProvider
    private let eventLoopGroup: EventLoopGroup

    private let address: SocketAddress

    private let isShutdown = NIOAtomic<Bool>.makeAtomic(value: false)

    private var state = State.disconnected
    private let lock = Lock()

    private enum State {
        case disconnected
        case connecting(EventLoopFuture<Void>)
        case connected(Channel)
    }

    var eventLoop: EventLoop { eventLoopGroup.next() }

    init(eventLoopGroupProvider: EventLoopGroupProvider, address: SocketAddress) {
        self.eventLoopGroupProvider = eventLoopGroupProvider
        switch self.eventLoopGroupProvider {
        case .shared(let group):
            eventLoopGroup = group
        case .createNew:
            eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        }
        self.address = address
    }

    deinit {
        precondition(self.isShutdown.load(), "client not stopped before the deinit.")
    }

    func shutdown(_ callback: @escaping (Error?) -> Void) {
        switch eventLoopGroupProvider {
        case .createNew:
            if isShutdown.compareAndExchange(expected: false, desired: true) {
                eventLoopGroup.shutdownGracefully(callback)
            }
        case .shared:
            isShutdown.store(true)
            callback(nil)
        }
    }

    // TODO: Encodable? currently we just use description of the value
    func emit<T: Encodable>(_ value: T) -> EventLoopFuture<Void> {
        lock.lock()
        switch state {
        case .disconnected:
            let promise = eventLoopGroup.next().makePromise(of: Void.self)
            state = .connecting(promise.futureResult)
            lock.unlock()
            connect(Encoder<T>(T.self, address: address)).flatMap { channel -> EventLoopFuture<Void> in
                self.lock.withLock {
                    guard case .connecting = self.state else {
                        preconditionFailure("invalid state \(self.state)")
                    }
                    self.state = .connected(channel)
                }
                return self.emit(value)
            }.cascade(to: promise)
            return promise.futureResult
        case .connecting(let future):
            let future = future.flatMap {
                self.emit(value)
            }
            state = .connecting(future)
            lock.unlock()
            return future
        case .connected(let channel):
            guard channel.isActive else {
                state = .disconnected
                lock.unlock()
                return emit(value)
            }
            lock.unlock()
            return channel.writeAndFlush(value)
        }
    }

    private func connect(_ handler: ChannelHandler) -> EventLoopFuture<Channel> {
        let bootstrap = DatagramBootstrap(group: eventLoopGroup)
            .channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .channelInitializer { channel in channel.pipeline.addHandler(handler) }
        // the bind address is local and does not really matter, the remote address is addressed by AddressedEnvelope below
        return bootstrap.bind(host: "0.0.0.0", port: 0)
    }
}

private final class Encoder<T>: ChannelOutboundHandler {
    public typealias OutboundIn = T
    public typealias OutboundOut = AddressedEnvelope<ByteBuffer>

    private let address: SocketAddress
    init<T>(_ type: T.Type, address: SocketAddress) {
        self.address = address
    }

    public func write(context: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?) {
        let value: T = unwrapOutboundIn(data)
        let string = "\(value)"
        var buffer = context.channel.allocator.buffer(capacity: string.utf8.count)
        buffer.writeString(string)
        context.writeAndFlush(wrapOutboundOut(AddressedEnvelope(remoteAddress: address, data: buffer)), promise: promise)
    }
}
