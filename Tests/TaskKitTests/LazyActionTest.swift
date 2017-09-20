//
//  LazyActionTest.swift
//  TaskKit
//
//  Created by Oleg Ketrar on 19.09.17.
//  Copyright © 2017 Oleg Ketrar. All rights reserved.
//

import XCTest
@testable import TaskKit

struct EmptyError: Error {}

final class LazyActionTest: XCTestCase {
    private var lazyConvert: LazyAction<String, Int> {
        return LazyAction { (input, finish) in
            DispatchQueue.main.async {
                finish(Result<Int> {
                    guard let int = Int(input) else { throw EmptyError() }
                    return int
                })
            }
        }
    }

    func testOnSuccess() {
        let successExp = expectation(description: "completion")
        let anyExp     = expectation(description: "onAny")
        let alwaysExp  = expectation(description: "always")

        lazyConvert
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
            }.execute(with: "100")

        wait(for: [alwaysExp, anyExp, successExp], timeout: 1, enforceOrder: true)
    }

    func testOnFailure() {
        let failureExp = expectation(description: "onFailure")
        let anyExp     = expectation(description: "onAny")
        let alwaysExp  = expectation(description: "always")

        lazyConvert
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
            }.execute(with: "abc")

        wait(for: [alwaysExp, anyExp, failureExp], timeout: 1, enforceOrder: true)
    }

    func testMapInput() {
        let onSuccessExp = expectation(description: "onSuccess")
        let onAnyExp     = expectation(description: "onAny")
        let alwaysExp    = expectation(description: "always")

        lazyConvert // str -> int
            .always { alwaysExp.fulfill() }
            .mapInput { String("\($0)") }
            .onAny { _ in onAnyExp.fulfill() }
            .mapInput { (str: String) -> Int in
                guard let int = Int(str) else { throw EmptyError() }
                return int
            }.onSuccess { XCTAssertEqual($0, 10); onSuccessExp.fulfill() }
            .execute(with: "10")

        wait(for: [onSuccessExp, onAnyExp, alwaysExp], timeout: 1, enforceOrder: true)
    }

    func testMap() {
        let originalExp  = expectation(description: "original")
        let convertedExp = expectation(description: "converted")

        lazyConvert
            .always { originalExp.fulfill() } // complete original
            .map { $0 + 10 }
            .onSuccess { XCTAssertEqual($0, 110) } // complete converted
            .onFailure { _ in XCTFail() }
            .always { convertedExp.fulfill() }
            .execute(with: "100")

        wait(for: [convertedExp, originalExp], timeout: 1, enforceOrder: true)
    }

    func testThen() {
        let firstOnSuccessExp  = expectation(description: "firstOnSuccess")
        let firstAlwaysExp     = expectation(description: "firstAlways")
        let secondOnSuccessExp = expectation(description: "secondOnSuccess")
        let secondAlwaysExp    = expectation(description: "secondAlways")
        let wholeOnSuccessExp  = expectation(description: "wholeOnSuccess")
        let wholeAlwaysExp     = expectation(description: "wholeAlways")

        let first = lazyConvert
            .onSuccess { _ in firstOnSuccessExp.fulfill() }
            .onFailure { _ in XCTFail() }
            .always { firstAlwaysExp.fulfill() }

        let second = lazyConvert
            .mapInput { (int: Int) -> String in "\(int)" }
            .map { (int) -> String in "\(int)" }
            .onSuccess { _ in secondOnSuccessExp.fulfill() }
            .onFailure { _ in XCTFail() }
            .always { secondAlwaysExp.fulfill() }

        first.then(second)
            .onSuccess { XCTAssertEqual($0, "100"); wholeOnSuccessExp.fulfill() }
            .onAny { XCTAssertNotNil($0.value); XCTAssertEqual($0.value!, "100") }
            .always { wholeAlwaysExp.fulfill() }
            .execute(with: "100")

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
        ("testThen", testThen),
        ("testMapInput", testMapInput)
    ]
}
