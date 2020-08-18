//
//  File.swift
//  
//
//  Created by Oleg Ketrar on 19.08.2020.
//

extension Task {

    public func execute() {
        run()
    }
}

extension Task where Failure == Swift.Error {

    @available(*, deprecated, renamed: "ignoredValue")
    public func ignoredOutput() -> Task<Void, Failure> {
        return ignoredValue()
    }
}

public typealias Action<T> = Task<T, Swift.Error>
public typealias NoResultAction = Action<Void>

public typealias Result<T> = Swift.Result<T, Swift.Error>
public typealias NoResult = Swift.Result<Void, Swift.Error>

@available(*, deprecated, message: "use Action")
public typealias LazyAction<Input, Output> = (Input) -> Action<Output>

@available(*, deprecated, message: "use Action")
public typealias NoResultLazyAction<Input> = (Input) -> Action<Void>
