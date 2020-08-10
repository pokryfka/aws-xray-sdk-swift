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

/// UDP Client.
internal final class UDPClient {
    /// A `EventLoopGroupProvider` defines how the underlying `EventLoopGroup` used to create the `EventLoop` is provided.
    ///
    /// When `shared`, the `EventLoopGroup` is provided externally and its lifecycle will be managed by the caller.
    /// When `createNew`, the library will create a new `EventLoopGroup` and manage its lifecycle.
    enum EventLoopGroupProvider {
        case shared(EventLoopGroup)
        case createNew
    }

    private enum State {
        case disconnected
        case connecting(EventLoopFuture<Void>)
        case connected(Channel)
    }

    private let eventLoopGroupProvider: EventLoopGroupProvider
    private let eventLoopGroup: EventLoopGroup

    private let address: SocketAddress

    private let isShutdown = NIOAtomic<Bool>.makeAtomic(value: false)

    private var state = State.disconnected
    private let lock = Lock()

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

    func emit(_ value: ByteBuffer) -> EventLoopFuture<Void> {
        lock.lock()
        switch state {
        case .disconnected:
            let promise = eventLoopGroup.next().makePromise(of: Void.self)
            state = .connecting(promise.futureResult)
            lock.unlock()
            connect(UDPWriter(address: address)).flatMap { channel -> EventLoopFuture<Void> in
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
            .channelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .channelInitializer { channel in channel.pipeline.addHandler(handler) }
        // the bind address is local and does not really matter, the remote address is addressed by AddressedEnvelope below
        return bootstrap.bind(host: "0.0.0.0", port: 0)
    }
}

private final class UDPWriter: ChannelOutboundHandler {
    public typealias OutboundIn = ByteBuffer
    public typealias OutboundOut = AddressedEnvelope<ByteBuffer>

    private let address: SocketAddress

    init(address: SocketAddress) {
        self.address = address
    }

    public func write(context: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?) {
        let buffer: ByteBuffer = unwrapOutboundIn(data)
        context.writeAndFlush(wrapOutboundOut(AddressedEnvelope(remoteAddress: address, data: buffer)), promise: promise)
    }
}
