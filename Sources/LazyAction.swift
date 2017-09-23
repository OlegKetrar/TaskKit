//
//  LazyAction.swift
//  TaskKit
//
//  Created by Oleg Ketrar on 17.07.17.
//  Copyright © 2017 Oleg Ketrar. All rights reserved.
//

import Foundation

/// `LazyAction` with result type `Void`.
public typealias NoResultLazyAction<T> = LazyAction<T, Void>

/// Abstract `Action` without input data.
public struct LazyAction<Input, Output> {
    let work: (Input, @escaping (Result<Output>) -> Void) -> Void
    private var onCompletion: (Result<Output>) -> Void = { _ in }

    /// Init with `work` closure.
    /// - parameter work: Closure what represents async work.
    /// Call `completion` at the end of work.
    public init(_ work: @escaping (_ input: Input, _ completion: @escaping (Result<Output>) -> Void) -> Void) {
        self.work = work
    }
}

extension LazyAction: CompletableAction {

    public var completion: (Result<Output>) -> Void {
        get { return onCompletion }
        set { onCompletion = newValue }
    }

    /// Convert to `Action` by providing input value.
    /// - parameter input:
    public func with(input: Input) -> Action<Output> {
        return Action { (ending) in self.work(input, ending) }.onAny(onCompletion)
    }

    /// Start action with input.
    public func execute(with input: Input) {
        work(input, onCompletion)
    }
}

extension LazyAction where Input == Void {
    public func execute() {
        work((), onCompletion)
    }
}

// MARK: Converion

extension LazyAction {

    /// Lightweight `then` where result can be success/failure.
    /// Does not compose action, just transform output.
    public func map<T>(_ transform: @escaping (Output) throws -> T) -> LazyAction<Input, T> {
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
    public func mapInput<T>(_ transform: @escaping (T) throws -> Input) -> LazyAction<T, Output> {
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

    /// Create sequence with action.
    /// Actions will be executed by FIFO rule (queue).
    public func then<T>(_ action: LazyAction<Output, T>) -> LazyAction<Input, T> {
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

    /// Inject result of action as a input.
    public func earlier<T>(_ action: LazyAction<T, Input>) -> LazyAction<T, Output> {
        return action.then(self)
    }

    /// Compose with `action`. `Action` will be executed before self.
    public func earlier(_ action: Action<Input>) -> Action<Output> {
        return action.then(self)
    }

    /// Ignore Action output.
    public func ignoredOutput() -> NoResultLazyAction<Input> {
        return map { _ in }
    }
}

extension LazyAction where Output == Void {

    /// Create sequence with action.
    /// Actions will be executed by FIFO rule (queue).
    public func then<T>(_ action: Action<T>) -> LazyAction<Input, T> {
        var lazyAction = LazyAction<Void, T> { (_, ending) in action.work(ending) }
        lazyAction.completion = action.completion

        return then(lazyAction)
    }
}

// MARK: Error handling

extension LazyAction {

    /// Use `recoverValue` if error occured.
    /// - parameter recoverValue: Used as action output if action failed.
    public func recover(with recoverValue: Output) -> LazyAction {
        var action = LazyAction<Input, Output> { input, ending in
            self.work(input) {
                ending(.success($0.value ?? recoverValue))
            }
        }

        action.completion = completion
        return action
    }

    /// Use `recoveryClosure` if error occured.
    /// - parameter recoveryClosure: Used for recovering action on failure.
    /// Throw error if action can't be recovered.
    public func recover(_ recoveryClosure: @escaping (Error) throws -> Output) -> LazyAction {
        var action = LazyAction<Input, Output> { input, ending in
            self.work(input) {
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
