//
//  LazyAction.swift
//  TaskKit
//
//  Created by Oleg Ketrar on 17.07.17.
//  Copyright © 2017 Oleg Ketrar. All rights reserved.
//

/// `LazyAction` encapsulate async work.
/// Taking `Input` and produce `Output` value.
public struct LazyAction<Input, Output> {
    var work: (Input, @escaping (Result<Output>) -> Void) -> Void
    var completion: (Result<Output>) -> Void = { _ in }

    public init(_ work: @escaping (Input, @escaping (Result<Output>) -> Void) -> Void) {
        self.work = work
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

// MARK: - Convenience

/// `Action` encapsulate async work.
public typealias Action<T> = LazyAction<Void, T>

public extension LazyAction {

    /// Create `Action` implementing sync work.
    /// - parameter work: Encapsulate sync work.
    static func sync(_ work: @escaping (Input) throws -> Output) -> LazyAction {
        return LazyAction<Input, Output> { input, ending in
            ending(Result { try work(input) })
        }
    }

    static func value(
        _ val: @autoclosure @escaping () throws -> Output) -> LazyAction<Void, Output> {

        return LazyAction<Void, Output>.sync(val)
    }
}

public extension LazyAction where Input == Void {

    init(_ work: @escaping (@escaping (Result<Output>) -> Void) -> Void) {
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
