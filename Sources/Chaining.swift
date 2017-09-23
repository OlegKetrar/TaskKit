//
//  Chaining.swift
//  TaskKit
//
//  Created by Oleg Ketrar on 23.09.17.
//  Copyright © 2017 Oleg Ketrar. All rights reserved.
//

import Foundation

public extension LazyAction {

    /// Create sequence with action.
    /// Actions will be executed by FIFO rule (queue).
    func then<T>(_ action: LazyAction<Output, T>) -> LazyAction<Input, T> {
        return LazyAction<Input, T> { (input, ending) in
            self.work(input, {

                // finish first action
                self.finish(with: $0)

                switch $0 {

                // start second action
                case let .success(secondInput):
                    action.work(secondInput) {

                        // finish second action and whole action
                        action.finish(with: $0)
                        ending($0)
                    }

                // finish second action and whole action
                case let .failure(firstError):
                    action.finish(withError: firstError)
                    ending(.failure(firstError))
                }
            })
        }
    }

    /// Lightweight `then` where result can be success/failure.
    /// Does not compose action, just transform output.
    func map<T>(_ transform: @escaping (Output) throws -> T) -> LazyAction<Input, T> {
        return LazyAction<Input, T> { (input, ending) in
            self.work(input) {
                ending($0.map(transform))
                self.finish(with: $0)
            }
        }
    }

    /// Lightweigt `eqrlier(_ action:)`.
    /// Does not compose action, just transform input.
    /// - parameter convert: closure to be injected before action.
    func mapInput<T>(_ transform: @escaping (T) throws -> Input) -> LazyAction<T, Output> {
        var action = LazyAction<T, Output> { (input, ending) in
            do {
                let converted = try transform(input)
                self.work(converted, ending)
            } catch {
                ending(.failure(error))
            }
        }

        action.completion = completion
        return action
    }
}

public extension LazyAction {

    /// Inject result of action as a input.
    func earlier<T>(_ action: LazyAction<T, Input>) -> LazyAction<T, Output> {
        return action.then(self)
    }

    /// Ignore Action output.
    func ignoredOutput() -> LazyAction<Input, Void> {
        return map { _ in }
    }

    /// Create sequence with action.
    /// Actions will be executed by FIFO rule (queue).
    func then<T>(_ work: @escaping (_ input: Output,
        _ completion: @escaping (Result<T>) -> Void) -> Void) -> LazyAction<Input, T> {

        return then(LazyAction<Output, T> { work($0, $1) })
    }
}
