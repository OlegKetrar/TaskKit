//
//  Completion.swift
//  TaskKit
//
//  Created by Oleg Ketrar on 22.09.17.
//  Copyright © 2017 Oleg Ketrar. All rights reserved.
//

extension Task {

    /// Adds completion closure.
    /// Will be executed by FIFO rule (queue) within original action.
    public func onAny(_ closure: @escaping Completion) -> Task {
        var copy = self
        let oldEnding = completion

        copy.completion = {
            oldEnding($0)
            closure($0)
        }

        return copy
    }

    /// Adds completion closure.
    /// Will be executed by FIFO rule (queue) within original action.
    public func always(_ closure: @escaping () -> Void) -> Task {
        return onAny { _ in
            closure()
        }
    }

    /// Adds completion closure which will be called if success.
    /// Will be executed by FIFO rule (queue) within original action.
    public func onSuccess(_ closure: @escaping (Success) -> Void) -> Task {
        return onAny {
            guard let value = $0.value else { return }
            closure(value)
        }
    }

    /// Adds completion closure which will be called if failure.
    /// Will be executed by FIFO rule (queue) within original action.
    public func onFailure(_ closure: @escaping (Failure) -> Void) -> Task {
        return onAny {
            guard let error = $0.error else { return }
            closure(error)
        }
    }

    /// Adds completion closure which will be called only when specific
    /// error will occur.
    /// Will be executed by FIFO rule (queue) within original action.
    /// - parameter errorType: Error type to be handled.
    public func onError<T: Swift.Error>(
        of type: T.Type,
        _ closure: @escaping (T) -> Void
    ) -> Task {

        return onFailure {
            guard let error = $0 as? T else { return }
            closure(error)
        }
    }

    /// Adds completion closure which will be called only when specific
    /// error will occur.
    /// Will be executed by FIFO rule (queue) within original action.
    /// - parameter errorType: Error type to be handled.
    public func onError<T: Swift.Error & Equatable>(
        is instance: T,
        _ closure: @escaping (T) -> Void
    ) -> Task {

        return onFailure {
            guard let error = $0 as? T, error == instance else { return }
            closure(error)
        }
    }
}


// MARK: - Finish

extension Task {

    /// Finishing action without execution with value.
    /// - parameter value: Success output value.
    public func finish(withValue value: Success) {
        completion(.success(value))
    }

    /// Finishing action without execution with error.
    /// - parameter error: Error.
    public func finish(withError error: Failure) {
        completion(.failure(error))
    }

    /// Finishing action without execution.
    /// - parameter result:
    public func finish(with result: Result) {
        completion(result)
    }
}

extension Task where Success == Void {

    /// Finishing action without execution with success.
    public func finish() {
        finish(with: .success)
    }
}
