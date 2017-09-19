//
//  Task.swift
//  TaskKit
//
//  Created by Oleg Ketrar on 19.09.17.
//  Copyright © 2017 Oleg Ketrar. All rights reserved.
//

import Foundation

/*
final class Promise<T> {
	private var work:   (@escaping (Result<T>) -> Void) -> Void
	private var finish: (Result<T>) -> Void = { _ in }

	private var performOnDealloc: Bool = true

	init(_ closure: @escaping (@escaping (Result<T>) -> Void) -> Void) {
		work = closure
	}

	// MARK: Configure

	@discardableResult
	func always(_ closure: @escaping () -> Void) -> Promise<T> {
		let oldFinish = finish

		finish = {
			closure()
			oldFinish($0)
		}

		return self
	}

	@discardableResult
	func then(_ closure: @escaping (T) -> Void) -> Promise<T> {
		let oldFinish = finish

		finish = {
			if let value = $0.value {
				closure(value)
			}

			oldFinish($0)
		}

		return self
	}

	@discardableResult
	func `catch`(_ closure: @escaping (AppError) -> Void) -> Promise<T> {
		let oldFinish = finish

		finish = {
			if let error = $0.error {
				closure(error)
			}

			oldFinish($0)
		}

		return self
	}

	// MARK: Transform

	func then<V>(_ f: @escaping (T) -> V) -> Promise<V> {
		let oldWork   = work
		let oldFinish = finish

		return Promise<V> { (finish) in
			oldWork {
				finish($0.map(f))
				oldFinish($0)
			}
		}
	}

	func then<V>(_ f: @escaping (T) -> Result<V>) -> Promise<V> {
		let oldWork   = work
		let oldFinish = finish

		return Promise<V> { (finish) in
			oldWork {
				finish($0.flatMap(f))
				oldFinish($0)
			}
		}
	}

	// MARK: Execution

	deinit {
		guard performOnDealloc else { return }
		work(finish)
	}

	func execute() {
		performOnDealloc = false
		work(finish)
	}
}
*/
