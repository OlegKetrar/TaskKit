//
//  Then.swift
//  TaskKit
//
//  Created by Oleg Ketrar on 23.09.17.
//  Copyright © 2017 Oleg Ketrar. All rights reserved.
//

extension Task {

    /// Create sequence with action.
    /// Actions will be executed by FIFO rule (queue).
    public func then<T>(
        _ closure: @escaping (Success) -> Task<T, Failure>
    ) -> Task<T, Failure> {

        return Task<T, Failure> { ending in
            self.work {

                // finish first task
                self.completion($0)

                switch $0 {
                case let .success(value):
                    let nextTask = closure(value)
                    nextTask.onAny(ending).run()

                case let .failure(error):
                    self.completion(.failure(error))
                    ending(.failure(error))
                }
            }
        }
    }
}
