//
//  MockError.swift
//  TaskKit
//
//  Created by Oleg Ketrar on 04.07.26.
//  Copyright © 2026 Oleg Ketrar. All rights reserved.
//

import Testing
import TaskKit
import Foundation

// Awaits a callback-based Action off the main thread so the action's
// main-queue completion can be delivered. Uses the library's own blocking
// `await(timeout:)` instead of XCTestExpectation.
private func awaitAction<T>(_ action: Action<T>, timeout: TimeInterval = 5) async throws -> T {
    try await Task.detached { try action.await(timeout: timeout) }.value
}

@Suite struct AsyncTests {

    // MARK: - Action.async

    @Test func async_succeeds() async throws {
        let action = Action<Int>.async(on: .global()) { 42 }
        #expect(try await awaitAction(action) == 42)
    }

    @Test func async_throws_propagates() async {
        let action = Action<Int>.async(on: .global()) { throw MockError() }
        await #expect(throws: MockError.self) {
            try await awaitAction(action)
        }
    }

    // MARK: - await(timeout:)

    @Test func await_timeout_throwsTimeoutError_whenNeverCompletes() {
        let action = Action<Int> { _ in } // never completes
        #expect(throws: TimeoutError.self) {
            try action.await(timeout: 0.05)
        }
    }

    // MARK: - DispatchQueue.asyncValue

    @Test func dispatchQueue_asyncValue_succeeds() async throws {
        let action = DispatchQueue.global().asyncValue { 100 }
        #expect(try await awaitAction(action) == 100)
    }
}
