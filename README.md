# TaskKit

[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

- [Features](#features)
- [Usage](#usage)
- [Requirements](#requirements)
- [Installation](#installation)
- [License](#license)

## Features

- [x] Carthage support
- [x] Swift PM support
- [ ] CocoaPods support
- [ ] implement AppError 
- [ ] implement background queue task execution
- [ ] add examples

## Usage

``swift
Input(now: 100)
    .convert { $0 + 23 }
    .then { print($0) }
    .split(with: Input(lazy: "345").convert { Int($0) })
    .union()
    .catch { print($0) }
    .execute { print("converted value: \($0)") }
``

## Requirements

- Swift 3.1+
- xCode 8.3+
- iOS 8.0+

## Installation

### Carthage

[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager that builds your dependencies and provides you with binary frameworks.

You can install Carthage with [Homebrew](http://brew.sh/) using the following command:

``bash
$ brew update
$ brew install carthage
``
To integrate NumberPad into your Xcode project using Carthage, specify it in your `Cartfile`:

``ogdl
github "OlegKetrar/TaskKit"
``
Run `carthage update` to build the framework and drag the built `Tools.framework` into your Xcode project.

### Swift Package Manager

The [Swift Package Manager](https://swift.org/package-manager/) is a tool for automating the distribution of Swift code and is integrated into the `swift` compiler. It is in early development, but TaskKit does support its use on supported platforms. 

Once you have your Swift package set up, adding TaskKit as a dependency is as easy as adding it to the `dependencies` value of your `Package.swift`.

``swift
dependencies: [
    .Package(url: "https://github.com/OlegKetrar/TaskKit", "0.2.2")
]
``

## License

TaskKit is released under the MIT license. See LICENSE for details.
