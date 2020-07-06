import NIO

enum SocketAddressExtError: Error {
    case failedToParseEndpointString(String)
}

internal extension SocketAddress {
    init(string: String) throws {
        let ipPort = string.split(separator: ":")
        guard
            ipPort.count == 2,
            let port = Int(ipPort[1])
        else {
            throw SocketAddressExtError.failedToParseEndpointString(string)
        }
        let ipAddress = String(ipPort[0])
        try self.init(ipAddress: ipAddress, port: port)
    }
}
