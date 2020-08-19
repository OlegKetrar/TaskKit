//
//  Action.swift
//  TaskKit
//
//  Created by Oleg Ketrar on 20.08.2020.
//  Copyright © 2020 Oleg Ketrar. All rights reserved.
//

public typealias Action<T> = Task<T, Swift.Error>

extension Task where Failure == Swift.Error {

    public func execute() {
        run()
    }
}
