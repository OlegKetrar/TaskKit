//
//  ActionTest.swift
//  TaskKit
//
//  Created by Oleg Ketrar on 17.07.17.
//  Copyright © 2017 Oleg Ketrar. All rights reserved.
//

import XCTest
@testable import TaskKit

final class TaskKitTests: XCTestCase {
	struct EmptyError: Error {}

	var lazyConvert: LazyAction<String, Int> {
		return LazyAction { (input, finish) in
			DispatchQueue.main.async {
				if let int = Int(input) {
					finish(.success(int))
				} else {
					finish(.failure(EmptyError()))
				}
			}
		}
	}

	func testSuccessCompletion() {
		let successExp = expectation(description: "completion")
		let anyExp     = expectation(description: "onAny")
		let alwaysExp  = expectation(description: "always")

		lazyConvert.input("100")
			.onFailure { _ in XCTFail() }
			.onSuccess {
				XCTAssertEqual($0, 100)
				successExp.fulfill()
			}.onAny {
				XCTAssertEqual($0.value, 100)
				XCTAssertNil($0.error)
				anyExp.fulfill()
			}.always {
				alwaysExp.fulfill()
			}.execute()

		wait(for: [alwaysExp, anyExp, successExp], timeout: 1, enforceOrder: true)
	}

	func testFailureCompletion() {
		let failureExp = expectation(description: "onFailure")
		let anyExp     = expectation(description: "onAny")
		let alwaysExp  = expectation(description: "always")

		lazyConvert.input("abc")
			.onSuccess { _ in XCTFail() }
			.onFailure {
				XCTAssertNotNil($0)
				failureExp.fulfill()
			}.onAny {
				XCTAssertNotNil($0.error)
				XCTAssertNil($0.value)
				anyExp.fulfill()
			}.always {
				alwaysExp.fulfill()
			}.execute()

		wait(for: [alwaysExp, anyExp, failureExp], timeout: 1, enforceOrder: true)
	}

	func testMapInput() {
		let onSuccessExp = expectation(description: "onSuccess")
		let onAnyExp     = expectation(description: "onAny")
		let alwaysExp    = expectation(description: "always")

		lazyConvert // str -> int
			.always { alwaysExp.fulfill() }
			.mapInput { (int: Int) -> String in "\(int)" } // int -> str -> int
			.onAny { _ in onAnyExp.fulfill() }
			.flatMapInput { (str) -> Result<Int> in // str -> int -> str -> int
				if let int = Int(str) {
					return .success(int)
				} else {
					return .failure(EmptyError())
				}
			}.input("10")
			.onSuccess { XCTAssertEqual($0, 10); onSuccessExp.fulfill() }
			.execute()

		wait(for: [onSuccessExp, onAnyExp, alwaysExp], timeout: 1, enforceOrder: true)
	}

	func testMap() {
		let originalExp  = expectation(description: "original")
		let convertedExp = expectation(description: "converted")

		lazyConvert
			.always { originalExp.fulfill() } // complete original
			.map { $0 + 10 }
			.input("100")
			.onSuccess { XCTAssertEqual($0, 110) } // complete converted
			.always { convertedExp.fulfill() }
			.execute()

		wait(for: [convertedExp, originalExp], timeout: 1, enforceOrder: true)
	}

	func testFlatMap() {
		let originalExp  = expectation(description: "original")
		let convertedExp = expectation(description: "converted")

		lazyConvert
			.always { originalExp.fulfill() } // complete original
			.flatMap { .success($0 + 10) }
			.input("100")
			.onSuccess { XCTAssertEqual($0, 110) } // complete converted
			.onFailure { _ in XCTFail() }
			.always { convertedExp.fulfill() }
			.execute()

		wait(for: [convertedExp, originalExp], timeout: 1, enforceOrder: true)
	}

	func testThen() {
		let firstOnSuccessExp  = expectation(description: "firstOnSuccess")
		let firstAlwaysExp     = expectation(description: "firstAlways")
		let secondOnSuccessExp = expectation(description: "secondOnSuccess")
		let secondAlwaysExp    = expectation(description: "secondAlways")
		let wholeOnSuccessExp  = expectation(description: "wholeOnSuccess")
		let wholeAlwaysExp     = expectation(description: "wholeAlways")

		let action = LazyAction<Int, String> { (input, finish) in
			DispatchQueue.main.async {
				finish(.success("\(input)"))
			}
		}

		let first = lazyConvert
			.onSuccess { _ in firstOnSuccessExp.fulfill() }
			.onFailure { _ in XCTFail() }
			.always { firstAlwaysExp.fulfill() }

		let second = action
			.onSuccess { _ in secondOnSuccessExp.fulfill() }
			.onFailure { _ in XCTFail() }
			.always { secondAlwaysExp.fulfill() }

		first.then(second)
			.input("100")
			.onSuccess { XCTAssertEqual($0, "100"); wholeOnSuccessExp.fulfill() }
			.onAny { XCTAssertNotNil($0.value); XCTAssertEqual($0.value!, "100") }
			.always { wholeAlwaysExp.fulfill() }
			.execute()

		let exp = [
			firstAlwaysExp,
			firstOnSuccessExp,
			secondAlwaysExp,
			secondOnSuccessExp,
			wholeAlwaysExp,
			wholeOnSuccessExp
		]

		wait(for: exp, timeout: 1, enforceOrder: true)
	}
}
