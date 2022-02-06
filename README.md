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
- [x] `Task<Value, TypedError>`
- [x] `Action<Value>` uses untyped Swift.Error
- [x] `SuccessTask<Value>` can't fail
- [x] `onSuccess`/`onFailure`/`onAny`/`always`
- [x] `map` / `flatMap` convert output
- [x] `then` compose sequence with another action
- [x] `recover` after error by providing `recoveryValue` / `recoveryClosure`
- [x] `async` / `await` /  `await(timeout:)`
- [x] `DispatchQueue.asyncValue`

## Usage

```swift
struct SomeError: Swift.Error {
  ...
}

// send Request and returns JSON
func downloadSmth(request: Request) -> Action<JSON> {
   return Action<JSON> { finish in
      request.send { response in
         if let json = response.json {
            finish(.success(json))
         } else {
            finish(.failure(SomeError()))
         }
      }
   }
}

// parse User from JSON
func parseUser(_ json: JSON) -> Action<User> {
   return Action<User> { completion in
      DispatchQueue.global().async {

         // do heavy parsing on bg queue
         let parseResult = Result<User> { try User(json) }

         // it is recommended to always call completion on main queue
         DispatchQueue.main.async { completion(parseResult) }
      }
   }
}

downloadSmth(request: FetchUserRequest())
   .onAny { 
      print("request finished") 
   }
   .then { json in 
      parseUser(json) 
   }
   .onSuccess { 
      print("user successfully parsed") 
   }
   .onFailure { 
      print("request failed or parsing failed") 
   }
   .recover { error in
      if error is NetworkError {
         return someCachedUser // action failed and we recover by providing recover value
      } else {
         throw error // can't recover, so move error
      }
   }
   .always {
      // stop preloader
   }
   .map { user in
      // proccess user
      print("user email is \(user.email)")
   }
   .execute()
```

## Requirements

- Swift 5.4+
- xCode 12.5+
- iOS 9.0+

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
