//
//  MockError.swift
//  TaskKit
//
//  Created by Oleg Ketrar on 04.07.26.
//  Copyright © 2026 Oleg Ketrar. All rights reserved.
//

import Testing
import TaskKit

@Suite struct ErrorHandlingTests {

    // MARK: - recover(closure)

    @Test func recover_onFailure_recoversValue() {
        var captured: Int?
        Action<Int>.sync { throw FakeError() }
            .recover { _ in 99 }
            .onSuccess { captured = $0 }
            .execute()
        #expect(captured == 99)
    }

    @Test func recover_onFailure_rethrows_propagates() {
        var captured: Error?
        Action<Int>.sync { throw FakeError() }
            .recover { _ in throw MockError() }
            .onFailure { captured = $0 }
            .execute()
        #expect(captured is MockError)
    }

    @Test func recover_onSuccess_passesThrough() {
        var recovered = false
        var captured: Int?
        Action<Int>.sync { 5 }
            .recover { _ in recovered = true; return 99 }
            .onSuccess { captured = $0 }
            .execute()
        #expect(captured == 5)
        #expect(!recovered)
    }

    // MARK: - recover(on: errorType)

    @Test func recover_onType_matches() {
        var captured: Int?
        Action<Int>.sync { throw FakeError() }
            .recover(on: FakeError.self) { _ in 10 }
            .onSuccess { captured = $0 }
            .execute()
        #expect(captured == 10)
    }

    @Test func recover_onType_doesNotMatch_propagates() {
        var failed = false
        Action<Int>.sync { throw FakeError() }
            .recover(on: MockError.self) { _ in 10 }
            .onFailure { _ in failed = true }
            .execute()
        #expect(failed)
    }

    // MARK: - recover(with:)

    @Test func recover_withValue() {
        var captured: Int?
        Action<Int>.sync { throw FakeError() }
            .recover(with: 77)
            .onSuccess { captured = $0 }
            .execute()
        #expect(captured == 77)
    }

    // MARK: - recoverWith

    @Test func recoverWith_onFailure_usesRecoveryAction() {
        var captured: Int?
        Action<Int>.sync { throw FakeError() }
            .recoverWith { _ in Action<Int>.sync { 55 } }
            .onSuccess { captured = $0 }
            .execute()
        #expect(captured == 55)
    }

    @Test func recoverWith_onSuccess_passesThrough() {
        var recovered = false
        var captured: Int?
        Action<Int>.sync { 5 }
            .recoverWith { _ in recovered = true; return Action<Int>.sync { 55 } }
            .onSuccess { captured = $0 }
            .execute()
        #expect(captured == 5)
        #expect(!recovered)
    }

    @Test func recoverWith_recoveryActionFailure_propagates() {
        var captured: Error?
        Action<Int>.sync { throw FakeError() }
            .recoverWith { _ in Action<Int>.sync { throw MockError() } }
            .onFailure { captured = $0 }
            .execute()
        #expect(captured is MockError)
    }

    // MARK: - convertErrorToNil / mapToOptional / mapToVoid

    @Test func convertErrorToNil_success_keepsValue() {
        var captured: Int?
        Action<Int>.sync { 7 }
            .convertErrorToNil()
            .onSuccess { captured = $0 }
            .execute()
        #expect(captured == 7)
    }

    @Test func convertErrorToNil_failure_becomesNil() {
        var captured: Int?
        Action<Int>.sync { throw FakeError() }
            .convertErrorToNil()
            .onSuccess { captured = $0 }
            .execute()
        #expect(captured == nil)
    }

    @Test func mapToOptional_wrapsValue() {
        var captured: Int?
        Action<Int>.sync { 3 }
            .mapToOptional()
            .onSuccess { captured = $0 }
            .execute()
        #expect(captured == 3)
    }

    @Test func mapToVoid_dropsOutput() {
        var called = false
        Action<Int>.sync { 9 }
            .mapToVoid()
            .onSuccess { _ in called = true }
            .execute()
        #expect(called)
    }
}
