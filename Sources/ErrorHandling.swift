//
//  ErrorHandling.swift
//  TaskKit
//
//  Created by Oleg Ketrar on 23.09.17.
//  Copyright © 2017 Oleg Ketrar. All rights reserved.
//

extension AsyncTask where Failure == Swift.Error {

    /// Use `recoveryClosure` if error occured.
    /// - parameter recoveryClosure: Used for recovering action on failure.
    /// Throw error if action can't be recovered.
    public func recover(
        _ recoveryClosure: @escaping (Failure) throws -> Success
    ) -> AsyncTask {

        var action = AsyncTask<Success, Failure> { ending in
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

    /// Use `recoveryClosure` if error occured of type `T`
    /// - parameter recoveryClosure: Used for recovering action on failure with error of type `T`.
    /// Throw error if action can't be recovered.
    public func recover<T: Error>(
        on errorType: T.Type,
        _ recoveryClosure: @escaping (T) throws -> Success
    ) -> AsyncTask {

        return recover {
            guard let error = $0 as? T else { throw $0 }
            return try recoveryClosure(error)
        }
    }

    /// Use `recoverValue` if error occured.
    /// - parameter recoverValue: Used as action output if action failed.
    public func recover(with recoverValue: Success) -> AsyncTask {
        return recover { _ in recoverValue }
    }

    /// Use `recoverValue` if error occured of type `T`.
    /// - parameter recoverValue: Used as action output if action failed with error of type `T`.
    public func recover<T: Error>(
        on errorType: T.Type,
        with recoverValue: Success
    ) -> AsyncTask {

        return recover(on: errorType, { _ in recoverValue })
    }
}
