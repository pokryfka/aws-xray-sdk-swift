import NIOConcurrencyHelpers

typealias Lock = NIOConcurrencyHelpers.Lock

// TODO: use RWLock as in Logging

@propertyWrapper
struct Synchronized<Value> {
    private var _value: Value
    private let lock: Lock

    init(wrappedValue: Value, lock: Lock = Lock()) {
        _value = wrappedValue
        self.lock = lock
    }

    var wrappedValue: Value {
        get { lock.withLock { _value } }
        set { lock.withLockVoid { _value = newValue } }
    }

    var projectedValue: Value {
        _value
    }
}
