**ENUM**

# `Config.ContextMissingStrategy`

```swift
public enum ContextMissingStrategy: String
```

## Cases
### `runtimeError`

```swift
case runtimeError = "RUNTIME_ERROR"
```

Indicate that a precondition was violated.

### `logError`

```swift
case logError = "LOG_ERROR"
```

Log an error and continue.
