//
//  ExecutionBuffer.swift
//  TaskKit
//
//  Created by Oleg Ketrar on 25.11.17.
//  Copyright © 2017 Oleg Ketrar. All rights reserved.
//

import Foundation

public protocol ExecutionBuffer: class {
    func execute<In, Out>(action: LazyAction<In, Out>) -> LazyAction<In, Out>
}

public extension LazyAction {

    /// Wrapp action by specified execution buffer.
    func wrapped(by buffer: ExecutionBuffer) -> LazyAction {
        return buffer.execute(action: self)
    }
}
