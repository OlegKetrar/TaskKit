//
//  Action.swift
//  TaskKit
//
//  Created by Oleg Ketrar on 20.08.2020.
//  Copyright © 2020 Oleg Ketrar. All rights reserved.
//

public typealias Action<T> = AsyncTask<T, Swift.Error>

extension AsyncTask where Failure == Swift.Error {

    public func execute() {
        run()
    }

    /// Lightweight `then` where result can be success/failure.
    /// Does not compose action, just transform output.
    public func mapThrows<T>(
        _ transform: @escaping (Success) throws -> T
    ) -> AsyncTask<T, Failure> {

        return AsyncTask<T, Failure> { ending in
            self.work { result in

                ending(result.flatMap { value in
                    Swift.Result { try transform(value) }
                })

                self.finish(with: result)
            }
        }
    }
}
