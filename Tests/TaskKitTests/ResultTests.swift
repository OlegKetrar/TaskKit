//
//  ResultTests.swift
//  TaskKitTests
//
//  Created by Oleg Ketrar on 06.02.2022.
//

import XCTest
import TaskKit

class ResultTests: XCTestCase {
    private typealias SUT = Swift.Result<Int, DummyError>

    func test_value_positive() {
        XCTAssertEqual(SUT.success(10).value, 10)
    }

    func test_value_negative() {
        XCTAssertNil(SUT.failure(DummyError()).value)
    }

    func test_error_positive() throws {
        let err = DummyError()
        let sut = SUT.failure(err)

        XCTAssertEqual(try XCTUnwrap(sut.error), err)
    }

    func test_error_negative() {
        XCTAssertNil(SUT.success(0).error)
    }

    func test_isSuccess() {
        XCTAssertTrue(SUT.success(10).isSuccess)
        XCTAssertFalse(SUT.failure(DummyError()).isSuccess)
    }

    func test_isFailure() {
        XCTAssertTrue(SUT.failure(DummyError()).isFailure)
        XCTAssertFalse(SUT.success(10).isFailure)
    }
}
