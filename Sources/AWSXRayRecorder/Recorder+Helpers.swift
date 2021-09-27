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

import InstrumentationBaggage

public extension XRayRecorder {
    /// Creates new segment.
    ///
    /// Records thrown `Error`.
    ///
    /// - Parameters:
    ///   - name: segment name
    ///   - context: the trace context
    ///   - startTime: start time, defaults to now
    ///   - metadata: segment metadata
    ///   - body: segment body
    @inlinable
    func segment<T>(name: String, context: TraceContext, startTime: XRayRecorder.Timestamp = .now(),
                    metadata: XRayRecorder.Segment.Metadata? = nil,
                    body: (XRayRecorder.Segment) throws -> T)
        rethrows -> T
    {
        let segment = beginSegment(name: name, context: context, startTime: startTime, metadata: metadata)
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
    /// Records thrown `Error`.
    ///
    /// Extracts the trace context from the baggage.
    /// Creates new one if the baggage does not contain a valid `XRayContext`.
    ///
    /// Depending on the context missing strategy configuration will log an error or fail if the context is missing.
    ///
    /// - Parameters:
    ///   - name: segment name
    ///   - baggage: baggage with the trace context
    ///   - startTime: start time, defaults to now
    ///   - metadata: segment metadata
    ///   - body: segment body
    @inlinable
    func segment<T>(name: String, baggage: Baggage, startTime: XRayRecorder.Timestamp = .now(),
                    metadata: XRayRecorder.Segment.Metadata? = nil,
                    body: (XRayRecorder.Segment) throws -> T)
        rethrows -> T
    {
        let segment = beginSegment(name: name, baggage: baggage, startTime: startTime, metadata: metadata)
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
    /// Records thrown `Error` and `.failure`.
    ///
    /// - Parameters:
    ///   - name: segment name
    ///   - context: the trace context
    ///   - startTime: start time, defaults to now
    ///   - metadata: segment metadata
    ///   - body: segment body
    @inlinable
    func segment<T, E>(name: String, context: TraceContext, startTime: XRayRecorder.Timestamp = .now(),
                       metadata: XRayRecorder.Segment.Metadata? = nil,
                       body: (XRayRecorder.Segment) throws -> Result<T, E>)
        rethrows -> Result<T, E>
    {
        let segment = beginSegment(name: name, context: context, startTime: startTime, metadata: metadata)
        defer {
            segment.end()
        }
        do {
            let result = try body(segment)
            if case Result<T, E>.failure(let error) = result {
                segment.addError(error)
            }
            return result
        } catch {
            segment.addError(error)
            throw error
        }
    }

    /// Creates new segment.
    ///
    /// Records thrown `Error` and `.failure`.
    ///
    /// Extracts the trace context from the baggage.
    /// Creates new one if the baggage does not contain a valid `XRayContext`.
    ///
    /// Depending on the context missing strategy configuration will log an error or fail if the context is missing.
    ///
    /// - Parameters:
    ///   - name: segment name
    ///   - baggage: baggage with the trace context
    ///   - startTime: start time, defaults to now
    ///   - metadata: segment metadata
    ///   - body: segment body
    @inlinable
    func segment<T, E>(name: String, baggage: Baggage, startTime: XRayRecorder.Timestamp = .now(),
                       metadata: XRayRecorder.Segment.Metadata? = nil,
                       body: (XRayRecorder.Segment) throws -> Result<T, E>)
        rethrows -> Result<T, E>
    {
        let segment = beginSegment(name: name, baggage: baggage, startTime: startTime, metadata: metadata)
        defer {
            segment.end()
        }
        do {
            let result = try body(segment)
            if case Result<T, E>.failure(let error) = result {
                segment.addError(error)
            }
            return result
        } catch {
            segment.addError(error)
            throw error
        }
    }
}

public extension XRayRecorder.Segment {
    /// Creates new subsegment.
    ///
    /// Records thrown `Error`.
    ///
    /// - Parameters:
    ///   - name: segment name
    ///   - startTime: start time, defaults to now
    ///   - metadata: segment metadata
    ///   - body: subsegment body
    @inlinable
    func subsegment<T>(name: String, startTime: XRayRecorder.Timestamp = .now(),
                       metadata: XRayRecorder.Segment.Metadata? = nil,
                       body: (XRayRecorder.Segment) throws -> T) rethrows -> T
    {
        let segment = beginSubsegment(name: name, startTime: startTime, metadata: metadata)
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

    /// Creates new subsegment.
    ///
    /// Records thrown `Error` and `.failure`.
    ///
    /// - Parameters:
    ///   - name: segment name
    ///   - startTime: start time, defaults to now
    ///   - metadata: segment metadata
    ///   - body: subsegment body
    @inlinable
    func subsegment<T, E>(name: String, startTime: XRayRecorder.Timestamp = .now(),
                          metadata: XRayRecorder.Segment.Metadata? = nil,
                          body: (XRayRecorder.Segment) throws -> Result<T, E>) rethrows -> Result<T, E>
    {
        let segment = beginSubsegment(name: name, startTime: startTime, metadata: metadata)
        defer {
            segment.end()
        }
        do {
            let result = try body(segment)
            if case Result<T, E>.failure(let error) = result {
                segment.addError(error)
            }
            return result
        } catch {
            segment.addError(error)
            throw error
        }
    }
}
