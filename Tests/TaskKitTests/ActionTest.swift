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

		waitForExpectations(timeout: 1) {
			XCTAssertNil($0, $0.debugDescription)
		}
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

		waitForExpectations(timeout: 1) {
			XCTAssertNil($0, $0.debugDescription)
		}
	}

	func testInputConvertion() {
		let exp = expectation(description: "onSuccess")

		lazyConvert
			.input { "10" + $0 }
			.input("5")
			.onSuccess { XCTAssertEqual($0, 105); exp.fulfill() }
			.execute()

		waitForExpectations(timeout: 1) {
			XCTAssertNil($0, $0.debugDescription)
		}
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

		waitForExpectations(timeout: 1) {
			XCTAssertNil($0, $0.debugDescription)
		}
	}

	func testFlatMapSuccess() {
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

		waitForExpectations(timeout: 1) {
			XCTAssertNil($0, $0.debugDescription)
		}
	}

	func testFlatMapFailure() {
		let originalExp  = expectation(description: "original")
		let convertedExp = expectation(description: "converted")

		lazyConvert
			.always { originalExp.fulfill() } // complete original
			.flatMap { _ -> NoResult in .failure(EmptyError()) }
			.input("100")
			.onSuccess { _ in XCTFail() } // complete converted
			.onFailure { XCTAssertNotNil($0) }
			.always { convertedExp.fulfill() }
			.execute()

		waitForExpectations(timeout: 1) {
			XCTAssertNil($0, $0.debugDescription)
		}
	}

	func testThen() {
		let firstExp  = expectation(description: "first")
		let secondExp = expectation(description: "second")
		let wholeExp  = expectation(description: "whole")

		let action = LazyAction<Int, String> { (input, finish) in
			DispatchQueue.main.async {
				finish(.success("\(input)"))
			}
		}

		let first = lazyConvert
			.onSuccess { XCTAssertEqual($0, 100) }
			.onFailure { _ in XCTFail() }
			.always { firstExp.fulfill() }

		let second = action
			.onFailure { _ in XCTFail() }
			.always { secondExp.fulfill() }

		first.then(second)
			.input("100")
			.always { wholeExp.fulfill() }
			.onAny { XCTAssertNotNil($0.value); XCTAssertEqual($0.value!, "100") }
			.execute()

		waitForExpectations(timeout: 1) {
			XCTAssertNil($0, $0.debugDescription)
		}
	}
}
