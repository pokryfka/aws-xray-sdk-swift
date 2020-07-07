@propertyWrapper
struct Synchronized<Value> {
    private var _value: Value
    private let lock: ReadWriteLock

    init(wrappedValue: Value, lock: ReadWriteLock = ReadWriteLock()) {
        _value = wrappedValue
        self.lock = lock
    }

    var wrappedValue: Value {
        get { lock.withReaderLock { _value } }
        set { lock.withWriterLockVoid { _value = newValue } }
    }

    var projectedValue: Value {
        _value
    }
}
