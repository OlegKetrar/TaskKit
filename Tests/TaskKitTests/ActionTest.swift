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

    /// Alaways success.
    private var successAction = NoResultAction { (finish) in
        DispatchQueue.main.async { finish(.success) }
    }

    /// Alaways failure.
    private var failureAction = NoResultAction { (finish) in
        DispatchQueue.main.async { finish(.failure(EmptyError())) }
    }

    /// converts String to Int.
    private let lazyAction = LazyAction<String, Int> { (input, finish) in
        DispatchQueue.main.async {
            finish(Result<Int> {
                guard let value = Int(input) else { throw EmptyError() }
                return value
            })
        }
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
        let convertedSuccessExp = expectation(description: "convertedSuccess")
        let convertedFailureExp = expectation(description: "convertedFailure")

        successAction
            .always { originalExp.fulfill() } // complete original
            .map { _ in "abc" }
            .onSuccess { XCTAssertEqual($0, "abc") } // complete converted
            .onFailure { _ in XCTFail() }
            .always { convertedSuccessExp.fulfill() }
            .map { (str) -> Int in
                guard let int = Int(str) else { throw EmptyError() }
                return int
            }.onSuccess { _ in XCTFail() }
            .always { convertedFailureExp.fulfill() }
            .execute()

        wait(for: [convertedFailureExp, convertedSuccessExp, originalExp], timeout: 1, enforceOrder: true)
    }

    func testThenLazyActionSuccess() {
        let firstOnSuccessExp  = expectation(description: "firstOnSuccess")
        let firstAlwaysExp     = expectation(description: "firstAlways")
        let secondOnSuccessExp = expectation(description: "secondOnSuccess")
        let secondAlwaysExp    = expectation(description: "secondAlways")
        let wholeOnSuccessExp  = expectation(description: "wholeOnSuccess")
        let wholeAlwaysExp     = expectation(description: "wholeAlways")

        // action
        let first = successAction
            .onSuccess { _ in firstOnSuccessExp.fulfill() }
            .onFailure { _ in XCTFail() }
            .always { firstAlwaysExp.fulfill() }
            .map { _ in "10" }

        // lazy action
        let second = lazyAction
            .onSuccess { _ in secondOnSuccessExp.fulfill() }
            .onFailure { _ in XCTFail() }
            .always { secondAlwaysExp.fulfill() }

        first.then(second)
            .onSuccess { XCTAssertEqual($0, 10); wholeOnSuccessExp.fulfill() }
            .onAny { XCTAssertNotNil($0.value); XCTAssertNil($0.error) }
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

    func testThenLazyActionFailure() {
        let firstOnSuccessExp  = expectation(description: "firstOnSuccess")
        let firstAlwaysExp     = expectation(description: "firstAlways")
        let secondOnFailureExp = expectation(description: "secondOnFailure")
        let secondAlwaysExp    = expectation(description: "secondAlways")
        let wholeOnFailureExp  = expectation(description: "wholeOnFailure")
        let wholeAlwaysExp     = expectation(description: "wholeAlways")

        // action
        let first = successAction
            .onSuccess { _ in firstOnSuccessExp.fulfill() }
            .onFailure { _ in XCTFail() }
            .always { firstAlwaysExp.fulfill() }
            .map { _ in "abcdef" }

        // lazy action
        let second = lazyAction
            .onSuccess { _ in XCTFail() }
            .onFailure { _ in secondOnFailureExp.fulfill() }
            .always { secondAlwaysExp.fulfill() }

        first.then(second)
            .onSuccess { _ in XCTFail() }
            .onFailure { XCTAssertNotNil($0); wholeOnFailureExp.fulfill() }
            .onAny { XCTAssertNil($0.value); XCTAssertNotNil($0.error) }
            .always { wholeAlwaysExp.fulfill() }
            .execute()

        let exp = [
            firstAlwaysExp,
            firstOnSuccessExp,
            secondAlwaysExp,
            secondOnFailureExp,
            wholeAlwaysExp,
            wholeOnFailureExp
        ]

        wait(for: exp, timeout: 1, enforceOrder: true)
    }

    func testThenAction() {
        let firstOnSuccessExp  = expectation(description: "firstOnSuccess")
        let firstAlwaysExp     = expectation(description: "firstAlways")
        let secondOnSuccessExp = expectation(description: "secondOnSuccess")
        let secondAlwaysExp    = expectation(description: "secondAlways")
        let wholeOnSuccessExp  = expectation(description: "wholeOnSuccess")
        let wholeAlwaysExp     = expectation(description: "wholeAlways")

        // action
        let first = successAction
            .onSuccess { _ in firstOnSuccessExp.fulfill() }
            .onFailure { _ in XCTFail() }
            .always { firstAlwaysExp.fulfill() }

        // lazy action
        let second = lazyAction
            .onSuccess { _ in secondOnSuccessExp.fulfill() }
            .onFailure { _ in XCTFail() }
            .always { secondAlwaysExp.fulfill() }
            .with(input: "10")

        first.then(second)
            .onAny { XCTAssertNotNil($0.value); XCTAssertNil($0.error) }
            .onSuccess { XCTAssertEqual($0, 10); wholeOnSuccessExp.fulfill() }
            .onFailure { _ in XCTFail() }
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

    func testRecoverWithValue() {
        let first  = XCTestExpectation()
        let second = XCTestExpectation()

        failureAction
            .onFailure { _ in XCTFail() }
            .onAny { XCTAssertNotNil($0.value); XCTAssertNil($0.error) }
            .always { second.fulfill() }
            .recover(with: ())
            .onAny { XCTAssertNotNil($0.value); XCTAssertNil($0.error); first.fulfill() }
            .onFailure { _ in XCTFail() }
            .execute()

        wait(for: [first, second], timeout: 1, enforceOrder: true)
    }

    func testRecoverWithClosure() {
        let first  = XCTestExpectation()
        let second = XCTestExpectation()
        let third  = XCTestExpectation()

        failureAction
            .onFailure { _ in XCTFail() }
            .onAny { XCTAssertNotNil($0.value); XCTAssertNil($0.error) }
            .always { third.fulfill() }
            .recover { error in
                XCTAssertNotNil(error)
                throw error // can't recover, move error ahead

            }.onAny { XCTAssertNotNil($0.value); XCTAssertNil($0.error); second.fulfill() }
            .onFailure { _ in XCTFail() }
            .recover { error in
                XCTAssertNotNil(error)
                return // recover success

            }.onFailure { _ in XCTFail() }
            .onAny { XCTAssertNotNil($0.value); XCTAssertNil($0.error); first.fulfill() }
            .execute()

        wait(for: [first, second, third], timeout: 1, enforceOrder: true)
    }
}
