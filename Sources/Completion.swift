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
    func always(_ closure: @escaping () -> Void) -> Action {
        return onAny { _ in
            closure()
        }
    }

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
