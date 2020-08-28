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

@testable import AWSXRayInstrument

import AWSXRayRecorder
import Baggage

private typealias XRayContext = XRayRecorder.TraceContext

extension BaggageContext {
    static func empty() -> BaggageContext {
        BaggageContext()
    }

    static func withTracingHeader(_ tracingHeader: String) -> BaggageContext {
        var context = BaggageContext()
        context.xRayContext = try? XRayContext(tracingHeader: tracingHeader)
        return context
    }

    static func withoutParentSampled() -> BaggageContext {
        var context = BaggageContext()
        context.xRayContext = XRayContext(traceId: .init(), parentId: nil, sampled: true)
        return context
    }

    static func withoutParentNotSampled() -> BaggageContext {
        var context = BaggageContext()
        context.xRayContext = XRayContext(traceId: .init(), parentId: nil, sampled: false)
        return context
    }
}
