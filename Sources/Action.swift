//
//  Action.swift
//  TaskKit
//
//  Created by Oleg Ketrar on 17.07.17.
//  Copyright © 2017 Oleg Ketrar. All rights reserved.
//

/// `Action` encapsulate async work returning Output or Swift.Error.
public struct Action<Output> {
    var work: (@escaping (Result<Output>) -> Void) -> Void
    var completion: (Result<Output>) -> Void = { _ in }

    public init(_ work: @escaping (@escaping (Result<Output>) -> Void) -> Void) {
        self.work = work
    }

    /// Start action with input.
    public func execute() {
        work(completion)
    }
}

// MARK: - Convenience

public extension Action {

    /// Create `Action` implementing sync work.
    /// - parameter work: Encapsulate sync work.
    static func sync(_ work: @escaping () throws -> Output) -> Self {
        Action<Output> { ending in
            ending(Result { try work() })
        }
    }

    static func value(_ val: @autoclosure @escaping () throws -> Output) -> Self {
        Action<Output>.sync(val)
    }
}

public extension Action {

    /// Adds `successCompletion` as `onSuccess` and start action.
    /// - parameter successCompletion: Closure will be called if action succeed.
    func execute(_ successCompletion: @escaping (Output) -> Void) {
        onSuccess(successCompletion).execute()
    }
}
