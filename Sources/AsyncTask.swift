//
//  AsyncTask.swift
//  TaskKit
//
//  Created by Oleg Ketrar on 17.07.17.
//  Copyright © 2017 Oleg Ketrar. All rights reserved.
//

/// `AsyncTask` encapsulate async work.
public struct AsyncTask<Success, Failure: Swift.Error> {
    public typealias Result = Swift.Result<Success, Failure>
    public typealias Completion = (Result) -> Void
    public typealias Work = (@escaping Completion) -> Void

    var work: Work
    var completion: Completion

    public init(_ work: @escaping Work) {
        self.work = work
        self.completion = { _ in }
    }

    public func run() {
        work(completion)
    }

    public static func value(_ val: Success) -> AsyncTask {
        AsyncTask { ending in ending(.success(val)) }
    }
}

extension AsyncTask where Failure == Swift.Error {

    /// Create `Action` implementing sync work.
    /// - parameter work: Encapsulate sync work.
    public static func sync(_ work: @escaping () throws -> Success) -> AsyncTask {
        return AsyncTask { ending in ending(Result { try work() }) }
    }
}

extension AsyncTask where Failure == Never {

    /// Create `Action` implementing sync work.
    /// - parameter work: Encapsulate sync work.
    public static func sync(_ work: @escaping () -> Success) -> AsyncTask {
        return AsyncTask { ending in ending(.success(work())) }
    }
}

extension AsyncTask where Success == Void, Failure == Swift.Error {

    public static var nothing: AsyncTask {
        return .sync {}
    }
}

extension AsyncTask where Success == Void, Failure == Never {

    public static var nothing: AsyncTask {
        return .sync {}
    }
}
