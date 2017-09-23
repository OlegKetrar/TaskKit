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

    /// Init with `work` closure.
    /// - parameter work: Closure what represents async work.
    /// Call `completion` at the end of work.
    public init(_ work: @escaping (_ input: Input, _ completion: @escaping (Result<Output>) -> Void) -> Void) {
        self.work = work
    }

    /// Convert to `Action` by providing input value.
    /// - parameter input:
    public func with(input: Input) -> LazyAction<Void, Output> {
        return Action { (ending) in self.work(input, ending) }.onAny(completion)
    }

    /// Start action with input.
    public func execute(with input: Input) {
        work(input, completion)
    }
}

/// `Action` encapsulate async work.
public typealias Action<T> = LazyAction<Void, T>

public extension LazyAction where Input == Void {

    /// Init with `work` closure.
    /// - parameter work: Closure what represents async work.
    /// Call `completion` at the end of work.
    init(_ work: @escaping (@escaping (Result<Output>) -> Void) -> Void) {
        self.work = { work($1) }
    }

    /// Start action.
    func execute() {
        work((), completion)
    }
}

/// `Action` with result type `Void`.
public typealias NoResultAction = LazyAction<Void, Void>

/// `Action` with `Input` and result type `Void`.
public typealias NoResultLazyAction<T> = LazyAction<T, Void>
