import Logging

// TODO: document

// TODO: AWS_XRAY_CONTEXT_MISSING – For X-Ray tracing, Lambda sets this to LOG_ERROR to avoid throwing runtime errors from the X-Ray SDK.

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

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

private func env(_ name: String) -> String? {
    #if canImport(Darwin)
    guard let value = getenv(name) else { return nil }
    return String(cString: value)
    #elseif canImport(Glibc)
    guard let value = getenv(name) else { return nil }
    return String(cString: value)
    #else
    return nil
    #endif
}
