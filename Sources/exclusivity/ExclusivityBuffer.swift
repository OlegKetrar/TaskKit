//
//  Exclusivity.swift
//  TaskKit
//
//  Created by Oleg Ketrar on 27.11.17.
//  Copyright © 2017 Oleg Ketrar. All rights reserved.
//

/// Exclusivity error.
/// Used by `ExclusivityBuffer`.
public struct ExclusivityError: Swift.Error {}

/// Execution buffer which provides execution exclusivity behaviour.
public class ExclusivityBuffer: ExecutionBuffer {
    private let buffer: ExecutionBuffer

    /// Behaviour of exclusivity buffer.
    public enum Behaviour {

        /// Ignore action call if already executing.
        case ignoreSubsequent

        /// Cancels previous action call if newest action started.
        case cancelCurrent
    }

    public init(behaviour: Behaviour) {
        switch behaviour {

        case .cancelCurrent:
            buffer = CancelFirstBuffer()

        case .ignoreSubsequent:
            buffer = IgnoreSubsequentBuffer()
        }
    }

    public func execute<Val>(task: Action<Val>) -> Action<Val> {
        return buffer.execute(task: task)
    }
}
