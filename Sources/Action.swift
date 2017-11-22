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
    var work: (Input, @escaping (Result<Output>) -> Void) -> Void
    var completion: (Result<Output>) -> Void = { _ in }

    public init(_ work: @escaping (Input, @escaping (Result<Output>) -> Void) -> Void) {
        self.work = work
    }

    /// Init with `asyncWork` closure.
    /// - parameter asyncWork: Closure what represents async work.
    /// Call `completion` at the end of work.
    @available(*, deprecated, renamed: "init(_:)")
    public static func makeLazy(
        _ asyncWork: @escaping (_ input: Input, _ completion: @escaping (Result<Output>) -> Void) -> Void) -> LazyAction {

        return LazyAction<Input, Output>(asyncWork)
    }

    /// Create `Action` implementing sync work.
    /// - parameter work: Encapsulate sync work.
    public static func sync(_ work: @escaping (Input) throws -> Output) -> LazyAction {
        return LazyAction<Input, Output> { input, ending in
            ending(Result { try work(input) })
        }
    }

    /// Convert to `Action` by providing input value.
    /// - parameter input:
    public func with(input: Input) -> LazyAction<Void, Output> {
        return Action { ending in self.work(input, ending) }.onAny(completion)
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
    @available(*, deprecated, renamed: "init(_:)")
    static func make(_ asyncWork: @escaping (@escaping (Result<Output>) -> Void) -> Void) -> LazyAction {
        return Action(asyncWork)
    }

    public init(_ work: @escaping (@escaping (Result<Output>) -> Void) -> Void) {
        self.init { _, ending in work(ending) }
    }

    /// Start action.
    func execute() {
        execute(with: ())
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
