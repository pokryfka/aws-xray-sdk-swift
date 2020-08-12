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
    /// Creates new segment.
    ///
    /// - Parameters:
    ///   - name: segment name
    ///   - context: the trace context
    ///   - metadata: segment metadata
    ///   - body: segment body
    @inlinable
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
                segment.addError(error)
                throw error
            }
        }

    /// Creates new segment.
    ///
    /// Extracts the trace context from the baggage.
    /// Creates new one if the baggage does not contain a valid `XRayContext`.
    ///
    /// Depending on the context missing strategy configuration will log an error or fail if the context is missing.
    ///
    /// - Parameters:
    ///   - name: segment name
    ///   - baggage: baggage with the trace context
    ///   - metadata: segment metadata
    ///   - body: segment body
    @inlinable
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
                segment.addError(error)
                throw error
            }
        }
}

extension XRayRecorder.Segment {
    /// Creates new subsegment.
    ///
    /// - Parameters:
    ///   - name: segment name
    ///   - metadata: segment metadata
    ///   - body: subsegment body
    @inlinable
    public func subsegment<T>(name: String, metadata: XRayRecorder.Segment.Metadata? = nil,
                              body: (XRayRecorder.Segment) throws -> T) rethrows -> T
    {
        let segment = beginSubsegment(name: name, metadata: metadata)
        defer {
            segment.end()
        }
        do {
            return try body(segment)
        } catch {
            segment.addError(error)
            throw error
        }
    }
}
