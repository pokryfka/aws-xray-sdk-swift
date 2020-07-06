import Logging
import NIO // getenv

private func env(_ name: String) -> String? {
    guard let value = getenv(name) else { return nil }
    return String(cString: value)
}

internal extension XRayRecorder {
    struct Config {
        let logLevel: Logger.Level = env("XRAY_RECORDER_LOG_LEVEL").flatMap(Logger.Level.init) ?? .debug
    }
}

internal extension XRayUDPEmitter {
    struct Config {
        let logLevel: Logger.Level = env("XRAY_RECORDER_LOG_LEVEL").flatMap(Logger.Level.init) ?? .info
        let daemonEndpoint: String = env("AWS_XRAY_DAEMON_ADDRESS") ?? "127.0.0.1:2000"
    }
}
