//
//  Exclusivity.swift
//  TaskKit
//
//  Created by Oleg Ketrar on 27.11.17.
//  Copyright © 2017 Oleg Ketrar. All rights reserved.
//

import Foundation

/// Exclusivity error.
/// Used by `ExclusivityBuffer`.
public struct ExclusivityError: Swift.Error {}

/// Execution buffer which provides execution exclusivity behaviour.
public class ExclusivityBuffer: ExecutionBuffer {
    private let buffer: ExecutionBuffer

    /// Behaviour of exclusivity buffer.
    public enum Behaviour {

        /// Cancels previous action call if newest action started.
        case ignoreSubsequent

        /// Ignore action call if already executing.
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

    public func execute<In, Out>(action: LazyAction<In, Out>) -> LazyAction<In, Out> {
        return buffer.execute(action: action)
    }
}

/// Implements `ignoreSubsequent` exclusivity behaviour.
private final class IgnoreSubsequentBuffer: ExecutionBuffer {
    private let lock = NSLock()
    private var isExecuting: Bool = false

    func execute<In, Out>(action: LazyAction<In, Out>) -> LazyAction<In, Out> {
        return LazyAction<In, Out> { input, ending in

            // is already executing
            if self.lock.locked({ self.isExecuting }) {

                // finish action with error
                action.finish(with: .failure(ExclusivityError()))
                ending(.failure(ExclusivityError()))

            } else {

                // block execution flow to action
                self.lock.locked { self.isExecuting = true }

                //
                action.work(input, {

                    // unblock execution flow
                    self.lock.locked { self.isExecuting = false }

                    // finish action
                    action.finish(with: $0)
                    ending($0)
                })
            }
        }
    }
}

/// Implements `cancelCurrent` exclusivity behaviour.
private final class CancelFirstBuffer: ExecutionBuffer {
    private let lock = NSLock()

    private var counter: Int      = 0
    private var mainActionID: Int = 0

    func execute<In, Out>(action: LazyAction<In, Out>) -> LazyAction<In, Out> {
        return LazyAction<In, Out> { input, ending in

            // generate unique identifier for current action call
            let actionID: Int = self.lock.locked {
                self.counter += 1
                return self.counter
            }

            // mark current action as finishable by saving actionID
            // mark previous started actions as not finishable
            self.lock.locked { self.mainActionID = actionID }

            // execute action
            action.work(input, {

                // check if current action finishable
                if self.lock.locked({ self.mainActionID == actionID }) {
                    action.finish(with: $0)
                    ending($0)

                } else {

                    // finish action with exclusivity error
                    action.finish(withError: ExclusivityError())
                    ending(.failure(ExclusivityError()))
                }
            })
        }
    }
}

private extension NSLock {

    func locked<T>(_ closure: () -> T) -> T {

        lock()
        let value = closure()
        unlock()

        return value
    }
}
