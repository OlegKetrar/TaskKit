//
//  Map.swift
//  TaskKit
//
//  Created by Oleg Ketrar on 20.08.2020.
//  Copyright © 2020 Oleg Ketrar. All rights reserved.
//

extension Task {

    /// Lightweight `then` where result can be success/failure.
    /// Does not compose action, just transform output.
    public func map<T>(
        _ transform: @escaping (Success) -> T
    ) -> Task<T, Failure> {

        return Task<T, Failure> { ending in
            self.work { result in
                ending(result.map(transform))
                self.finish(with: result)
            }
        }
    }

    public func flatMap<T>(
        _ transform: @escaping (Success) -> Swift.Result<T, Failure>
    ) -> Task<T, Failure> {

        return Task<T, Failure> { ending in
            self.work { result in
                ending(result.flatMap(transform))
                self.finish(with: result)
            }
        }
    }

    /// Ignore Action output.
    public func ignoredOutput() -> Task<Void, Failure> {
        return map { _ in }
    }
}

extension Task where Failure == Swift.Error {

    /// Lightweight `then` where result can be success/failure.
    /// Does not compose action, just transform output.
    public func mapThrows<T>(
        _ transform: @escaping (Success) throws -> T
    ) -> Task<T, Failure> {

        return Task<T, Failure> { ending in
            self.work { result in

                ending(result.flatMap { value in
                    Swift.Result { try transform(value) }
                })

                self.finish(with: result)
            }
        }
    }
}
