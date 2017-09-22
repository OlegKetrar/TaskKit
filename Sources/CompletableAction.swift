//
//  CompletableAction.swift
//  TaskKit
//
//  Created by Oleg Ketrar on 22.09.17.
//  Copyright © 2017 Oleg Ketrar. All rights reserved.
//

import Foundation

/// Completion will be called by FILO rule (stack).
public protocol CompletableAction {
    associatedtype ResultedValue
    var completion: (Result<ResultedValue>) -> Void { get set }
}

public extension CompletableAction {

    /// Adds completion closure which will be called if success.
    /// Will be executed by FILO rule (stack) within original action.
    func onSuccess(_ closure: @escaping (ResultedValue) -> Void) -> Self {
        var copy      = self
        let oldFinish = completion

        copy.completion = {
            if let value = $0.value {
                closure(value)
            }

            oldFinish($0)
        }

        return copy
    }

    /// Adds completion closure which will be called if failure.
    /// Will be executed by FILO rule (stack) within original action.
    func onFailure(_ closure: @escaping (Error) -> Void) -> Self {
        var copy      = self
        let oldFinish = completion

        copy.completion = {
            if let error = $0.error {
                closure(error)
            }

            oldFinish($0)
        }

        return copy
    }

    /// Adds completion closure.
    /// Will be executed by FILO rule (stack) within original action.
    func onAny(_ closure: @escaping (Result<ResultedValue>) -> Void) -> Self {
        var copy = self
        let oldFinish = completion

        copy.completion = {
            closure($0)
            oldFinish($0)
        }

        return copy
    }

    /// Adds completion closure.
    /// Will be executed by FILO rule (stack) within original action.
    func always(_ closure: @escaping () -> Void) -> Self {
        var copy      = self
        let oldFinish = completion

        copy.completion = {
            closure()
            oldFinish($0)
        }

        return copy
    }

    /// Finishing action without execution with value.
    /// - parameter value: Success output value.
    func finish(withValue value: ResultedValue) {
        completion(.success(value))
    }

    /// Finishing action without execution with error.
    /// - parameter error: Error.
    func finish(withError error: Error) {
        completion(.failure(error))
    }

    /// Finishing action without execution.
    /// - parameter result:
    func finish(with result: Result<ResultedValue>) {
        completion(result)
    }
}
