//
//  Result.swift
//  TaskKit
//
//  Created by Oleg Ketrar on 30.03.17.
//  Copyright © 2017 Oleg Ketrar. All rights reserved.
//

import Foundation

// MARK: - Result

public enum Result<T> {
    case success(T)
    case failure(Swift.Error?)
}

extension Result where T == Void {
    public static var emptySuccess: Result {
        return .success(Void())
    }
}

extension Result {
    public var isSuccess: Bool {
        return value != nil
    }

    public var isFailure: Bool {
        return !isSuccess
    }

    public static var emptyFailure: Result {
        return .failure(nil)
    }
}
