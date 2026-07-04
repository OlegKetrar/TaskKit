//
//  MockError.swift
//  TaskKit
//
//  Created by Oleg Ketrar on 04.07.26.
//  Copyright © 2026 Oleg Ketrar. All rights reserved.
//

import Testing
import TaskKit

@Suite struct ResultTests {

    // MARK: - value / error / isSuccess / isFailure

    @Test func success_accessors() {
        let result = Result<Int>.success(42)
        #expect(result.value == 42)
        #expect(result.error == nil)
        #expect(result.isSuccess)
        #expect(!result.isFailure)
    }

    @Test func failure_accessors() {
        let result = Result<Int>.failure(MockError())
        #expect(result.value == nil)
        #expect(result.error != nil)
        #expect(!result.isSuccess)
        #expect(result.isFailure)
    }

    // MARK: - unwrap

    @Test func unwrap_success_returnsValue() throws {
        #expect(try Result<String>.success("hi").unwrap() == "hi")
    }

    @Test func unwrap_failure_throws() {
        #expect(throws: MockError.self) {
            try Result<Int>.failure(MockError()).unwrap()
        }
    }

    // MARK: - init(throwing:)

    @Test func init_throwing_success() {
        #expect(Result<Int> { 42 }.value == 42)
    }

    @Test func init_throwing_failure() {
        #expect(Result<Int> { throw MockError() }.error != nil)
    }

    // MARK: - map

    @Test func map_success_transforms() {
        #expect(Result<Int>.success(2).map { $0 * 3 }.value == 6)
    }

    @Test func map_failure_propagates() {
        let r = Result<Int>.failure(MockError()).map { $0 * 3 }
        #expect(r.error != nil)
        #expect(r.value == nil)
    }

    @Test func map_throwing_becomesFailure() {
        #expect(Result<Int>.success(1).map { _ in throw MockError() }.error != nil)
    }

    // MARK: - description

    @Test func description_strings() {
        #expect(Result<Int>.success(1).description == "success")
        #expect(Result<Int>.failure(MockError()).description == "failure")
    }

    // MARK: - Void / NoResult

    @Test func noResult_success() {
        let r: NoResult = .success
        #expect(r.isSuccess)
    }

    @Test func ignoredValue_succeeds() {
        #expect(Result<Int>.success(5).ignoredValue.isSuccess)
    }
}
