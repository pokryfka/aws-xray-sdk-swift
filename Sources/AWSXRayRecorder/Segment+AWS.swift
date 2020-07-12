extension XRayRecorder.Segment {
    /// The type of AWS resource running your application.
    ///
    /// When multiple values are applicable to your application, use the one that is most specific.
    /// For example, a Multicontainer Docker Elastic Beanstalk environment runs your application on an Amazon ECS container,
    /// which in turn runs on an Amazon EC2 instance.
    /// In this case you would set the origin to `AWS::ElasticBeanstalk::Environment` as the environment is the parent of the other two resources.
    enum Origin: String, Encodable {
        /// An Amazon EC2 instance.
        case ec2Instance = "AWS::EC2::Instance"
        /// An Amazon ECS container.
        case ecsContainer = "AWS::ECS::Container"
        /// An Elastic Beanstalk environment.
        case elasticBeanstalk = "AWS::ElasticBeanstalk::Environment"
    }

    /// For segments, the aws object contains information about the resource on which your application is running.
    /// Multiple fields can apply to a single resource. For example, an application running in a multicontainer Docker environment on
    /// Elastic Beanstalk could have information about the Amazon EC2 instance, the Amazon ECS container running on the instance,
    /// and the Elastic Beanstalk environment itself.
    ///
    /// # References
    /// - [AWS X-Ray segment documents - AWS resource data](https://docs.aws.amazon.com/xray/latest/devguide/xray-api-segmentdocuments.html#api-segmentdocuments-aws)
    public struct AWS: Encodable {
        /// If your application sends segments to a different AWS account, record the ID of the account running your application.
        var accountId: String?

        // MARK: Segments

        /// Information about an Amazon ECS container.
        struct ECS: Encodable {
            /// The container ID of the container running your application.
            let container: String?
        }

        /// Information about an EC2 instance.
        struct EC2: Encodable {
            /// The instance ID of the EC2 instance.
            let instanceId: String?
            /// The Availability Zone in which the instance is running.
            let availabilityZone: String?
        }

        /// Information about an Elastic Beanstalk environment.
        /// You can find this information in a file named `/var/elasticbeanstalk/xray/environment.conf`
        /// on the latest Elastic Beanstalk platforms.
        struct ElasticBeanstalk: Encodable {
            /// The name of the environment.
            var environmentName: String?
            /// The name of the application version that is currently deployed to the instance that served the request.
            var versionLabel: String?
            /// **number** indicating the ID of the last successful deployment to the instance that served the request.
            var deploymentId: Int?
        }

        /// Information about an Amazon ECS container.
        var ecs: ECS?
        /// Information about an EC2 instance.
        var ec2: EC2?
        /// Information about an Elastic Beanstalk environment.
        var elasticBeanstalk: ElasticBeanstalk?

        // MARK: Subsegments

        /// The name of the API action invoked against an AWS service or resource.
        var operation: String?
        /// If the resource is in a region different from your application, record the region. For example, `us-west-2`.
        var region: String?
        /// Unique identifier for the request.
        public var requestId: String?
        /// For operations on an Amazon SQS queue, the queue's URL.
        var queueURL: String?
        /// For operations on a DynamoDB table, the name of the table.
        var tableName: String?

        public init(operation: String? = nil, region: String? = nil, requestId: String? = nil) {
            self.operation = operation
            self.region = region
            self.requestId = requestId
        }
    }
}

extension XRayRecorder.Segment {
    public func setAWS(_ aws: AWS) {
        self.aws = aws
    }
}
