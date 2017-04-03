//
//  Result.swift
//  TaskKit
//
//  Created by Oleg Ketrar on 30.03.17.
//  Copyright © 2017 Oleg Ketrar. All rights reserved.
//

import Foundation

public enum Result<T> {
    case success(T)
    case failure(Error?)
}

extension Result {
    public var isSuccess: Bool {
        return value != nil
    }

    public var isFailure: Bool {
        return !isSuccess
    }

    public var value: T? {
        guard case let .success(value) = self else { return nil }
        return value
    }

    public var error: Error? {
        guard case let .failure(error) = self else { return nil }
        return error
    }

    public func unwrap() throws -> T {
        switch self {
        case .success(let value):
            return value
        case .failure(let error):
            throw error!
        }
    }

    public static var emptyFailure: Result {
        return .failure(nil)
    }
}

extension Result where T == Void {
    public static var emptySuccess: Result {
        return .success(Void())
    }
}

extension Result: CustomStringConvertible {
    public var description: String {
        switch self  {
        case .success:
            return "success"

        case .failure:
            return "failure"
        }
    }
}

extension Result: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case let .success(value):
            return "success: \(value)"

        case let .failure(.some(error)):
            return "failure: \(error))"

        case .failure(.none):
            return "failure"
        }
    }
}
