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
public struct LazyAction<Input, Output>: CompletableAction {
    let work: (Input, @escaping (Result<Output>) -> Void) -> Void
    public var finish: (Result<Output>) -> Void = { _ in }

    public init(_ closure: @escaping (Input, @escaping (Result<Output>) -> Void) -> Void) {
        work = closure
    }

    public func with(input: Input) -> Action<Output> {
        return Action { (finish) in self.work(input, finish) }.onAny(finish)
    }

    /// Start action with input.
    public func execute(with input: Input) {
        work(input, finish)
    }

    /// Lightweigt `eqrlier(_ action:)`.
    /// Does not compose action, just transform input.
    /// - parameter convert: closure to be injected before action.
    public func mapInput<T>(_ transform: @escaping (T) throws -> Input) -> LazyAction<T, Output> {
        var action = LazyAction<T, Output> { (input, finish) in
            do {
                let converted = try transform(input)
                self.work(converted, finish)
            } catch {
                finish(.failure(error))
            }
        }

        action.finish = finish
        return action
    }
}

extension LazyAction where Input == Void {
    public func execute() {
        work((), finish)
    }
}

extension LazyAction {

    /// Lightweight `then` where result can be success/failure.
    /// Does not compose action, just transform output.
    public func map<T>(_ transform: @escaping (Output) throws -> T) -> LazyAction<Input, T> {
        return LazyAction<Input, T> { (input, finish) in
            self.work(input) {
                finish($0.map(transform))
                self.finish($0)
            }
        }
    }

    /// Create sequence with action.
    /// Actions will be executed by FIFO rule (queue).
    public func then<T>(_ action: LazyAction<Output, T>) -> LazyAction<Input, T> {
        return LazyAction<Input, T> { (input, onCompletion) in
            self.work(input, {

                // finish first action
                self.finish($0)

                if let secondInput = $0.value {

                    // start second action
                    action.work(secondInput) {

                        // finish second action and whole action
                        action.finish($0)
                        onCompletion($0)
                    }

                } else {
                    let firstResult = Result<T>.failure($0.error!)

                    // finish second action and whole action
                    action.finish(firstResult)
                    onCompletion(firstResult)
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
        var lazyAction = LazyAction<Void, T> { (_, finish) in action.work(finish) }
        lazyAction.finish = action.finish

        return then(lazyAction)
    }
}
