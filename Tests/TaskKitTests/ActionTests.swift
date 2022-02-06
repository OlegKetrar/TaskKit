//
//  ActionTests.swift
//  TaskKit
//
//  Created by Oleg Ketrar on 19.09.17.
//  Copyright © 2017 Oleg Ketrar. All rights reserved.
//

import XCTest
import TaskKit

struct ConvertionError: Error {}
struct NonRecoverError: Error {}

class ActionTests: XCTestCase {

    func testOnSuccess() {
        let successExp = expectation(description: "completion")
        let anyExp = expectation(description: "onAny")
        let alwaysExp = expectation(description: "always")

        convertAsync("100")
            .onFailure { _ in XCTFail() }
            .onSuccess {
                XCTAssertEqual($0, 100)
                successExp.fulfill()
            }
            .onAny {
                XCTAssertEqual($0.value, 100)
                XCTAssertNil($0.error)
                anyExp.fulfill()
            }
            .always {
                alwaysExp.fulfill()
            }
            .execute()

        wait(
            for: [successExp, anyExp, alwaysExp],
            timeout: 1,
            enforceOrder: true)
    }

    func testOnFailure() {
        let failureExp = expectation(description: "onFailure")
        let anyExp = expectation(description: "onAny")
        let alwaysExp = expectation(description: "always")

        convertAsync("abc")
            .onSuccess { _ in XCTFail() }
            .onFailure {
                XCTAssertNotNil($0)
                failureExp.fulfill()
            }
            .onAny {
                XCTAssertNotNil($0.error)
                XCTAssertNil($0.value)
                anyExp.fulfill()
            }
            .always {
                alwaysExp.fulfill()
            }
            .execute()

        wait(
            for: [failureExp, anyExp, alwaysExp],
            timeout: 1,
            enforceOrder: true)
    }

    func testMap() {
        let originalExp = expectation(description: "original")
        let convertedExp = expectation(description: "converted")

        convertAsync("100")
            .always { originalExp.fulfill() } // complete original
            .map { $0 + 10 }
            .onSuccess { XCTAssertEqual($0, 110) } // complete converted
            .onFailure { _ in XCTFail() }
            .always { convertedExp.fulfill() }
            .execute()

        wait(for: [convertedExp, originalExp], timeout: 1, enforceOrder: true)
    }

    func testThen() {
        let firstOnSuccessExp  = expectation(description: "firstOnSuccess")
        let firstAlwaysExp = expectation(description: "firstAlways")
        let secondOnSuccessExp = expectation(description: "secondOnSuccess")
        let secondAlwaysExp = expectation(description: "secondAlways")
        let wholeOnSuccessExp = expectation(description: "wholeOnSuccess")
        let wholeAlwaysExp = expectation(description: "wholeAlways")

        convertAsync("100")
            .onSuccess { _ in firstOnSuccessExp.fulfill() }
            .onFailure { _ in XCTFail() }
            .always { firstAlwaysExp.fulfill() }
            .then { value in
                convertAsync("\(value)")
                    .map { "\($0)" }
                    .onSuccess { _ in secondOnSuccessExp.fulfill() }
                    .onFailure { _ in XCTFail() }
                    .always { secondAlwaysExp.fulfill() }
            }
            .onSuccess {
                XCTAssertEqual($0, "100")
                wholeOnSuccessExp.fulfill()
            }
            .onAny {
                XCTAssertNotNil($0.value)
                XCTAssertEqual($0.value!, "100")
            }
            .always { wholeAlwaysExp.fulfill() }
            .execute()

        let exp = [
            firstOnSuccessExp,
            firstAlwaysExp,
            secondOnSuccessExp,
            secondAlwaysExp,
            wholeOnSuccessExp,
            wholeAlwaysExp
        ]

        wait(for: exp, timeout: 1, enforceOrder: true)
    }

    func testThenLazy() {
        let firstFinished = expectation(description: "firstFinished")
        let secondCreated = expectation(description: "secondCreated")
        let secondFinished = expectation(description: "secondFinished")

        var sharedCounter: Int = 0

        let first = Action<Void> { sharedCounter = 2; $0(.success) }
            .onSuccess { firstFinished.fulfill() }

        func makeSecondAction(with value: Int) -> Action<Int> {
            secondCreated.fulfill()

            return Action<Int> { ending in
                ending(.success(value))
            }
        }

        first
            .then {
                makeSecondAction(with: sharedCounter).onSuccess {
                    secondFinished.fulfill()
                    XCTAssertEqual($0, 2)
                }
            }
            .execute()

        wait(
            for: [firstFinished, secondCreated, secondFinished],
            timeout: 1,
            enforceOrder: true)
    }

    func testRecoverWithValue() {
        let first  = XCTestExpectation()
        let second = XCTestExpectation()

        convertAsync("asbdf")
            .onSuccess { XCTAssertEqual($0, 10) }
            .onFailure { _ in XCTFail() }
            .onAny {
                XCTAssertNotNil($0.value)
                XCTAssertNil($0.error)
            }
            .always {
                first.fulfill()
            }
            .recover(with: 10)
            .onSuccess {
                XCTAssertEqual($0, 10)
            }
            .onAny {
                XCTAssertNotNil($0.value)
                XCTAssertNil($0.error)
                second.fulfill()
            }
            .onFailure { _ in XCTFail() }
            .execute()

        wait(for: [first, second], timeout: 1, enforceOrder: true)
    }

    func testRecoverWithValueOnError() {

        let exp = XCTestExpectation()

        // expect fail, but recovered with `15`
        convertAsync("abc")
            .recover(on: NonRecoverError.self, with: 20)
            .recover(on: ConvertionError.self, with: 15)
            .onSuccess { XCTAssertEqual($0, 15) }
            .onFailure { _ in XCTFail() }
            .onError(of: ConvertionError.self, { _ in XCTFail() })
            .ignoredOutput()

            // expect success with `10`
            .then { convertAsync("10") }
            .recover(on: NonRecoverError.self, with: 20)
            .onSuccess { XCTAssertEqual($0, 10) }
            .onFailure { _ in XCTFail() }
            .ignoredOutput()

            // expect fail, non-recovered
            .then { convertAsync("aa") }
            .recover(on: NonRecoverError.self, with: 10)
            .onSuccess { _ in XCTFail() }
            .onFailure { XCTAssertTrue($0 is ConvertionError) }
            .onError(of: ConvertionError.self) { _ in exp.fulfill() }
            .onError(of: NonRecoverError.self) { _ in XCTFail() }
            .execute()

        wait(for: [exp], timeout: 1)
    }

    func testRecoverWithClosure() {
        let first = XCTestExpectation()
        let second = XCTestExpectation()
        let third = XCTestExpectation()

        convertAsync("asdagg")
            .onSuccess { XCTAssertEqual($0, 5) }
            .onFailure { _ in XCTFail() }
            .onAny { XCTAssertNotNil($0.value); XCTAssertNil($0.error) }
            .always { first.fulfill() }
            .recover { error in
                XCTAssertNotNil(error)
                throw error // can't recover, move error ahead
            }
            .onAny {
                XCTAssertNotNil($0.value)
                XCTAssertNil($0.error)
                second.fulfill()
            }
            .onFailure { _ in XCTFail() }
            .onSuccess { XCTAssertEqual($0, 5) }
            .recover { error in
                XCTAssertNotNil(error)
                return 5 // recover success
            }
            .onFailure { _ in XCTFail() }
            .onSuccess { XCTAssertEqual($0, 5) }
            .onAny {
                XCTAssertNotNil($0.value)
                XCTAssertNil($0.error)
                third.fulfill()
            }
            .execute()

        wait(for: [first, second, third], timeout: 1, enforceOrder: true)
    }

    func testRecoverWithClosureOnError() {

        let exp = XCTestExpectation()

        // expect fail, but recovered with `15`
        convertAsync("abc")
            .recover(on: NonRecoverError.self) { XCTFail(); throw $0 }
            .recover(on: ConvertionError.self) { _ in 15 }
            .onSuccess { XCTAssertEqual($0, 15) }
            .onFailure { _ in XCTFail() }
            .onError(of: ConvertionError.self, { _ in XCTFail() })
            .ignoredOutput()

            // expect success with `10`
            .then { convertAsync("10") }
            .recover(on: NonRecoverError.self) { _ in XCTFail(); return 20 }
            .onSuccess { XCTAssertEqual($0, 10) }
            .onFailure { _ in XCTFail() }
            .ignoredOutput()

            // expect fail, non-recovered
            .then { convertAsync("aa") }
            .recover(on: NonRecoverError.self) { _ in XCTFail(); return 10 }
            .onSuccess { _ in XCTFail() }
            .onFailure { XCTAssertTrue($0 is ConvertionError) }
            .onError(of: ConvertionError.self) { _ in exp.fulfill() }
            .onError(of: NonRecoverError.self) { _ in XCTFail() }
            .execute()
    }

    func testSync() {
        let first  = XCTestExpectation()
        let second = XCTestExpectation()

        Action.sync { "abc" }
            .onSuccess { XCTAssertEqual($0, "abc") }
            .onFailure { _ in XCTFail() }
            .always { first.fulfill() }
            .then { str in convertSync(str).onSuccess { _ in XCTFail() } }
            .onSuccess { _ in XCTFail() }
            .onFailure { XCTAssertTrue($0 is ConvertionError) }
            .always { second.fulfill() }
            .execute()

        wait(for: [first, second], timeout: 1, enforceOrder: true)
    }

    func testValue() {

        let exp = XCTestExpectation()
        var rawInt = 10

        // lazy view on rawInt
        var lazyInt: Int {
            return rawInt
        }

        Action<Int>.value(10)
            .onSuccess { XCTAssert($0 == 10) }
            .onFailure { _ in XCTFail() }
            .map { XCTAssert($0 == 10) }
            .map { rawInt = 15 } // changing int before start lazy action
            .then { Action<Int>.value(lazyInt) }
            .onSuccess { XCTAssert($0 == 15) }
            .always { exp.fulfill() }
            .execute()

        wait(for: [exp], timeout: 0.5)
    }

    /// `then()` should create action at the moment of actual execution.
    func test_then_laziness() {
        var isChanged: Bool = false

        let action = SuccessTask.nothing
            .then { SuccessTask<Bool>.value(isChanged) }
            .onSuccess { XCTAssertTrue($0) }

        isChanged.toggle()

        action.run()
    }

    func testAsyncAwait() {
        let exp = XCTestExpectation()

        Action<Int>
            .async {
                let strValue = try Action.sync { "10" }.await()
                let intValue = try convertSync(strValue).await()

                return intValue
            }
            .onSuccess { XCTAssertEqual($0, 10) }
            .onFailure { _ in XCTFail() }
            .always { exp.fulfill() }
            .execute()

        wait(for: [exp], timeout: 1)
    }

    func testAwaitTimeout() {
        let successExp = XCTestExpectation()
        let failureExp = XCTestExpectation()

        let longAction = Action<Void> { ending in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                ending(.success)
            }
        }

        // should finished successfully
        Action<Void>
            .async { try longAction.await(timeout: 0.5) }
            .onFailure { _ in XCTFail() }
            .always { successExp.fulfill() }
            .execute()

        // should failed with `timedout` error
        Action<Void>
            .async { try longAction.await(timeout: 0.1) }
            .onSuccess { _ in XCTFail() }
            .onFailure { XCTAssertTrue( $0 is TimeoutError) }
            .always { failureExp.fulfill() }
            .execute()

        wait(for: [successExp, failureExp], timeout: 1)
    }
}

/// Takes `String` and tries to convert to `Int`.
/// Throws `ConvertionError` if can't convertation failed.
private func convertAsync(_ str: String) -> Action<Int> {
    .async(on: .main) {
        guard let int = Int(str) else { throw ConvertionError() }
        return int
    }
}

/// Takes `String` and tries to convert to `Int`.
/// Throws `ConvertionError` if can't convertation failed.
private func convertSync(_ str: String) -> Action<Int> {
    .sync {
        guard let int = Int(str) else { throw ConvertionError() }
        return int
    }
}
