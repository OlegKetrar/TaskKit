//
//  Concurrency.swift
//  TaskKit
//
//  Created by Oleg Ketrar on 25.06.2022.
//

import Foundation

extension AsyncTask where Failure == Swift.Error {

    public func task() async throws -> Success {
        try await withCheckedThrowingContinuation { continuation in
            self.onAny { continuation.resume(with: $0) }.execute()
        }
    }

    public init(async work: @escaping () async throws -> Success) {

        self.init { ending in
            _Concurrency.Task {
                do {
                    let value = try await work()

                    await MainActor.run {
                        ending(.success(value))
                    }

                } catch let error {
                    await MainActor.run {
                        ending(.failure(error))
                    }
                }
            }
        }
    }
}

extension AsyncTask where Failure == Never {

    public func task() async -> Success {
        await withCheckedContinuation { continuation in
            self.onSuccess { continuation.resume(returning: $0) }.run()
        }
    }

    public init(async work: @escaping () async -> Success) {

        self.init { ending in
            _Concurrency.Task {
                let value = await work()

                await MainActor.run {
                    ending(.success(value))
                }
            }
        }
    }
}
