//
//  ExclusivityTest.swift
//  TaskKitTests
//
//  Created by Oleg Ketrar on 27.11.17.
//  Copyright © 2017 Oleg Ketrar. All rights reserved.
//

import XCTest
import TaskKit

final class ExclusivityTest: XCTestCase {
    private var sharedNumber: Int = 5

    private let sharedQueue = DispatchQueue(
        label: "shared-number-queue",
        qos: .utility)

    private lazy var longAsyncAction = Action<Void> { ending in
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            ending(.success)
        }
    }

    /// Second action should fail by exclusivity.
    func testIgnoreSubsequent() {

        let buffer = ExclusivityBuffer(behaviour: .ignoreSubsequent)
        let firstExp = XCTestExpectation()
        let secondExp = XCTestExpectation()
        var sharedValue = 0

        let first = longAsyncAction
            .wrapped(by: buffer)
            .map { sharedValue = 1 }

        let second = longAsyncAction
            .wrapped(by: buffer)
            .map { sharedValue = 2 }

        first
            .onSuccess { firstExp.fulfill() }
            .execute()

        second
            .onSuccess { XCTFail() }
            .onFailure { XCTAssertTrue( $0 is ExclusivityError ); secondExp.fulfill() }
            .execute()

        wait(for: [firstExp, secondExp], timeout: 1)
        XCTAssertTrue(sharedValue == 1)
    }

    /// First action should fail by exclusivity.
    func testCancelCurrent() {

        let buffer = ExclusivityBuffer(behaviour: .cancelCurrent)
        let firstExp = XCTestExpectation()
        let secondExp = XCTestExpectation()
        var sharedValue = 0

        let first = longAsyncAction
            .wrapped(by: buffer)
            .map { sharedValue = 1 }

        let second = longAsyncAction
            .wrapped(by: buffer)
            .map { sharedValue = 2 }

        first
            .onSuccess { XCTFail() }
            .onFailure { XCTAssertTrue( $0 is ExclusivityError ); firstExp.fulfill() }
            .execute()

        second
            .onSuccess { secondExp.fulfill() }
            .execute()

        wait(for: [firstExp, secondExp], timeout: 1)
        XCTAssertTrue(sharedValue == 2)
    }

    /// Both actions should fail,
    /// first by exclusivity, second by timeout.
    func testExclusivityWithTimeout() {

        let buffer = ExclusivityBuffer(behaviour: .cancelCurrent)
        let by5Exp = XCTestExpectation()
        let by7Exp = XCTestExpectation()

        let longTimeoutedAction = Action<Void>.async {
            try self.longAsyncAction.await(timeout: 0.1)
        }

        // prepare actions
        let multiplyBy5 = longAsyncAction
            .wrapped(by: buffer)
            .map { self.sharedQueue.sync { self.sharedNumber *= 5 } }

        let multiplyBy7 = longTimeoutedAction
            .wrapped(by: buffer)
            .map { self.sharedQueue.sync { self.sharedNumber *= 7 } }

        // set default value
        sharedNumber = 10

        // execute actions
        multiplyBy5
            .onSuccess { XCTFail() }
            .onFailure { XCTAssertTrue($0 is ExclusivityError) }
            .always { by5Exp.fulfill() }
            .execute()

        multiplyBy7
            .onSuccess { XCTFail() }
            .onFailure { XCTAssertTrue($0 is TimeoutError) }
            .always { by7Exp.fulfill() }
            .execute()

        wait(for: [by5Exp, by7Exp], timeout: 1)
        XCTAssertTrue(sharedNumber == 10, "sharedNumber = \(sharedNumber)")
    }
}
