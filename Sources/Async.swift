//
//  Async.swift
//  TaskKit
//
//  Created by Oleg Ketrar on 24.09.17.
//  Copyright © 2017 Oleg Ketrar. All rights reserved.
//

import Foundation
import Dispatch

/// Timed out error.
public struct TimeoutError: Swift.Error {}

// MARK: - Async/Await on Action

extension Task where Failure == Swift.Error {

    /// Produce action with `closure` on `queue`.
    /// Callbacks added via `onSuccess/onFailure/onAny/always` methods
    /// will be called on `DispatchQueue.main` with execution result.
    /// - parameter queue: DispatchQueue for execution.
    /// By default `DispatchQueue.global()`.
    /// - parameter work: Closure to be executed on `queue`.
    public static func async<T>(
        on queue: DispatchQueue = .global(),
        work: @escaping () throws -> T) -> Task<T, Failure> {

        return Task<T, Failure> { ending in
            queue.async {
                let result = Swift.Result<T, Failure> { try work() }
                DispatchQueue.main.async { ending(result) }
            }
        }
    }

    /// Blocks current execution context and waits for action complete.
    /// - parameter timeout: Timeout for awaiting.
    /// Should be greater than `0`. `0` means no timeout. Default `0`.
    /// `TimeoutError` will be thrown if action finished by timed out.
    public func await(timeout: TimeInterval = 0) throws -> Success {
        let semaphore = DispatchSemaphore(value: 0)
        var result = Swift.Result<Success, Failure>.failure(TimeoutError())

        onAny { result = $0; semaphore.signal() }.run()

        if timeout > 0 {
            _ = semaphore.wait(timeout: .now() + timeout)
        } else {
            semaphore.wait()
        }

        return try result.get()
    }
}

// MARK: - Convenience

extension DispatchQueue {

    /// Produce acion with `closure` on queue.
    /// Callbacks added via `onSuccess/onFailure/onAny/always` methods
    /// will be called on `DispatchQueue.main` with execution result.
    /// - parameter closure: Closure to be executed on queue.
    public func asyncValue<T>(_ closure: @escaping () throws -> T) -> Action<T> {
        return Action<T>.async(on: self, work: closure)
    }
}
