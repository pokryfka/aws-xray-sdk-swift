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

import Baggage

extension XRayRecorder {
    @inlinable
    @discardableResult
    public func segment<T>(name: String, context: TraceContext, metadata: XRayRecorder.Segment.Metadata? = nil,
                           body: (Segment) throws -> T)
        rethrows -> T
    {
        let segment = beginSegment(name: name, context: context, metadata: metadata)
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

    @inlinable
    @discardableResult
    public func segment<T>(name: String, baggage: BaggageContext, metadata: XRayRecorder.Segment.Metadata? = nil,
                           body: (Segment) throws -> T)
        rethrows -> T
    {
        let segment = beginSegment(name: name, baggage: baggage, metadata: metadata)
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

extension XRayRecorder.Segment {
    @inlinable
    @discardableResult
    public func subsegment<T>(name: String, metadata: XRayRecorder.Segment.Metadata? = nil,
                              body: (XRayRecorder.Segment) throws -> T) rethrows -> T {
        let segment = beginSubsegment(name: name, metadata: metadata)
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
