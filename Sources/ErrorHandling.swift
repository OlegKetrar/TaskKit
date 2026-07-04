//
//  ErrorHandling.swift
//  TaskKit
//
//  Created by Oleg Ketrar on 23.09.17.
//  Copyright © 2017 Oleg Ketrar. All rights reserved.
//

public extension Action {

    /// Use `recoveryClosure` if error occured.
    /// - parameter recoveryClosure: Used for recovering action on failure.
    /// Throw error if action can't be recovered.
    func recover(_ recoveryClosure: @escaping (Error) throws -> Output) -> Action {

        var action = Action<Output> { ending in
            self.work() {
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

    /// Use `recoveryClosure` if error occured of type `T`
    /// - parameter recoveryClosure: Used for recovering action on failure with error of type `T`.
    /// Throw error if action can't be recovered.
    func recover<T: Error>(
        on errorType: T.Type,
        _ recoveryClosure: @escaping (T) throws -> Output
    ) -> Action {

        return recover {
            guard let error = $0 as? T else { throw $0 }
            return try recoveryClosure(error)
        }
    }

    /// Use `recoverValue` if error occured.
    /// - parameter recoverValue: Used as action output if action failed.
    func recover(with recoverValue: Output) -> Action {
        return recover { _ in recoverValue }
    }

    /// Use `recoverValue` if error occured of type `T`.
    /// - parameter recoverValue: Used as action output if action failed with error of type `T`.
    func recover<T: Error>(on errorType: T.Type, with recoverValue: Output) -> Action {
        return recover(on: errorType, { _ in recoverValue })
    }
}
