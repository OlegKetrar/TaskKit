//
//  CompletionTests.swift
//  TaskKitTests
//
//  Created by Oleg Ketrar on 06.02.2022.
//

import XCTest
import TaskKit

class CompletionTests: XCTestCase {

    func test_onAnyCall_positive() {
        var callCount: Int = 0

        SuccessTask<Void>
            .init { ending in ending(.success) }
            .onAny { result in callCount += 1 }
            .run()

        XCTAssertEqual(callCount, 1)
    }

    func test_onAnyCall_negative() {
        SuccessTask<Void>
            .init { _ in }
            .onAny { _ in XCTFail() }
            .run()
    }

    func test_onAny_success() {
        var callCount: Int = 0

        SuccessTask<Void>
            .init { ending in ending(.success) }
            .onAny { result in callCount += 1 }
            .run()

        XCTAssertEqual(callCount, 1)
    }

    func test_onAny_failure() {
        Task<Void, DummyError>
            .init { ending in ending(.failure(DummyError())) }
            .onAny { result in XCTAssertTrue(result.isFailure) }
            .run()
    }

    func test_onSuccess() {
        let exp = makeExp("call onSuccess")

        Action<Int>
            .value(10)
            .onSuccess { XCTAssertEqual($0, 10); exp.fulfill() }
            .onFailure { _ in XCTFail() }
            .run()

        assertWaitSyncExp()
    }

    func test_onFailure() {
        let exp = makeExp("call onSuccess")

        Action<Int>
            .value(10)
            .onSuccess { XCTAssertEqual($0, 10); exp.fulfill() }
            .run()

        assertWaitSyncExp()
    }

    func makeExp(_ name: String = "") -> XCTestExpectation {
        expectation(description: name)
    }

    func assertWaitSyncExp() {
        waitForExpectations(timeout: 0, handler: nil)
    }
}
