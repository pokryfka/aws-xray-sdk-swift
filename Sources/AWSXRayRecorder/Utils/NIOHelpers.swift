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

import NIO

enum SocketAddressExtError: Error {
    case invalidEndpoint(String)
    case invalidPort(String)
}

internal extension SocketAddress {
    init(string: String) throws {
        let ipPort = string.split(separator: ":")
        guard ipPort.count == 2 else {
            throw SocketAddressExtError.invalidEndpoint(string)
        }
        guard let port = Int(ipPort[1]) else {
            throw SocketAddressExtError.invalidPort(String(ipPort[1]))
        }
        let ipAddress = String(ipPort[0])
        try self.init(ipAddress: ipAddress, port: port)
    }
}
