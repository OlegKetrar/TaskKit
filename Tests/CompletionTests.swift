//
//  MockError.swift
//  TaskKit
//
//  Created by Oleg Ketrar on 04.07.26.
//  Copyright © 2026 Oleg Ketrar. All rights reserved.
//

import Testing
import TaskKit

@Suite struct CompletionTests {

    // MARK: - onAny / always

    @Test func onAny_calledOnSuccessAndFailure() {
        var calls = 0
        Action<Int>.sync { 1 }.onAny { _ in calls += 1 }.execute()
        Action<Int>.sync { throw MockError() }.onAny { _ in calls += 1 }.execute()
        #expect(calls == 2)
    }

    @Test func always_calledOnSuccessAndFailure() {
        var calls = 0
        Action<Int>.sync { 1 }.always { calls += 1 }.execute()
        Action<Int>.sync { throw MockError() }.always { calls += 1 }.execute()
        #expect(calls == 2)
    }

    // MARK: - onSuccess / onFailure

    @Test func onSuccess_onlyOnSuccess() {
        var value: Int?
        var calls = 0
        Action<Int>.sync { 5 }.onSuccess { value = $0; calls += 1 }.execute()
        Action<Int>.sync { throw MockError() }.onSuccess { _ in calls += 1 }.execute()
        #expect(value == 5)
        #expect(calls == 1)
    }

    @Test func onFailure_onlyOnFailure() {
        var calls = 0
        Action<Int>.sync { 5 }.onFailure { _ in calls += 1 }.execute()
        Action<Int>.sync { throw MockError() }.onFailure { _ in calls += 1 }.execute()
        #expect(calls == 1)
    }

    // MARK: - onError

    @Test func onError_matchesType() {
        var calls = 0
        Action<Int>.sync { throw MockError() }
            .onError(MockError.self) { _ in calls += 1 }
            .execute()

        #expect(calls == 1)
    }

    @Test func onError_ignoresOtherType() {
        struct E2: Swift.Error {}

        var calls = 0
        Action<Int>.sync { throw E2() }
            .onError(MockError.self) { _ in calls += 1 }
            .execute()

        #expect(calls == 0)
    }

    // MARK: - ordering

    @Test func completions_runInFIFOOrder() {
        var order: [Int] = []
        Action<Int>.sync { 1 }
            .onAny { _ in order.append(1) }
            .onAny { _ in order.append(2) }
            .onAny { _ in order.append(3) }
            .execute()
        #expect(order == [1, 2, 3])
    }
}
