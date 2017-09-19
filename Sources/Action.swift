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

	public init(_ closure: @escaping (@escaping (Result<Output>) -> Void) -> Void) {
		work = closure
	}

    /// Start action.
    public func execute() {
        work(finish)
    }
}

extension Action {

	/// Lightweight `then` where result always success.
	/// Does not compose action, just transform output.
	public func map<T>(_ closure: @escaping (Output) -> T) -> Action<T> {
		return Action<T> { (finish) in
			self.work {
				finish($0.map(closure))
				self.finish($0)
			}
		}
	}

	/// Lightweight `then` where result can be success/failure.
	/// Does not compose action, just transform output.
	public func flatMap<T>(_ closure: @escaping (Output) throws -> T) -> Action<T> {
        return Action<T> { (finish) in
            self.work {
                finish($0.flatMap(closure))
                self.finish($0)
            }
        }
	}

	/// Create sequence with action.
	/// Actions will be executed by FIFO rule (queue).
	public func then<T>(_ action: LazyAction<Output, T>) -> Action<T> {
		return Action<T> { (onCompletion) in
			self.work {

				// finish first action
				self.finish($0)

				if let secondInput = $0.value {

					// start second action
					action.work(secondInput) {

						// finish second action and whole action
						action.finish($0)
						onCompletion($0)
					}

				} else {
					let firstResult = Result<T>.failure($0.error!)

					// finish second action and whole action
					action.finish(firstResult)
					onCompletion(firstResult)
				}
			}
		}
	}

    /// Ignore Action output.
    public func ignoredOutput() -> NoResultAction {
        return map { _ in }
    }
}
