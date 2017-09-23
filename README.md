# TaskKit

[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

- [Features](#features)
- [Usage](#usage)
- [Requirements](#requirements)
- [Installation](#installation)
- [License](#license)

## Features

- [x] `Carthage` support
- [x] `Swift PM` support
- [ ] `CocoaPods` support
- [x] `Result<T>`
- [x] `Action<Out>`
- [x] `LazyAction<In, Out>` input can provided lazily
- [x] `onSuccess`/`onFailure`/`onAny`/`always`
- [x] `map` convert output
- [x] `mapInput` convert input
- [x] `then`/`earlier` compose sequence with another action
- [x] `with(input)` converts `LazyAction` to `Action`
- [x] `ignoredOutput()` ignores output
- [x] `recover` after error by providing `recoveryValue` / `recoveryClosure`
- [ ] conditions `onlyIf(_ closure:)`
- [ ] `resolveOnQueue` / `execute` on queue, `completion` on queue
- [ ] `async` / `await`
- [ ] `zip` / `either` / `union` compose actions
- [ ] `Optional<T>.unwrap() -> Action<T>`
- [ ] `DispatchQueue( ... ).asyncValue(_ work: @escaping () throws -> T) -> Action<T>`
- [ ] `catch` & Non-fallible `Action`

## Usage

```swift
struct SomeError: Swift.Error {
  ...
}

// send Request and returns JSON
let downloadSmth = LazyAction<Request, JSON> { request, finish in
   request.send { response in
     if let json = response.json {
       finish(.success(json))
     } else {
       finish(.failure(SomeError()))
     }
   }
}

// parse User from JSON
let parseUser = LazyAction<JSON, User> { json, finish in
   finish(Result<User> {
     try User(json)
   })
}

downloadSmth
   .onSuccess {
      print("response json: \($0)")
   }.onFailure {
      print("response error: \($0)")
   }.always {
      print("request finished")
   }.then(parseUser) // chain execution
   .onSuccess {
      print("user parsed: \($0)")
   }.onAny {
      print("user fetching result \($0)")
   }.onFailure {
      print("fetching or parsing error \($0)")
   }.recover { error in
      if error is NetworkError {
         return someCachedUser // action failed and we recover by providing recover value
      } else {
         throw error // can't recover, so move error
      }
   }.always {
      /* stop preloaders */
   }.map { user in
      print("user email is \(user.email)")
   }.execute(with: FetchUserRequest())
```

## Requirements

- Swift 4+
- xCode 9+
- iOS 8.0+

## Installation

### Carthage

[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager that builds your dependencies and provides you with binary frameworks.

You can install Carthage with [Homebrew](http://brew.sh/) using the following command:

```bash
$ brew update
$ brew install carthage
```
To integrate NumberPad into your Xcode project using Carthage, specify it in your `Cartfile`:

```ogdl
github "OlegKetrar/TaskKit"
```
Run `carthage update` to build the framework and drag the built `TaskKit.framework` into your Xcode project.

### Swift Package Manager

The [Swift Package Manager](https://swift.org/package-manager/) is a tool for automating the distribution of Swift code and is integrated into the `swift` compiler. It is in early development, but TaskKit does support its use on supported platforms. 

Once you have your Swift package set up, adding TaskKit as a dependency is as easy as adding it to the `dependencies` value of your `Package.swift`.

```swift
dependencies: [
   .Package(url: "https://github.com/OlegKetrar/TaskKit")
]
```

## License

TaskKit is released under the MIT license. See LICENSE for details.
