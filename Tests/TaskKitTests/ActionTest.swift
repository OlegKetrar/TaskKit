//
//  ActionTest.swift
//  TaskKit
//
//  Created by Oleg Ketrar on 17.07.17.
//  Copyright © 2017 Oleg Ketrar. All rights reserved.
//

import XCTest
@testable import TaskKit

final class ActionTest: XCTestCase {

	var successAction = NoResultAction { (finish) in
        DispatchQueue.main.async { finish(.success) }
	}

    var failureAction = NoResultAction { (finish) in
        DispatchQueue.main.async { finish(.failure(EmptyError())) }
    }

	func testOnSuccess() {
		let successExp = expectation(description: "completion")
		let anyExp     = expectation(description: "onAny")
		let alwaysExp  = expectation(description: "always")

		successAction
			.onFailure { _ in XCTFail() }
			.onSuccess { successExp.fulfill() }
            .onAny {
				XCTAssertNil($0.error)
				anyExp.fulfill()
			}.always {
				alwaysExp.fulfill()
            }.execute()

		wait(for: [alwaysExp, anyExp, successExp], timeout: 1, enforceOrder: true)
	}

	func testOnFailure() {
		let failureExp = expectation(description: "onFailure")
		let anyExp     = expectation(description: "onAny")
		let alwaysExp  = expectation(description: "always")

		failureAction
			.onSuccess { XCTFail() }
			.onFailure {
				XCTAssertNotNil($0)
				failureExp.fulfill()
			}.onAny {
				XCTAssertNotNil($0.error)
				anyExp.fulfill()
			}.always {
				alwaysExp.fulfill()
			}.execute()

		wait(for: [alwaysExp, anyExp, failureExp], timeout: 1, enforceOrder: true)
	}

	func testMap() {
		let originalExp  = expectation(description: "original")
		let convertedExp = expectation(description: "converted")

		successAction
			.always { originalExp.fulfill() } // complete original
			.map { _ in 10 }
			.onSuccess { XCTAssertEqual($0, 10) } // complete converted
			.always { convertedExp.fulfill() }
            .execute()

		wait(for: [convertedExp, originalExp], timeout: 1, enforceOrder: true)
	}

	func testFlatMap() {
		let originalExp  = expectation(description: "original")
		let convertedSuccessExp = expectation(description: "convertedSuccess")
        let convertedFailureExp = expectation(description: "convertedFailure")

		successAction
			.always { originalExp.fulfill() } // complete original
			.flatMap { _ in "abc" }
			.onSuccess { XCTAssertEqual($0, "abc") } // complete converted
			.onFailure { _ in XCTFail() }
			.always { convertedSuccessExp.fulfill() }
            .flatMap { (input) -> Int in
                guard input.isEmpty else { throw EmptyError() }
                return 10
            }.onSuccess { _ in XCTFail() }
            .always { convertedFailureExp.fulfill() }
            .execute()

		wait(for: [convertedFailureExp, convertedSuccessExp, originalExp], timeout: 1, enforceOrder: true)
	}

	func testThen() {
		let firstOnSuccessExp  = expectation(description: "firstOnSuccess")
		let firstAlwaysExp     = expectation(description: "firstAlways")
		let secondOnSuccessExp = expectation(description: "secondOnSuccess")
		let secondAlwaysExp    = expectation(description: "secondAlways")
		let wholeOnSuccessExp  = expectation(description: "wholeOnSuccess")
		let wholeAlwaysExp     = expectation(description: "wholeAlways")

		let action = LazyAction<Int, String> { (input, finish) in
			DispatchQueue.main.async { finish(.success("\(input)")) }
		}

		// action
		let first = successAction
			.onSuccess { _ in firstOnSuccessExp.fulfill() }
			.onFailure { _ in XCTFail() }
			.always { firstAlwaysExp.fulfill() }
            .map { _ in 10 }

		// lazy action
		let second = action
			.onSuccess { _ in secondOnSuccessExp.fulfill() }
			.onFailure { _ in XCTFail() }
			.always { secondAlwaysExp.fulfill() }

		first.then(second)
			.onSuccess { XCTAssertEqual($0, "10"); wholeOnSuccessExp.fulfill() }
			.onAny { XCTAssertNotNil($0.value); XCTAssertEqual($0.value!, "10") }
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

    static var allTests = [
        ("testOnSuccess", testOnSuccess),
        ("testOnFailure", testOnFailure),
        ("testMap", testMap),
        ("testFlatMap", testFlatMap),
        ("testThen", testThen)
    ]
}
