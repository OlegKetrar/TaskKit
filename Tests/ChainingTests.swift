//
//  MockError.swift
//  TaskKit
//
//  Created by Oleg Ketrar on 04.07.26.
//  Copyright © 2026 Oleg Ketrar. All rights reserved.
//

import Testing
import TaskKit

@Suite struct ChainingTests {

    // MARK: - then (action variant)

    @Test func thenAction_passesOutputDownstream() {
        var captured: String?
        Action<Int>.sync { 5 }
            .then { input in Action<String>.sync { "v\(input)" } }
            .execute { captured = $0 }
        #expect(captured == "v5")
    }

    @Test func thenAction_upstreamFailure_skipsDownstream() {
        var downstreamRan = false
        var captured: Error?
        Action<Int>.sync { throw MockError() }
            .then { _ in downstreamRan = true; return Action<String>.sync { "x" } }
            .onFailure { captured = $0 }
            .execute()
        #expect(!downstreamRan)
        #expect(captured is MockError)
    }

    @Test func thenAction_downstreamFailure_propagates() {
        var captured: Error?
        Action<Int>.sync { 5 }
            .then { _ in Action<String>.sync { throw MockError() } }
            .onFailure { captured = $0 }
            .execute()
        #expect(captured is MockError)
    }

    // MARK: - then (closure variant)

    @Test func thenClosure_resolvesSuccess() {
        var captured: String?
        Action<Int>.sync { 7 }
            .then { input, resolve in resolve(.success("v\(input)")) }
            .execute { captured = $0 }
        #expect(captured == "v7")
    }

    @Test func thenClosure_upstreamFailure_propagates() {
        var captured: Error?
        Action<Int>.sync { throw MockError() }
            .then { input, resolve in resolve(.success("v\(input)")) }
            .onFailure { captured = $0 }
            .execute()
        #expect(captured is MockError)
    }

    // MARK: - map

    @Test func map_transformsSuccess() {
        var captured: String?
        Action<Int>.sync { 42 }
            .map { String($0) }
            .execute { captured = $0 }
        #expect(captured == "42")
    }

    @Test func map_propagatesFailure() {
        var captured: Error?
        Action<Int>.sync { throw MockError() }
            .map { String($0) }
            .onFailure { captured = $0 }
            .execute()
        #expect(captured is MockError)
    }

    // MARK: - ignoredOutput

    @Test func ignoredOutput_succeedsWithVoid() {
        var called = false
        Action<Int>.sync { 1 }
            .ignoredOutput()
            .onSuccess { called = true }
            .execute()
        #expect(called)
    }
}
