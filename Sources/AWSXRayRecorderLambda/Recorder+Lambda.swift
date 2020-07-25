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

import AnyCodable
import AWSLambdaRuntime
import AWSXRayRecorder
import NIO

// TODO: document

// TODO: check also the Context, for example Lambda-Runtime-Invoked-Function-Arn
// both ARN and so Region are provided

extension XRayRecorder {
    private var metadata: Segment.Metadata {
        // TODO: make it configurable? define metadata plugin/factory interface
        let metadataKeys: [AWSLambdaEnv] = [.functionName, .funtionVersion, .memorySizeInMB]
        let metadataKeyValues = zip(metadataKeys, metadataKeys.map(\.value))
            .filter { $0.1 != nil }.map { ($0.0.rawValue, AnyEncodable($0.1)) }
        return Segment.Metadata(uniqueKeysWithValues: metadataKeyValues)
    }

    public func beginSegment(name: String, context: Lambda.Context) -> Segment {
        // TODO: Implement AWS plugins https://github.com/pokryfka/aws-xray-sdk-swift/issues/26
//        let aws = XRayRecorder.Segment.AWS(region: AWSLambdaEnv.region.value, requestId: context.requestID)
        if let context = try? XRayRecorder.TraceContext(tracingHeader: context.traceID) {
            return beginSegment(name: name, context: context, metadata: metadata)
        } else {
            let context = XRayRecorder.TraceContext()
            return beginSegment(name: name, context: context, metadata: metadata)
        }
    }
}

extension XRayRecorder {
    @inlinable
    public func segment<T>(name: String, context: Lambda.Context, body: (Segment) throws -> T) rethrows -> T
    {
        let segment = beginSegment(name: name, context: context)
        defer {
            segment.end()
        }
        do {
            return try body(segment)
        } catch {
            segment.setError(error)
            throw error
        }
    }
}

extension XRayRecorder {
    @inlinable
    public func segment<T>(name: String, context: Lambda.Context, body: () -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        let segment = beginSegment(name: name, context: context)
        return body().always { result in
            if case Result<T, Error>.failure(let error) = result {
                segment.setError(error)
            }
            segment.end()
        }
    }
}
