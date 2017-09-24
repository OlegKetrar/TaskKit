//
//  LazyAction.swift
//  TaskKit
//
//  Created by Oleg Ketrar on 17.07.17.
//  Copyright © 2017 Oleg Ketrar. All rights reserved.
//

import Foundation

/// `LazyAction` encapsulate async work.
/// Taking `Input` and produce `Output` value.
public struct LazyAction<Input, Output> {
    var work: (Input, @escaping (Result<Output>) -> Void) -> Void = { _, _ in }
    var completion: (Result<Output>) -> Void = { _ in }

    private init() {}

    /// Init with `asyncWork` closure.
    /// - parameter asyncWork: Closure what represents async work.
    /// Call `completion` at the end of work.
    public static func makeLazy(
        _ asyncWork: @escaping (_ input: Input, _ completion: @escaping (Result<Output>) -> Void) -> Void) -> LazyAction {

        var action  = LazyAction()
        action.work = asyncWork

        return action
    }

    /// Create `Action` implementing sync work.
    /// - parameter work: Encapsulate sync work.
    public static func sync(_ work: @escaping (Input) throws -> Output) -> LazyAction {
        return LazyAction<Input, Output>.makeLazy { input, ending in
            ending(Result {
                try work(input)
            })
        }
    }

    /// Convert to `Action` by providing input value.
    /// - parameter input:
    public func with(input: Input) -> LazyAction<Void, Output> {
        return Action.make { ending in self.work(input, ending) }.onAny(completion)
    }

    /// Start action with input.
    public func execute(with input: Input) {
        work(input, completion)
    }
}

/// `Action` encapsulate async work.
public typealias Action<T> = LazyAction<Void, T>

public extension LazyAction where Input == Void {

    /// Init with `asyncWork` closure.
    /// - parameter asyncWork: Closure what represents async work.
    /// Call `completion` at the end of work.
    static func make(_ asyncWork: @escaping (@escaping (Result<Output>) -> Void) -> Void) -> LazyAction {
        var action = LazyAction()
        action.work = { asyncWork($1) }

        return action
    }

    /// Start action.
    func execute() {
        work((), completion)
    }

    /// Adds `successCompletion` as `onSuccess` and start action.
    /// - parameter successCompletion: Closure will be called if action succeed.
    func execute(_ successCompletion: @escaping (Output) -> Void) {
        onSuccess(successCompletion).execute()
    }
}

/// `Action` with result type `Void`.
public typealias NoResultAction = LazyAction<Void, Void>

/// `Action` with `Input` and result type `Void`.
public typealias NoResultLazyAction<T> = LazyAction<T, Void>
