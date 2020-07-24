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

// TODO: document

public protocol XRayEmitter {
    func send(_ segment: XRayRecorder.Segment)
    func flush(_ callback: @escaping (Error?) -> Void)
}

public struct XRayNoOpEmitter: XRayEmitter {
    public func send(_: XRayRecorder.Segment) {}
    public func flush(_: @escaping (Error?) -> Void) {}

    public init() {}
}
