//
//  ExecutionBuffer.swift
//  TaskKit
//
//  Created by Oleg Ketrar on 25.11.17.
//  Copyright © 2017 Oleg Ketrar. All rights reserved.
//

import Foundation

public protocol ExecutionBuffer: AnyObject {
    func execute<T>(task: Action<T>) -> Action<T>
}

extension Task where Failure == Swift.Error {

    /// Wrapp action by specified execution buffer.
    public func wrapped(by buffer: ExecutionBuffer) -> Task {
        return buffer.execute(task: self)
    }
}
