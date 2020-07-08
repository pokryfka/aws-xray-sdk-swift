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
