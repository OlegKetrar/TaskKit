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
- [x] `LazyAction` (input can provided lazily) & `Action`
- [x] `onSuccess`, `onFailure`, `onAny`, `always`
- [x] `map`, `flatMap`, `then` on `LazyAction`
- [x] `mapInput`, `flatMapInput`, `earlier` on `LazyAction`
- [ ] `AppError` 
- [ ] conditions `onlyIf(_ closure:)`
- [ ] background queue execution

## Usage

```swift
let firstAction  = ...
let secondAction = <someYourAction>
   .onSuccess { print("second succeed \($0)") }
   .onFailure { print("second failed \($0)")  }

let superImportantAction = <someYourActionNeedExecutedFirstly>
   .onAny { print("important finished with \($0)") }

firstAction
   .onSuccess { print("first succeed \($0)") }
   .onFailure { print("first failed \($0)")  }
   .then(secondAction)
   .earlier(superImportantAction)
   .map { 
      // transform result of composed actions 
   }.always { 
      // stop preloader, etc
   }.input( ... ) // provide input lazily
   .execute()
```

## Requirements

- Swift 3.1+
- xCode 8.3+
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
