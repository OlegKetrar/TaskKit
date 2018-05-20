//
//  Result.swift
//  TaskKit
//
//  Created by Oleg Ketrar on 30.03.17.
//  Copyright © 2017 Oleg Ketrar. All rights reserved.
//

import Foundation

/// Encapsulate and wrap result of any operation success/failure
public enum Result<Wrapped> {
    case success(Wrapped)
    case failure(Error)
}

extension Result {

    /// Returns value if `success`, otherwise `nil`.
    public var value: Wrapped? {
        guard case let .success(value) = self else { return nil }
        return value
    }

    /// Returns error if `failure`, otherwise `nil`.
    public var error: Error? {
        guard case let .failure(error) = self else { return nil }
        return error
    }

    public var isSuccess: Bool {
        if case .success = self {
            return true
        } else {
            return false
        }
    }

    public var isFailure: Bool {
        return !isSuccess
    }

    /// Returns the value if `success`
    /// or throws error if `failure`.
    public func unwrap() throws -> Wrapped {
        switch self {
        case let .success(value): return value
        case let .failure(error): throw error
        }
    }

    /// Construct `success` if the expression returns value
    /// or `failure` if it throws.
    /// - parameter throwingExpr: Closure.
    public init(_ throwingExpr: () throws -> Wrapped) {
        do {
            self = .success(try throwingExpr())
        } catch {
            self = .failure(error)
        }
    }

    /// Convert value if `success`.
    public func map<T>(_ transform: (Wrapped) throws -> T) -> Result<T> {
        switch self {
        case let .success(value): return Result<T> { try transform(value) }
        case let .failure(error): return .failure(error)
        }
    }
}

extension Result: CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String {
        switch self  {
        case .success: return "success"
        case .failure: return "failure"
        }
    }

    public var debugDescription: String {
        switch self {
        case let .success(value): return "success: \(value)"
        case let .failure(error): return "failure: \(error))"
        }
    }
}

/// Contains Void value.
public typealias NoResult = Result<Void>

extension Result where Wrapped == Void {
    public static var success: Result {
        return .success(Void())
    }
}

extension Result {

    @available(*, deprecated, renamed: "ignoredValue")
    public func ignoredResult() -> NoResult {
        return map { _ in }
    }

    /// Returns `NoResult`.
    public var ignoredValue: NoResult {
        return map { _ in }
    }
}
