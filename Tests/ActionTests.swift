//
//  MockError.swift
//  TaskKit
//
//  Created by Oleg Ketrar on 04.07.26.
//  Copyright © 2026 Oleg Ketrar. All rights reserved.
//

import Testing
import TaskKit

@Suite struct ActionTests {

    @Test func sync_succeeds() {
        var captured: Int?
        Action<Int>.sync { 42 }.execute { captured = $0 }
        #expect(captured == 42)
    }

    @Test func sync_failure_propagates() {
        var captured: Error?
        Action<Int>.sync { throw MockError() }
            .onFailure { captured = $0 }
            .execute()
        #expect(captured is MockError)
    }

    @Test func value_autoclosure_succeeds() {
        var captured: Int?
        Action<Int>.success(99).execute { captured = $0 }
        #expect(captured == 99)
    }

    @Test func failure_propagates() {
        var captured: Error?
        Action<Int>.failure(MockError())
            .onFailure { captured = $0 }
            .execute()
        #expect(captured is MockError)
    }

    @Test func execute_callsCompletion() {
        var calls = 0
        Action<Int>.sync { 1 }.onAny { _ in calls += 1 }.execute()
        #expect(calls == 1)
    }

    // MARK: - execute(successCompletion)

    @Test func execute_successCompletion_calledOnSuccess() {
        var captured: Int?
        Action<Int>.sync { 7 }.execute { captured = $0 }
        #expect(captured == 7)
    }

    @Test func execute_successCompletion_skippedOnFailure() {
        var called = false
        Action<Int>.sync { throw MockError() }.execute { _ in called = true }
        #expect(!called)
    }

    // MARK: - await (sync action)

    @Test func await_sync_returnsValue() throws {
        #expect(try Action<Int>.sync { 13 }.await() == 13)
    }

    @Test func await_sync_throwsOnFailure() {
        #expect(throws: MockError.self) {
            try Action<Int>.sync { throw MockError() }.await()
        }
    }
}
