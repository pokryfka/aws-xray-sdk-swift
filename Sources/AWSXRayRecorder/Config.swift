import Logging
import NIO // getenv

// TODO: document

private func env(_ name: String) -> String? {
    guard let value = getenv(name) else { return nil }
    return String(cString: value)
}

public extension XRayRecorder {
    struct Config {
        let enabled: Bool
        let daemonEndpoint: String
        let logLevel: Logger.Level
        let serviceVersion: String

        public init(
            enabled: Bool? = nil,
            daemonEndpoint: String? = nil,
            logLevel: Logger.Level? = nil,
            serviceVersion: String? = nil
        ) {
            self.enabled = enabled ?? !(env("AWS_XRAY_SDK_DISABLED").flatMap(Bool.init) ?? false)
            self.daemonEndpoint = daemonEndpoint ?? env("AWS_XRAY_DAEMON_ADDRESS") ?? "127.0.0.1:2000"
            self.logLevel = logLevel ?? env("XRAY_RECORDER_LOG_LEVEL").flatMap(Logger.Level.init) ?? .info
            // TODO: get package version
            self.serviceVersion = serviceVersion ?? "aws-xray-sdk-swift"
        }
    }
}

internal extension XRayUDPEmitter {
    struct Config {
        let logLevel: Logger.Level
        let daemonEndpoint: String

        init(logLevel: Logger.Level? = nil, daemonEndpoint: String? = nil) {
            self.logLevel = logLevel ?? env("XRAY_RECORDER_LOG_LEVEL").flatMap(Logger.Level.init) ?? .info
            self.daemonEndpoint = daemonEndpoint ?? env("AWS_XRAY_DAEMON_ADDRESS") ?? "127.0.0.1:2000"
        }

        init(_ config: XRayRecorder.Config) {
            logLevel = config.logLevel
            daemonEndpoint = config.daemonEndpoint
        }
    }
}
