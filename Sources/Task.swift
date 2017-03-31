//
//  Task.swift
//  TaskKit
//
//  Created by Oleg Ketrar on 30.03.17.
//  Copyright © 2017 Oleg Ketrar. All rights reserved.
//

import Foundation

// MARK: - _ResultType

public protocol _ResultType {
    associatedtype Value
    typealias Error = Swift.Error

    var value: Optional<Value> { get }
    var error: Optional<Error> { get }
}

extension Result: _ResultType {
    public typealias Value = T

    public var value: T? {
        guard case let .success(value) = self else { return nil }
        return value
    }

    public var error: Error? {
        guard case let .failure(error) = self else { return nil }
        return error
    }
}

// MARK: - Task

public protocol Task {
    associatedtype Input
    associatedtype Output
    var execute: (Input, @escaping (Output) -> Void) -> Void { get }
}

public struct AnyTask<In, Out>: Task {
    public typealias Input  = In
    public typealias Output = Out
    public let execute: (In, @escaping (Out) -> Void) -> Void

    init(_ closure: @escaping (In, @escaping (Out) -> Void) -> Void) {
        execute = closure
    }
}

/// MARK: - Provide data

public struct Input<Data>: Task {
    public typealias Input  = Void
    public typealias Output = Data

    public var execute: ((), @escaping (Data) -> Void) -> Void

    public init(now data: Data) {
        execute = { $1(data) }
    }

    public init(lazy dataClosure: @autoclosure @escaping () -> Data) {
        execute = { $1(dataClosure()) }
    }
}

/// MARK: - Sequence

public extension Task {

    /// create sequence with task
    public func then<T: Task>(_ task: T) -> AnyTask<Input, T.Output> where T.Input == Output {
        return AnyTask { (input, onCompletion) in self.execute(input) { task.execute($0, onCompletion) } }
    }

    /// create sequence with closure
    public func then(_ closure: @escaping (Output) -> Void) -> AnyTask<Input, Output> {
        return then( AnyTask { closure($0); $1($0) })
    }
}

public extension Task where Output: _ResultType {

    /// MARK: FailableTask -> FailableTask

    /// create sequence with task
    public func then<T: Task>(_ task: T) -> AnyTask<Input, Result<T.Output.Value>>
    where T.Input == Output.Value, T.Output: _ResultType {

        return AnyTask { (input, onCompletion) in
            self.execute(input) {
                if let value = $0.value {
                    task.execute(value) {
                        if let value = $0.value {
                            onCompletion(.success(value))
                        } else {
                            onCompletion(.failure($0.error))
                        }
                    }
                } else {
                    onCompletion(Result.failure($0.error))
                }
            }
        }
    }

    /// MARK: FailableTask -> Task

    /// create sequence with task
    public func then<T: Task>(_ task: T) -> AnyTask<Input, Result<T.Output>> where T.Input == Output.Value {
        return AnyTask { (input, onCompletion) in
            self.execute(input) {
                if let value = $0.value {
                    task.execute(value) { onCompletion(.success($0)) }
                } else {
                    onCompletion(Result.failure($0.error))
                }
            }
        }
    }
}

/// MARK: - Convertion

/// MARK: Task -> Convertation

public extension Task {

    /// convertion of task result
    public func convert<T>(_ closure: @escaping (Output) -> T) -> AnyTask<Input, T> {
        return then(AnyTask { $1(closure($0)) })
    }

    /// failable convertion of task result (produce failable task)
    public func convert<T>(_ closure: @escaping (Output) -> Optional<T>) -> AnyTask<Input, Result<T>> {
        return then(AnyTask { (input, onCompletion) in
            if let converted = closure(input) {
                onCompletion(.success(converted))
            } else {
                onCompletion(.failure(nil))
            }
        })
    }
}

/// MARK: FailableTask -> Convertation

public extension Task where Output: _ResultType {

    /// convertion of task result
    public func convert<T>(_ closure: @escaping (Output.Value) -> T) -> AnyTask<Input, Result<T>> {
        return then(AnyTask {
            if let value = $0.value {
                $1(.success( closure(value) ))
            } else {
                $1(.failure($0.error))
            }
        })
    }

    /// failable convertion of task result (produce failable task)
    public func convert<T>(_ closure: @escaping (Output.Value) -> Optional<T>) -> AnyTask<Input, Result<T>> {
        return then(AnyTask {
            if let value = $0.value, let converted = closure(value) {
                $1(.success(converted))
            } else {
                $1(.failure($0.error))
            }
        })
    }
}

/// MARK: - Convert sequence

public extension Task where Output: Sequence {
    func map<T>(_ closure: @escaping (Output.Iterator.Element) -> T) -> AnyTask<Input, Array<T>> {
        return then(AnyTask { $1( $0.map(closure)) })
    }

    public func flatMap<T>(_ closure: @escaping (Output.Iterator.Element) -> Optional<T>) -> AnyTask<Input, Array<T>> {
        return then(AnyTask { $1( $0.flatMap(closure)) })
    }
}

public extension Task where Output: _ResultType, Output.Value: Sequence {
    public func map<T>(_ closure: @escaping (Output.Value.Iterator.Element) -> T) -> AnyTask<Input, Result<Array<T>>> {
        return then(AnyTask { $1($0.map(closure)) })
    }

    public func flatMap<T>(_ closure: @escaping (Output.Value.Iterator.Element) -> Optional<T>) -> AnyTask<Input, Result<Array<T>>> {
        return then(AnyTask { $1($0.flatMap(closure)) })
    }
}

/// MARK: - Awaiting

public protocol _SplittedValueType {
    associatedtype First
    associatedtype Second

    var first: First   { get }
    var second: Second { get }
}

public struct SplittedValue<T, V>: _SplittedValueType {
    public let first: T
    public let second: V

    init(_ f: T, _ s: V) {
        first  = f
        second = s
    }
}

public extension Task {
    public func split<T: Task>(with task: T) -> AnyTask<Input, SplittedValue<Output, T.Output>> where Input == T.Input {
        return AnyTask { (input, onCompletion) in
            let group = DispatchGroup()

            var firstOutput: Optional<Output>    = .none
            var secondOutput: Optional<T.Output> = .none

            group.enter()
            group.enter()

            group.notify(queue: .main) {
                guard case let .some(first) = firstOutput,
                    case let .some(second) = secondOutput else { fatalError("awaitingError") }

                onCompletion(SplittedValue(first, second))
            }

            self.execute(input)  { firstOutput = .some($0); group.leave() }
            task.execute(input) { secondOutput = .some($0); group.leave() }
        }
    }
}

/// MARK: - Split Results

public extension Task where Output: _SplittedValueType, Output.First: _ResultType {
    public func union() -> AnyTask<Input, Result<(Output.First.Value, Output.Second)>> {
        return then(AnyTask<Output, Result<(Output.First.Value, Output.Second)>> { (input, onCompletion) in
            if let firstResult = input.first.value {
                onCompletion(.success(firstResult, input.second))
            } else {
                onCompletion(.failure(input.first.error))
            }
        })
    }
}

public extension Task where Output: _SplittedValueType, Output.Second: _ResultType {
    public func union() -> AnyTask<Input, Result<(Output.First, Output.Second.Value)>> {
        return then(AnyTask<Output, Result<(Output.First, Output.Second.Value)>> { (input, onCompletion) in
            if let secondResult = input.second.value {
                onCompletion(.success(input.first, secondResult))
            } else {
                onCompletion(.failure(input.second.error))
            }
        })
    }
}

public extension Task where Output: _SplittedValueType, Output.First: _ResultType, Output.Second: _ResultType {
    public func union() -> AnyTask<Input, Result<(Output.First.Value, Output.Second.Value)>> {
        return then(AnyTask<Output, Result<(Output.First.Value, Output.Second.Value)>> { (input, onCompletion) in
            switch (input.first.value, input.second.value) {
            case let (.some(firstValue), .some(secondValue)):
                onCompletion(.success(firstValue, secondValue))

            default:
                let errors = [input.first.error as Any, input.second.error as Any].flatMap { $0 as? Swift.Error }
                onCompletion(.failure(errors.first))
            }
        })
    }
}

public extension Task where Output: _SplittedValueType {
    public func union() -> AnyTask<Input, (Output.First, Output.Second)> {
        return then(AnyTask<Output, (Output.First, Output.Second)> {
            $1(($0.first, $0.second))
        })
    }
}

/// MARK: - Execute Convenience

public extension Task where Input == Void {
    public func execute(_ closure: @escaping (Output) -> Void) {
        execute(Void(), closure)
    }

    public func finally(_ closure: @escaping (Output) -> Void) {
        execute(closure)
    }
}

/// MARK: - Unwrapping

public extension Task where Output: _ResultType {
    public func `catch`(_ closure: @escaping (Output.Error?) -> Void) -> AnyTask<Input, Output.Value> {
        return then( AnyTask { (result, onCompletion) in
            if let value = result.value {
                onCompletion(value)
            } else {
                closure(result.error)
            }
        })
    }

    public func ignoreFailure() -> AnyTask<Input, Output.Value> {
        return `catch` { _ in }
    }
}
