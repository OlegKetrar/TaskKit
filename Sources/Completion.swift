//
//  CompletableAction.swift
//  TaskKit
//
//  Created by Oleg Ketrar on 22.09.17.
//  Copyright © 2017 Oleg Ketrar. All rights reserved.
//

// MARK: -

public extension LazyAction {

    /// Adds completion closure.
    /// Will be executed by FIFO rule (queue) within original action.
    func onAny( _ closure: @escaping (Result<Output>) -> Void) -> LazyAction {
        var copy      = self
        let oldEnding = completion

        copy.completion = {
            oldEnding($0)
            closure($0)
        }

        return copy
    }

    /// Adds completion closure.
    /// Will be executed by FIFO rule (queue) within original action.
    func always(_ closure: @escaping () -> Void) -> LazyAction {
        return onAny { _ in
            closure()
        }
    }
}

// MARK: - Success/Failure

public extension LazyAction {

    /// Adds completion closure which will be called if success.
    /// Will be executed by FIFO rule (queue) within original action.
    func onSuccess(_ closure: @escaping (Output) -> Void) -> LazyAction {
        return onAny {
            guard let value = $0.value else { return }
            closure(value)
        }
    }

    /// Adds completion closure which will be called if failure.
    /// Will be executed by FIFO rule (queue) within original action.
    func onFailure(_ closure: @escaping (Error) -> Void) -> LazyAction {
        return onAny {
            guard let error = $0.error else { return }
            closure(error)
        }
    }

    /// Adds completion closure which will be called only when specific
    /// error will occur.
    /// Will be executed by FIFO rule (queue) within original action.
    /// - parameter errorType: Error type to be handled.
    func onError<T: Error>(
        _ errorType: T.Type,
        _ closure: @escaping (T) -> Void) -> LazyAction {

        return onFailure {
            guard let error = $0 as? T else { return }
            closure(error)
        }
    }
}

// MARK: - Finish

public extension LazyAction {

    /// Finishing action without execution with value.
    /// - parameter value: Success output value.
    func finish(withValue value: Output) {
        completion(.success(value))
    }

    /// Finishing action without execution with error.
    /// - parameter error: Error.
    func finish(withError error: Error) {
        completion(.failure(error))
    }

    /// Finishing action without execution.
    /// - parameter result:
    func finish(with result: Result<Output>) {
        completion(result)
    }
}

public extension LazyAction where Output == Void {

    /// Finishing action without execution with success.
    func finish() {
        finish(with: .success)
    }
}
