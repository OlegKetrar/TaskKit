//
//  ResultExtension.swift
//  TaskKit
//
//  Created by Oleg Ketrar on 30.03.17.
//  Copyright © 2017 Oleg Ketrar. All rights reserved.
//

extension Swift.Result {

    /// Returns value if `success`, otherwise `nil`.
    public var value: Success? {
        guard case let .success(value) = self else { return nil }
        return value
    }

    /// Returns error if `failure`, otherwise `nil`.
    public var error: Failure? {
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

    /// Returns `NoResult`.
    public var ignoredValue: Swift.Result<Void, Failure> {
        return map { _ in }
    }
}

extension Swift.Result where Success == Void {

    public static var success: Swift.Result<Void, Failure> {
        return .success(Void())
    }
}

extension Swift.Result where Failure == Swift.Error {

    public func mapThrows<T>(
        _ transform: @escaping (Success) throws -> T
    ) -> Swift.Result<T, Failure> {

        flatMap { value in
            Swift.Result { try transform(value) }
        }
    }
}
