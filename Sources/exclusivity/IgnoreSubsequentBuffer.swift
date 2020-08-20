//
//  IgnoreSubsequentBuffer.swift
//  TaskKit
//
//  Created by Oleg Ketrar on 21.08.2020.
//  Copyright © 2020 Oleg Ketrar. All rights reserved.
//

import Foundation

/// Implements `ignoreSubsequent` exclusivity behaviour.
final class IgnoreSubsequentBuffer: ExecutionBuffer {
    private let lock = NSRecursiveLock()
    private var isExecuting: Bool = false

    func execute<Val>(task: Action<Val>) -> Action<Val> {
        return Task { ending in

            // is already executing
            if self.lock.sync({ self.isExecuting }) {

                // finish action with error
                task.finish(with: .failure(ExclusivityError()))
                ending(.failure(ExclusivityError()))

            } else {

                // block execution flow to action
                self.lock.sync { self.isExecuting = true }

                //
                task.work {

                    // unblock execution flow
                    self.lock.sync { self.isExecuting = false }

                    // finish action
                    task.finish(with: $0)
                    ending($0)
                }
            }
        }
    }
}
