# ConcurrencyHelpers

This package provides some helper methods that make adopting Swift concurrency easier.

Right now, the Swift standard library is lacking support for concurrency in very central functions like `Sequence.map(_:)` which is a hindrance when developing using async await.
As long as the standard library doesn't fully support concurrency, this package aims to help getting around these limitations.


## Installation

You can install this package by adding it to your package's dependencies:

```swift
let package = Package(
    // name, platforms, products, etc.
    dependencies: [
        // other dependencies
        .package(url: "https://github.com/Zollerboy1/ConcurrencyHelpers.git", from: "1.0.0"),
    ],
    // targets, etc.
)
```


## Usage

Just import the package and start using `map(_:)`, `filter(_:)`, etc. like normal while calling asynchronous code in the body:

```swift
import ConcurrencyHelpers

let photoNames = ["IMG001", "IMG99", "IMG0404"]
let photos = await photoNames.asyncMap { name in
    await downloadPhoto(named: name)
}
```

This package also contains implementations of `map(_:)` and `forEach(_:)` that perform the work concurrently by splitting the `Collection` into multiple chunks:

```swift
import ConcurrencyHelpers

let photoNames = getAllPhotoNames()
// could be thousands of photos
let photos = await photoNames.parallelMap { name in
    await downloadPhoto(named: name)
}
// Performs the work on as many threads as possible simultanously
```
