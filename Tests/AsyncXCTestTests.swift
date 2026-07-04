//
//  AsyncXCTestTests.swift
//  TaskKitTests
//
//  Created by Oleg Ketrar on 04.07.26.
//  Copyright © 2026 Oleg Ketrar. All rights reserved.
//

import XCTest
import TaskKit

final class AsyncXCTestTests: XCTestCase {

    // MARK: - Action.async

    func test_async_succeeds() {
        let expectation = self.expectation(description: "async succeeds")
        var captured: Int?

        Action<Int>.async(on: .global()) { 42 }
            .onSuccess {
                captured = $0
                expectation.fulfill()
            }
            .execute()

        wait(for: [expectation], timeout: 5)
        XCTAssertEqual(captured, 42)
    }

    func test_async_throws_propagates() {
        let expectation = self.expectation(description: "async throws")
        var captured: Error?

        Action<Int>.async(on: .global()) { throw MockError() }
            .onFailure {
                captured = $0
                expectation.fulfill()
            }
            .execute()

        wait(for: [expectation], timeout: 5)
        XCTAssertNotNil(captured as? MockError)
    }

    // MARK: - await(timeout:)

    func test_await_timeout_throwsTimeoutError_whenNeverCompletes() {
        let action = Action<Int> { _ in } // never completes
        XCTAssertThrowsError(try action.await(timeout: 0.05)) { error in
            XCTAssertNotNil(error as? TimeoutError)
        }
    }

    // MARK: - DispatchQueue.asyncValue

    func test_dispatchQueue_asyncValue_succeeds() {
        let expectation = self.expectation(description: "asyncValue succeeds")
        var captured: Int?

        DispatchQueue.global().asyncValue { 100 }
            .onSuccess {
                captured = $0
                expectation.fulfill()
            }
            .execute()

        wait(for: [expectation], timeout: 5)
        XCTAssertEqual(captured, 100)
    }
}
