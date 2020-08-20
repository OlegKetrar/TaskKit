//
//  CancelFirstBuffer.swift
//  TaskKit
//
//  Created by Oleg Ketrar on 21.08.2020.
//  Copyright © 2020 Oleg Ketrar. All rights reserved.
//

import Foundation

/// Implements `cancelCurrent` exclusivity behaviour.
final class CancelFirstBuffer: ExecutionBuffer {
    private let lock = NSRecursiveLock()

    private var counter: Int = 0
    private var mainActionID: Int = 0

    func execute<Val>(task: Action<Val>) -> Action<Val> {
        return Task { ending in

            // generate unique identifier for current action call
            let actionID: Int = self.lock.sync {
                self.counter += 1
                return self.counter
            }

            // mark current action as finishable by saving actionID
            // mark previous started actions as not finishable
            self.lock.sync { self.mainActionID = actionID }

            // execute action
            task.work {

                // check if current action finishable
                if self.lock.sync({ self.mainActionID == actionID }) {
                    task.finish(with: $0)
                    ending($0)

                } else {

                    // finish action with exclusivity error
                    task.finish(withError: ExclusivityError())
                    ending(.failure(ExclusivityError()))
                }
            }
        }
    }
}

extension NSRecursiveLock {

    func sync<T>(_ critical: () -> T) -> T {

        lock()
        let value = critical()
        unlock()

        return value
    }
}
