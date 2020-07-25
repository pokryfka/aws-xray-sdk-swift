//===----------------------------------------------------------------------===//
//
// This source file is part of the aws-xray-sdk-swift open source project
//
// Copyright (c) 2020 pokryfka and the aws-xray-sdk-swift project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

/// Lambda runtimes set several environment variables during initialization.
/// # References
/// - [Using AWS Lambda environment variables - Runtime environment variables](https://docs.aws.amazon.com/lambda/latest/dg/configuration-envvars.html#configuration-envvars-runtime)
internal enum AWSLambdaEnv: String {
    // MARK: Reserved environment variables

    /// The handler location configured on the function.
    case handler = "_HANDLER"
    /// The AWS Region where the Lambda function is executed.
    case region = "AWS_REGION"
    /// The runtime identifier, prefixed by `AWS_Lambda_` - for example, AWS_Lambda_java8.
    case executionEnv = "AWS_EXECUTION_ENV"
    /// The name of the function.
    case functionName = "AWS_LAMBDA_FUNCTION_NAME"
    /// The amount of memory available to the function in MB.
    case memorySizeInMB = "AWS_LAMBDA_FUNCTION_MEMORY_SIZE"
    /// The version of the function being executed.
    case funtionVersion = "AWS_LAMBDA_FUNCTION_VERSION"
    /// The name of the Amazon CloudWatch Logs group for the function.
    case logGroupName = "AWS_LAMBDA_LOG_GROUP_NAME"
    /// The name of the Amazon CloudWatch Logs stream for the function.
    case logStreamName = "AWS_LAMBDA_LOG_STREAM_NAME"
    /// The access keys obtained from the function's execution role.
    case accessKeyId = "AWS_ACCESS_KEY_ID"
    case secretAccessKey = "AWS_SECRET_ACCESS_KEY"
    case sessionToken = "AWS_SESSION_TOKEN"
    /// (Custom runtime) The host and port of the runtime API.
    case runtimeAPI = "AWS_LAMBDA_RUNTIME_API"
    /// The path to your Lambda function code.
    case taskRoot = "LAMBDA_TASK_ROOT"
    /// The path to runtime libraries.
    case runtimeDir = "LAMBDA_RUNTIME_DIR"
    /// The environment's time zone (`UTC`). The execution environment uses NTP to synchronize the system clock.
    case timeZone = "TZ"

    // MARK: Unreserved environment variables

    /// The locale of the runtime (example: `en_US.UTF-8`).
    case lang = "LANG"
    /// The execution path (examle: `/usr/local/bin:/usr/bin/:/bin:/opt/bin`).
    case path = "PATH"
    /// The system library path
    /// (example: `/lib64:/usr/lib64:$LAMBDA_RUNTIME_DIR:$LAMBDA_RUNTIME_DIR/lib:$LAMBDA_TASK_ROOT:$LAMBDA_TASK_ROOT/lib:/opt/lib`).
    case ldLibraryPath = "LD_LIBRARY_PATH"
    /// The X-Ray tracing header.
    case traceId = "_X_AMZN_TRACE_ID"
    /// For X-Ray tracing, Lambda sets this to `LOG_ERROR`   to avoid throwing runtime errors from the X-Ray SDK.
    case xrayContextMissing = "AWS_XRAY_CONTEXT_MISSING"
    /// For X-Ray tracing, the IP address and port of the X-Ray daemon.
    case xrayDaemonAddress = "AWS_XRAY_DAEMON_ADDRESS"
}

extension AWSLambdaEnv {
    var value: String? {
        env(rawValue)
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
