//
//  Async.swift
//  TaskKit
//
//  Created by Oleg Ketrar on 24.09.17.
//  Copyright © 2017 Oleg Ketrar. All rights reserved.
//

import Foundation
import Dispatch

// MARK: Async/Await on Action

public extension LazyAction {

    /// Produce action with `closure` on `queue`.
    /// Callbacks added via `onSuccess/onFailure/onAny/always` methods
    /// will be called on `DispatchQueue.main` with execution result.
    /// - parameter queue: DispatchQueue for execution.
    /// By default `DispatchQueue.global()`.
    /// - parameter work: Closure to be executed on `queue`.
    static func async<T>(
        on queue: DispatchQueue = .global(),
        work: @escaping (Input) throws -> T) -> LazyAction<Input, T> {

        return LazyAction<Input, T>.makeLazy { input, ending in
            queue.async {
                let result = Result<T> { try work(input) }
                DispatchQueue.main.async { ending(result) }
            }
        }
    }
}

public extension LazyAction where Input == Void {

    /// Blocks current execution context and waits for action complete.
    func await() throws -> Output {
        let group  = DispatchGroup()
        var result: Result<Output>!

        group.enter()
        onAny { result = $0; group.leave() }.execute()
        group.wait()

        return try result.unwrap()
    }
}

// MARK: Convenience

public extension DispatchQueue {

    /// Produce acion with `closure` on queue.
    /// Callbacks added via `onSuccess/onFailure/onAny/always` methods
    /// will be called on `DispatchQueue.main` with execution result.
    /// - parameter closure: Closure to be executed on queue.
    func asyncValue<T>(_ closure: @escaping () throws -> T) -> Action<T> {
        return Action<T>.async(on: self, work: closure)
    }
}
