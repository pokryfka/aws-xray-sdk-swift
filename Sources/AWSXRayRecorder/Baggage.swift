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

private enum XRayContextKey: BaggageKey {
    typealias Value = XRayRecorder.TraceContext
    var name: String { "XRayTraceContext" }
}

public extension Baggage {
    /// Contains `XRayContext`.
    var xRayContext: XRayContext? {
        get {
            self[XRayContextKey.self]
        }
        set {
            self[XRayContextKey.self] = newValue
        }
    }
}

internal extension Baggage {
    func withParent(_ parentId: XRayRecorder.Segment.ID) throws -> Baggage {
        guard var context = xRayContext else { throw XRayRecorder.TraceError.missingContext }
        context.parentId = parentId
        var updated = self
        updated.xRayContext = context
        return updated
    }
}
