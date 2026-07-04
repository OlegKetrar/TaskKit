//
//  Chaining.swift
//  TaskKit
//
//  Created by Oleg Ketrar on 23.09.17.
//  Copyright © 2017 Oleg Ketrar. All rights reserved.
//

public extension Action {

    /// Create sequence with action.
    /// Actions will be executed by FIFO rule (queue).
    func then<T>(_ doNext: @escaping (Output) -> Action<T>) -> Action<T> {
        then { resultValue, resolve in
            doNext(resultValue)
                .onAny(resolve)
                .execute()
        }
    }

    /// Create sequence with action.
    /// Actions will be executed by FIFO rule (queue).
    func then<T>(
        _ next: @escaping (
            _ input: Output,
            _ completion: @escaping (Result<T>) -> Void
        ) -> Void
    ) -> Action<T> {

        Action<T> { resolve in
            self.work({
                self.completion($0)

                switch $0 {
                case let .success(value): next(value, resolve)
                case let .failure(error): resolve(.failure(error))
                }
            })
        }
    }

    /// Lightweight `then` where result can be success/failure.
    /// Does not compose action, just transform output.
    func map<T>(_ transform: @escaping (Output) throws -> T) -> Action<T> {
        return Action<T> { ending in
            self.work() {
                ending($0.map(transform))
                self.completion($0)
            }
        }
    }

    /// Ignore Action output.
    func ignoredOutput() -> Action<Void> {
        return map { _ in }
    }
}
