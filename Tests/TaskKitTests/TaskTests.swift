//
//  TaskTests.swift
//  TaskKitTests
//
//  Created by Oleg Ketrar on 06.02.2022.
//

import XCTest
import TaskKit

class TaskTests: XCTestCase {

    func test_run_callsWork() {
        var isWorkCalled: Bool = false

        SuccessTask<Void>
            .init { _ in isWorkCalled = true }
            .run()

        XCTAssertTrue(isWorkCalled)
    }

    func test_run_callsWorkEverytime() {
        var callCount: Int = 0

        let sut = SuccessTask<Void> { ending in
            ending(.success)
            callCount += 1
        }

        sut.run()
        sut.run()

        XCTAssertEqual(callCount, 2)
    }

    func test_sync_SuccessTask_success() {
        SuccessTask<Int>
            .sync { 10 }
            .onAny { XCTAssertEqual($0.value, 10) }
            .run()
    }

    func test_sync_Action_success() {
        Action<Int>
            .sync { 10 }
            .onAny { XCTAssertEqual($0.value, 10) }
            .run()
    }

    func test_sync_Action_failure() {
        Action<Void>
            .sync { throw DummyError() }
            .onFailure { XCTAssertTrue($0 is DummyError) }
            .onSuccess { _ in XCTFail() }
            .run()
    }

    func test_value_SuccessTask() {
        SuccessTask<Int>
            .value(10)
            .onAny { XCTAssertEqual($0.value, 10) }
            .run()
    }

    func test_value_Action_failure() {
        func throwDummyError() throws -> Int {
            throw DummyError()
        }

        Action<Int>
            .value(try throwDummyError())
            .onFailure { XCTAssertTrue($0 is DummyError) }
            .onSuccess { _ in XCTFail() }
            .run()
    }

    func test_value_Action_success() {
        Action<Int>
            .value(10)
            .onAny { XCTAssertEqual($0.value, 10) }
            .run()
    }

    func test_value_Action_autoclosure() {
        var isCalled: Bool = false

        func getInt() -> Int {
            isCalled = true
            return 10
        }

        _ = Action<Int>.value(getInt())

        XCTAssertFalse(isCalled)
    }

    func test_value_SuccessTask_autoclosure() {
        var isCalled: Bool = false

        func getInt() -> Int {
            isCalled = true
            return 10
        }

        _ = SuccessTask<Int>.value(getInt())

        XCTAssertFalse(isCalled)
    }

    func test_nothing_SuccessTask() {
        SuccessTask<Void>
            .nothing
            .onAny { try! XCTUnwrap($0.value) }
            .run()
    }

    func test_nothing_Action() {
        Action<Void>
            .nothing
            .onAny { try! XCTUnwrap($0.value) }
            .run()
    }
}

struct DummyError: Swift.Error, Equatable {}
