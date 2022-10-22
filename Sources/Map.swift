//
//  Map.swift
//  TaskKit
//
//  Created by Oleg Ketrar on 20.08.2020.
//  Copyright © 2020 Oleg Ketrar. All rights reserved.
//

extension AsyncTask {

    /// Lightweight `then` where result can be success/failure.
    /// Does not compose action, just transform output.
    public func map<T>(
        _ transform: @escaping (Success) -> T
    ) -> AsyncTask<T, Failure> {

        return AsyncTask<T, Failure> { ending in
            self.work { result in
                ending(result.map(transform))
                self.finish(with: result)
            }
        }
    }

    public func flatMap<T>(
        _ transform: @escaping (Success) -> Swift.Result<T, Failure>
    ) -> AsyncTask<T, Failure> {

        return AsyncTask<T, Failure> { ending in
            self.work { result in
                ending(result.flatMap(transform))
                self.finish(with: result)
            }
        }
    }

    /// Ignore Action output.
    public func ignoredOutput() -> AsyncTask<Void, Failure> {
        return map { _ in }
    }
}
