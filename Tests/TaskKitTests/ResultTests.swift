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

    func test_isSuccess_true() {
        XCTAssertTrue(SUT.success(10).isSuccess)
    }

    func test_isSuccess_false() {
        XCTAssertFalse(SUT.failure(DummyError()).isSuccess)
    }

    func test_isFailure_true() {
        XCTAssertTrue(SUT.failure(DummyError()).isFailure)
    }

    func test_isFailure_false() {
        XCTAssertFalse (SUT.success(10).isFailure)
    }

    func test_ignoredValue() {
        XCTAssertTrue(SUT.success(10).ignoredValue.isSuccess)
    }

    func test_ignoredValue_failure() {
        let sut = SUT.failure(DummyError()).ignoredValue

        XCTAssertTrue(sut.isFailure)
        XCTAssertNotNil(sut.error)
    }

    func test_mapThrows_positive() {
        var captured: Int?

        let sut = Swift.Result<Int, Swift.Error>
            .success(10)
            .mapThrows { (value: Int) -> String in
                captured = value

                return "value"
            }

        XCTAssertEqual(captured, 10)
        XCTAssertEqual(sut.value, "value")
    }

    func test_mapThrows_throwingError() {
        let sut = Swift.Result<Int, Swift.Error>
            .success(10)
            .mapThrows { _ -> Int in
                throw DummyError()
            }

        XCTAssertNil(sut.value)
        XCTAssertTrue(sut.isFailure)
        XCTAssertTrue(sut.error is DummyError)
    }

    func test_mapThrows_notCalledWhenAlreadyFailure() {
        var captured: Int?

        let sut = Swift.Result<Int, Swift.Error>
            .failure(DummyError())
            .mapThrows { (value) -> Int in
                captured = value

                return 10
            }

        XCTAssertNil(sut.value)
        XCTAssertNil(captured)
        XCTAssertTrue(sut.isFailure)
        XCTAssertTrue(sut.error is DummyError)
    }
}
