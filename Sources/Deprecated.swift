//
//  Deprecated.swift
//  TaskKit
//
//  Created by Oleg Ketrar on 19.08.2020.
//  Copyright © 2020 Oleg Ketrar. All rights reserved.
//

@available(*, deprecated, message: "Use Swift.Result instead")
public typealias Result<T> = Swift.Result<T, Swift.Error>

@available(*, deprecated, message: "Use Swift.Result instead")
public typealias NoResult = Swift.Result<Void, Swift.Error>

@available(*, deprecated, message: "Use Action<Void>")
public typealias NoResultAction = Action<Void>

@available(*, unavailable, message: "use (Input) -> Action<Output>")
public typealias LazyAction<Input, Output> = (Input) -> Action<Output>

@available(*, unavailable, message: "use (Input) -> Action<Void>")
public typealias NoResultLazyAction<Input> = (Input) -> Action<Void>
