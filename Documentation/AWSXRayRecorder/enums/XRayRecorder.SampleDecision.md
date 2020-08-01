**ENUM**

# `XRayRecorder.SampleDecision`

```swift
public enum SampleDecision: String, Encodable
```

# References
- [AWS X-Ray concepts - Sampling](https://docs.aws.amazon.com/xray/latest/devguide/xray-concepts.html#xray-concepts-sampling)

## Cases
### `sampled`

```swift
case sampled = "Sampled=1"
```

### `notSampled`

```swift
case notSampled = "Sampled=0"
```

### `unknown`

```swift
case unknown = ""
```

### `requested`

```swift
case requested = "Sampled=?"
```
