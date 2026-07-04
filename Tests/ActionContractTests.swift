//
//  ActionContractTests.swift
//  TaskKitTests
//
//  Created by Oleg Ketrar on 04.07.26.
//  Copyright © 2026 Oleg Ketrar. All rights reserved.
//

import Testing
import TaskKit
import Foundation

// Exit tests run the body in a forked child process: if the body traps
// (precondition/fatalError/continuation double-resume), the child exits
// abnormally and the parent records an issue without crashing itself.
// The body is treated as the child's sync main(), so async bridging
// (CheckedContinuation) is run inside a Task and awaited via semaphore.
// Requires Swift 6.2+ toolchain.

@Suite struct ActionContractTests {

    // MARK: - Action completes exactly once

    // An Action that invokes its completion more than once is misuse.
    // When bridged to a CheckedContinuation the second resume traps the
    // process in debug. This exit test pins that contract: the child is
    // expected to exit with .failure rather than .success.
    @Test func doubleCompletion_crashesChildProcess() async {
        await #expect(processExitsWith: .failure) {
            let action = Action<Int> { finish in
                finish(.success(1))
                finish(.success(2))
            }

            runAwaiting(action)
        }
    }

    // Sanity check: a well-behaved Action completing exactly once, bridged
    // through a CheckedContinuation, exits the child normally.
    @Test func singleCompletion_exitsChildNormally() async {
        await #expect(processExitsWith: .success) {
            runAwaiting(Action<Int>.sync { 42 })
        }
    }
}

// Bridges a callback-based Action to a synchronous blocking call by
// resuming a CheckedContinuation from the Action's completion. Detects
// double-completion as a fatal error in debug builds.
private func runAwaiting<T>(_ action: Action<T>) {
    let sem = DispatchSemaphore(value: 0)

    Task {
        _ = try? await withCheckedThrowingContinuation { (cont: CheckedContinuation<T, Error>) in
            action
                .onSuccess { cont.resume(returning: $0) }
                .onFailure { cont.resume(throwing: $0) }
                .execute()
        }
        sem.signal()
    }

    sem.wait()
}
