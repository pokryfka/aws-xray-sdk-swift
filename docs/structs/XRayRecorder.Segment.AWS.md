**STRUCT**

# `XRayRecorder.Segment.AWS`

```swift
public struct AWS: Encodable
```

For segments, the aws object contains information about the resource on which your application is running.
Multiple fields can apply to a single resource. For example, an application running in a multicontainer Docker environment on
Elastic Beanstalk could have information about the Amazon EC2 instance, the Amazon ECS container running on the instance,
and the Elastic Beanstalk environment itself.

# References
- [AWS X-Ray segment documents - AWS resource data](https://docs.aws.amazon.com/xray/latest/devguide/xray-api-segmentdocuments.html#api-segmentdocuments-aws)

## Properties
### `requestId`

```swift
public var requestId: String?
```

Unique identifier for the request.

## Methods
### `init(operation:region:requestId:)`

```swift
public init(operation: String? = nil, region: String? = nil, requestId: String? = nil)
```
