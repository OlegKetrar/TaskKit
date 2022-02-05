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

    /// Create sequence with action.
    /// Actions will be executed by FIFO rule (queue).
    public func then<T>(
        _ closure: @escaping (Success) -> SuccessTask<T>
    ) -> Task<T, Failure> {

        return Task<T, Failure> { ending in
            self.work {

                // finish first task
                self.completion($0)

                switch $0 {
                case let .success(value):
                    let nextTask = closure(value)
                    nextTask.onSuccess { ending(.success($0)) }.run()

                case let .failure(error):
                    self.completion(.failure(error))
                    ending(.failure(error))
                }
            }
        }
    }
}

extension Task where Failure == Never {

    /// Create sequence with action.
    /// Actions will be executed by FIFO rule (queue).
    public func then<T>(
        _ closure: @escaping (Success) -> SuccessTask<T>
    ) -> SuccessTask<T> {

        return SuccessTask<T> { ending in
            self.work {

                // finish first task
                self.completion($0)

                if let value = $0.value {
                    let nextTask = closure(value)
                    nextTask.onAny(ending).run()
                }
            }
        }
    }

    /// Create sequence with action.
    /// Actions will be executed by FIFO rule (queue).
    public func then<T, F: Swift.Error>(
        _ closure: @escaping (Success) -> Task<T, F>
    ) -> Task<T, F> {

        return Task<T, F> { ending in
            self.work {

                // finish first task
                self.completion($0)

                if let value = $0.value {
                    let nextTask = closure(value)
                    nextTask.onAny(ending).run()
                }
            }
        }
    }
}
