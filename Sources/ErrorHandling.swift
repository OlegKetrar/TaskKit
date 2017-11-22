//
//  ErrorHandling.swift
//  TaskKit
//
//  Created by Oleg Ketrar on 23.09.17.
//  Copyright © 2017 Oleg Ketrar. All rights reserved.
//

import Foundation

// TODO: `catch`

public extension LazyAction {

    /// Use `recoverValue` if error occured.
    /// - parameter recoverValue: Used as action output if action failed.
    func recover(with recoverValue: Output) -> LazyAction {
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
    func recover(_ recoveryClosure: @escaping (Error) throws -> Output) -> LazyAction {
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
