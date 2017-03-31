//
//  TaskKitTests.swift
//  TaskKitTests
//
//  Created by Oleg Ketrar on 31.03.17.
//  Copyright © 2017 Oleg Ketrar. All rights reserved.
//

import XCTest
@testable import TaskKit

class TaskKitTests: XCTestCase {
    func testThen() {
        let firstExp  = expectation(description: "t -> t")

        /*
        let secondExp = expectation(description: "t -> ft")
        let thirdExp  = expectation(description: "ft -> t")
        let fourthExp = expectation(description: "ft -> ft")
        */

        /// t -> t
        Input(now: "10")
            .convert { Int($0) }
            .then { XCTAssertEqual($0, 10) }
            .execute { XCTAssertEqual($0, 10); firstExp.fulfill() }

        /*
        /// t -> ft
        Input(now: 10).then(Send()).then { (result) in
            if case let .success(json) = result {
                XCTAssertEqual(json.value, "a")
            } else {
                XCTFail()
            }
        }.catch {
            XCTAssertNil($0)
        }.execute { (json) in
            XCTAssertEqual(json.value, "a")
            secondExp.fulfill()
        }

        /// ft -> t
        Send<Int>().then(Parse()).then { (result) in
            if case let .success(int) = result {
                XCTAssertEqual(int, 10)
            } else {
                XCTFail()
            }
        }.catch {
            XCTAssertNil($0)
        }.execute(10) { (int) in
            XCTAssertEqual(int, 10)
            thirdExp.fulfill()
        }

        /// ft -> ft
        Send<Int>().then(OptinalParse()).then { (result) in
            if case let .success(int) = result {
                XCTAssertEqual(int, 10)
            } else {
                XCTFail()
            }
        }.catch {
            XCTAssertNil($0)
        }.execute(10) { (int) in
            XCTAssertEqual(int, 10)
            fourthExp.fulfill()
        }
 
        */

        ///

        waitForExpectations(timeout: 1) { (error) in
            XCTAssertNil(error, error.debugDescription)
        }
    }

    // MARK: - Input, Task.then(closure:)

    func testInput() {
        Input(now: "My Name")
            .convert { $0 + " is Oleg" }
            .execute { XCTAssertEqual("My Name is Oleg", $0) }
    }

    func testLazyInput() {
        class PersonMock {
            var isNameCreated: Bool = false
            var lazyName: String {
                isNameCreated = true
                return "Oleg"
            }
        }

        let person = PersonMock()
        let input  = Input(lazy: person.lazyName).convert { "name is \($0)" }

        // check lazy
        XCTAssertFalse(person.isNameCreated)

        input.execute { _ in
            XCTAssertTrue(person.isNameCreated)
        }
    }

    func testCompletion() {
        let completionExp = expectation(description: "completion")

        Input(now: "12").convert { Int($0) }.execute { (result) in
            if case let .success(integer) = result {
                XCTAssertEqual(integer, 12)
            } else {
                XCTFail()
            }

            completionExp.fulfill()
        }

        waitForExpectations(timeout: 1) { (error) in
            XCTAssertNil(error, error.debugDescription)
        }
    }

    // MARK: - Convert

    func testConvertTask() {
        Input(now: "12")
            .convert { $0 + "34" }
            .convert { Int($0) }
            .execute {
                if case let .success(integer) = $0 {
                    XCTAssertEqual(integer, 1234)
                } else {
                    XCTFail()
                }
        }
    }

    func testConvertEachTask() {
        Input(now: ["1", "2", "3"])
            .map { $0 + "1" }
            .flatMap { Int($0) }
            .convert { (array: [Int]) -> Int in array.reduce(0, +) }
            .execute { (sum: Int) in
                XCTAssertEqual(sum, 11 + 21 + 31)
        }
    }

    // MAKR: - Execution Conveniences

    func testOnSuccess() {
        let successExp = expectation(description: "successExp")

        Input(now: "12")
            .convert { Int($0) }
            .ignoreFailure()
            .execute { XCTAssertEqual($0, 12); successExp.fulfill() }

        waitForExpectations(timeout: 1) { (error) in
            XCTAssertNil(error)
        }
    }

    func testCatchingError() {
        let errorExp = expectation(description: "errorCatching")

        Input(now: "Str")
            .convert { Int($0) }
            .catch { XCTAssertNil($0); errorExp.fulfill() }
            .execute { _ in XCTFail() }

        waitForExpectations(timeout: 1) { (error) in
            XCTAssertNil(error)
        }
    }

    // MARK: - Awaiting

    func testTaskAwaiting() {
        let asyncExpectation = expectation(description: "awaiting")

        let first = Input(now: "1").convert { $0 + "2" }
        let second = Input(now: "2").convert { $0 + "1" }

        first.split(with: second)
            .union()
            .convert { $0.0 + " > " + $0.1 }
            .execute {
                asyncExpectation.fulfill()
                XCTAssertEqual($0, "12 > 21")
        }

        waitForExpectations(timeout: 1) { (error) in
            XCTAssertNil(error, error.debugDescription)
        }
    }

    func testTaskAndFailableTaskAwaiting() {
        let asyncExpectation = expectation(description: "awaiting")

        let first = Input(now: 10).convert { $0 + 2 }
        let second = Input(now: "2").convert { $0 + "1" }.convert { Int($0) }

        first.split(with: second)
            .union()
            .convert { $0.0 + $0.1 }
            .execute { (result) in
                if case let .success(value) = result {
                    XCTAssertEqual(value, 12 + 21)
                } else {
                    XCTFail()
                }

                asyncExpectation.fulfill()
        }

        waitForExpectations(timeout: 1) { (error) in
            XCTAssertNil(error, error.debugDescription)
        }
    }

    func testFailableTaskAndTaskAwaiting() {
        let asyncExpectation = expectation(description: "awaiting")

        let first = Input(now: "2").convert { $0 + "1" }.convert { Int($0) }
        let second = Input(now: 10).convert { $0 + 2 }

        first.split(with: second)
            .union()
            .convert { $0.0 + $0.1 }
            .execute { (result) in
                if case let .success(value) = result {
                    XCTAssertEqual(value, 12 + 21)
                } else {
                    XCTFail()
                }

                asyncExpectation.fulfill()
        }

        waitForExpectations(timeout: 1) { (error) in
            XCTAssertNil(error, error.debugDescription)
        }
    }

    func testFailableTaskAwaiting() {
        let asyncExpectation = expectation(description: "awaiting")

        let first = Input(now: "1").convert { $0 + "2" }.convert { Int($0) }
        let second = Input(now: "2").convert { $0 + "1" }.convert { Int($0) }

        first.split(with: second)
            .union()
            .convert { $0.0 + $0.1 }
            .execute { (result) in
                if case let .success(value) = result {
                    XCTAssertEqual(value, 12 + 21)
                } else {
                    XCTFail()
                }
                
                asyncExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 1) { (error) in
            XCTAssertNil(error, error.debugDescription)
        }
    }

    static var allTests = [
        ("testThen", testThen),
        ("testInput", testInput),
        ("testLazyInput", testLazyInput),
        ("testCompletion", testCompletion),
        ("testConvertTask", testConvertTask),
        ("testConvertEachTask", testConvertEachTask),
        ("testTaskAwaiting", testTaskAwaiting),
        ("testTaskAndFailableTaskAwaiting", testTaskAndFailableTaskAwaiting),
        ("testFailableTaskAndTaskAwaiting", testFailableTaskAndTaskAwaiting),
        ("testFailableTaskAwaiting", testFailableTaskAwaiting)
    ]
}
