import Logging
import NIO // getenv

private func env(_ name: String) -> String? {
    guard let value = getenv(name) else { return nil }
    return String(cString: value)
}

extension XRayRecorder {
    struct Config {
        let logLevel: Logger.Level = env("XRAY_RECORDER_LOG_LEVEL").flatMap(Logger.Level.init) ?? .info
        let daemonAddress: String? = env("AWS_XRAY_DAEMON_ADDRESS")

        init() {}
    }
}
