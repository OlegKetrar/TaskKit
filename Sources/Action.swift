//
//  Action.swift
//  TaskKit
//
//  Created by Oleg Ketrar on 17.07.17.
//  Copyright © 2017 Oleg Ketrar. All rights reserved.
//

import Foundation

/// `Action` with result type `Void`.
public typealias NoResultAction = Action<Void>

/// `Action` encapsulate some async work.
public struct Action<Output> {
    let work: (@escaping (Result<Output>) -> Void) -> Void
    private var onCompletion: (Result<Output>) -> Void = { _ in }

    ///
    public init(_ closure: @escaping (@escaping (Result<Output>) -> Void) -> Void) {
        work = closure
    }
}

extension Action: CompletableAction {

    public var completion: (Result<Output>) -> Void {
        get { return onCompletion }
        set { onCompletion = newValue }
    }

    /// Start action.
    public func execute() {
        work(onCompletion)
    }
}

// MARK: Convertion

extension Action {

    /// Lightweight `then` where result always success.
    /// Does not compose action, just transform output.
    public func map<T>(_ transform: @escaping (Output) throws -> T) -> Action<T> {
        return Action<T> { (ending) in
            self.work {
                ending($0.map(transform))
                self.finish(with: $0)
            }
        }
    }

    /// Create sequence with `action`.
    /// Actions will be executed by FIFO rule (queue).
    public func then<T>(_ action: LazyAction<Output, T>) -> Action<T> {
        return Action<T> { (ending) in
            self.work {

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
            }
        }
    }

    /// Inject result of `action` as a input.
    public func earlier(_ action: NoResultAction) -> Action<Output> {
        return action.then(self)
    }

    /// Inject result of `action` as a input.
    public func earlier<T>(_ action: NoResultLazyAction<T>) -> LazyAction<T, Output> {
        return action.then(self)
    }

    /// Ignore Action output.
    public func ignoredOutput() -> NoResultAction {
        return map { _ in }
    }
}

extension Action where Output == Void {

    /// Create sequence with action.
    /// Actions will be executed by FIFO rule (queue).
    public func then<T>(_ action: Action<T>) -> Action<T> {
        var lazyAction = LazyAction<Void, T> { _, finish in action.work(finish) }
        lazyAction.completion = action.completion

        return then(lazyAction)
    }
}

// MARK: Error handling

extension Action {

    /// Use `recoverValue` if error occured.
    /// - parameter recoverValue: Used as action output if action failed.
    public func recover(with recoverValue: Output) -> Action {
        var action = Action<Output> { ending in
            self.work {
                ending(.success($0.value ?? recoverValue))
            }
        }

        action.completion = completion
        return action
    }

    /// Use `recoveryClosure` if error occured.
    /// - parameter recoveryClosure: Used for recovering action on failure.
    /// Throw error if action can't be recovered.
    public func recover(_ recoveryClosure: @escaping (Error) throws -> Output) -> Action {
        var action = Action<Output> { ending in
            self.work {
                if let error = $0.error {
                    ending(Result { try recoveryClosure(error) })
                } else {
                    ending($0)
                }
            }
        }

        action.completion = completion
        return action
    }
}
