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

	/// Return the value if it's a .success or throw the error if it's a .failure.
	public func unwrap() throws -> Wrapped {
		switch self {
		case let .success(value): return value
		case let .failure(error): throw error
		}
	}

	/// Construct a .failure if the expression returns a value or a .failure if it throws.
	public init(_ throwingExpr: () throws -> Wrapped) {
		do {
			self = .success(try throwingExpr())
		} catch {
			self = .failure(error)
		}
	}

	public func map<T>(_ transform: (Wrapped) -> T) -> Result<T> {
		switch self {
		case let .success(value): return .success(transform(value))
		case let .failure(error): return .failure(error)
		}
	}

	public func flatMap<T>(_ transform: (Wrapped) -> Result<T>) -> Result<T> {
		switch self {
		case let .success(value): return transform(value)
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
public typealias NoResult = Result<()>

extension Result where Wrapped == Void {
	public static var emptySuccess: Result {
		return .success(Void())
	}
}

extension Result {

	/// Returns `NoResult`.
	public var ignoredResult: NoResult {
		return map { _ in Void() }
	}
}
