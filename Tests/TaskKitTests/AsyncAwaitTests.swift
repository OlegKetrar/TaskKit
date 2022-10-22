//
//  AsyncAwaitTests.swift
//  
//
//  Created by Oleg Ketrar on 22.10.2022.
//

import Foundation
import XCTest
import TaskKit
import Dispatch

class AsyncAwaitTests: XCTestCase {

    @MainActor
    func test_async() async throws {

        let task = Task<String, Swift.Error>
            .init { ending in

                DispatchQueue.global().async {

                    DispatchQueue.main.async {
                        ending(.success("101"))
                    }
                }
            }
            .onSuccess { _ in
                XCTAssert(Thread.current.isMainThread)
            }

        XCTAssert(Thread.current.isMainThread)
        let value = try await task.task()

        XCTAssert(Thread.current.isMainThread)
        XCTAssertEqual(value, "101")
    }

    @MainActor
    func test_async_init() async throws {

        let task1 = Task<String, Swift.Error>
            .init { ending in

                DispatchQueue.global().async {

                    DispatchQueue.main.async {
                        ending(.success("101"))
                    }
                }
            }
            .onSuccess { _ in
                XCTAssert(Thread.current.isMainThread)
            }

        let task2 = Task<String, Swift.Error>
            .init(async: {
                try await task1.task()
            })
            .onSuccess { _ in
                XCTAssert(Thread.current.isMainThread)
            }

        let value = try await task2.task()

        XCTAssertEqual(value, "101")
    }
}
