//
//  CompletableAction.swift
//  TaskKit
//
//  Created by Oleg Ketrar on 22.09.17.
//  Copyright © 2017 Oleg Ketrar. All rights reserved.
//

public extension Action {

    /// Adds completion closure.
    /// Will be executed by FIFO rule (queue) within original action.
    func onAny( _ closure: @escaping (Result<Output>) -> Void) -> Action {
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
    func always(_ closure: @escaping () -> Void) -> Action {
        return onAny { _ in
            closure()
        }
    }
}

// MARK: - Success/Failure

public extension Action {

    /// Adds completion closure which will be called if success.
    /// Will be executed by FIFO rule (queue) within original action.
    func onSuccess(_ closure: @escaping (Output) -> Void) -> Action {
        return onAny {
            guard let value = $0.value else { return }
            closure(value)
        }
    }

    /// Adds completion closure which will be called if failure.
    /// Will be executed by FIFO rule (queue) within original action.
    func onFailure(_ closure: @escaping (Error) -> Void) -> Action {
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
        _ closure: @escaping (T) -> Void
    ) -> Action {

        return onFailure {
            guard let error = $0 as? T else { return }
            closure(error)
        }
    }
}

// MARK: - Finish

public extension Action {

    /// Finishing action without execution with value.
    /// - parameter value: Success output value.
    @available(*, deprecated)
    func finish(withValue value: Output) {
        completion(.success(value))
    }

    /// Finishing action without execution with error.
    /// - parameter error: Error.
    @available(*, deprecated)
    func finish(withError error: Error) {
        completion(.failure(error))
    }

    /// Finishing action without execution.
    /// - parameter result:
    @available(*, deprecated)
    func finish(with result: Result<Output>) {
        completion(result)
    }
}

public extension Action where Output == Void {

    /// Finishing action without execution with success.
    @available(*, deprecated)
    func finish() {
        finish(with: .success)
    }
}
