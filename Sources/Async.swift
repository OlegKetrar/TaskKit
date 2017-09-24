//
//  Async.swift
//  TaskKit
//
//  Created by Oleg Ketrar on 24.09.17.
//  Copyright © 2017 Oleg Ketrar. All rights reserved.
//

import Foundation
import Dispatch

/// Produce Action.
public func async<T>(
    on queue: DispatchQueue = .global(),
    work: @escaping () throws -> T) -> Action<T> {

    return Action { ending in
        queue.async {
            let result = Result { try work() }
            DispatchQueue.main.async { ending(result) }
        }
    }
}

/// Blocks current execution context and wait for action complete.
public func await<T>(_ action: Action<T>) throws -> T {
    let group  = DispatchGroup()
    var result: Result<T>!

    group.enter()
    action.onAny { result = $0; group.leave() }.execute()
    group.wait()

    return try result.unwrap()
}

extension LazyAction where Input == Void {

    /// Blocks current execution context and wait for action complete.
    public func await() throws -> Output {
        return try TaskKit.await(self)
    }
}
