//
//  LazyAction.swift
//  TaskKit
//
//  Created by Oleg Ketrar on 17.07.17.
//  Copyright © 2017 Oleg Ketrar. All rights reserved.
//

import Foundation

/// LazyAction with result type Void.
public typealias NoResultLazyAction<T> = LazyAction<T, Void>

/// Abstract Action without input data.
public struct LazyAction<Input, Output>: CompletableAction {
	let work: (Input, @escaping (Result<Output>) -> Void) -> Void
	public var finish: (Result<Output>) -> Void = { _ in }

	public init(_ closure: @escaping (Input, @escaping (Result<Output>) -> Void) -> Void) {
		work = closure
	}

	public func input(_ input: Input) -> Action<Output> {
		return Action { (finish) in self.work(input, finish) }.onAny(finish)
	}

	public func input<T>(_ convert: @escaping (T) -> Input) -> LazyAction<T, Output> {
		let oldWork = work

		var action    = LazyAction<T, Output> { oldWork(convert($0), $1) }
		action.finish = finish

		return action
	}
}

extension LazyAction {

	/// Map.
	public func map<T>(_ closure: @escaping (Output) -> T) -> LazyAction<Input, T> {
		let oldWork   = work
		let oldFinish = finish

		return LazyAction<Input, T> { (input, finish) in
			oldWork(input) {
				oldFinish($0)
				finish($0.map(closure))
			}
		}
	}

	/// FlatMap.
	public func flatMap<T>(_ closure: @escaping (Output) -> Result<T>) -> LazyAction<Input, T> {
		let oldWork   = work
		let oldFinish = finish

		return LazyAction<Input, T> { (input, finish) in
			oldWork(input) {
				oldFinish($0)
				finish($0.flatMap(closure))
			}
		}
	}

	/// Create sequence with action.
	/// Completions of Action sequence will be called by FIFO rule (queue).
	public func then<T>(_ action: LazyAction<Output, T>) -> LazyAction<Input, T> {
		var newAction = LazyAction<Input, T> { (input, onCompletion) in
			self.work(input, {

				// finish first action
				self.finish($0)

				// start second task if success else finish
				switch $0 {
				case let .success(value): action.work(value, onCompletion)
				case let .failure(error): onCompletion(.failure(error))
				}
			})
		}

		newAction.finish = action.finish
		return newAction
	}

	/// Ignore Action result.
	public func ignoreResult() -> NoResultLazyAction<Input> {
		return map { _ in Void() }
	}
}
