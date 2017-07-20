//
//  Action.swift
//  TaskKit
//
//  Created by Oleg Ketrar on 17.07.17.
//  Copyright © 2017 Oleg Ketrar. All rights reserved.
//

import Foundation

/// Completion will be called by FILO rule (stack).
public protocol CompletableAction {
	associatedtype CompletionType
	var finish: (Result<CompletionType>) -> Void { get set }
}

extension CompletableAction {

	/// Adds completion closure which will be called if success.
	/// Will be executed by FILO rule (stack) within original action.
	public func onSuccess(_ closure: @escaping (CompletionType) -> Void) -> Self {
		var copy      = self
		let oldFinish = finish

		copy.finish = {
			if let value = $0.value {
				closure(value)
			}

			oldFinish($0)
		}

		return copy
	}

	/// Adds completion closure which will be called if failure.
	/// Will be executed by FILO rule (stack) within original action.
	public func onFailure(_ closure: @escaping (Error) -> Void) -> Self {
		var copy      = self
		let oldFinish = finish

		copy.finish = {
			if let error = $0.error {
				closure(error)
			}

			oldFinish($0)
		}

		return copy
	}

	/// Adds completion closure.
	/// Will be executed by FILO rule (stack) within original action.
	public func onAny(_ closure: @escaping (Result<CompletionType>) -> Void) -> Self {
		var copy = self
		let oldFinish = finish

		copy.finish = {
			closure($0)
			oldFinish($0)
		}

		return copy
	}

	/// Adds completion closure.
	/// Will be executed by FILO rule (stack) within original action.
	public func always(_ closure: @escaping () -> Void) -> Self {
		var copy      = self
		let oldFinish = finish

		copy.finish = {
			closure()
			oldFinish($0)
		}
		
		return copy
	}
}

/// Action with result type Void.
public typealias NoResultAction = Action<Void>

/// Action encapsulate some async work.
public struct Action<Output>: CompletableAction {
	let work: (@escaping (Result<Output>) -> Void) -> Void
	public var finish: (Result<Output>) -> Void = { _ in }

	public var execute: () -> Void {
		return { self.work(self.finish) }
	}

	public init(_ closure: @escaping (@escaping (Result<Output>) -> Void) -> Void) {
		work = closure
	}
}
