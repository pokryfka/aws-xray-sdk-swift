import Dispatch

internal func timeIntervalSince1970() -> Double {
    Double(DispatchWallTime.now().milliseconsSinceEpoch / 1000)
}

internal extension DispatchWallTime {
    var milliseconsSinceEpoch: Int64 {
        Int64(bitPattern: rawValue) / -1_000_000
    }
}
