# SocketLogger

SocketLogger is a logging µlib compatible with any socket-based syslog
service. Allows flexibility to choose between various logging providers while
integrating with any logging framework of your choice (e.g.
[SwiftyBeaver](https://github.com/SwiftyBeaver/SwiftyBeaver),
[Willow](https://github.com/Nike-Inc/Willow),
[XCGLogger](https://github.com/DaveWoodCom/XCGLogger)).

## Requirements

SocketLogger is compatible with iOS 8+, macOS 10.10 and tvOS 9.
Requires Swift 4.

## Installation

### [Carthage](https://github.com/Carthage/Carthage)

Add this to your `Cartfile`:

```
github "instacart/SocketLogger.swift"
```

Then run:

```
$ carthage update
```

## Usage

### Swift

Initialize the logger:
```swift
import SocketLogger
let logger = SocketLogger(host: "myloggingprovider.io", port: 0356, token: "[token]")
```

Log a message (or integrate with a logging framework of your choice):
```swift
logger.log(details: .init(hostname: "mymachine.example.com", application: "SocketLogger"),
           message: "A socket is a generalized interprocess communication channel.")
```

## Integration

We have included a handful of
[examples](https://github.com/instacart/SocketLogger.swift/tree/master/Examples)
for using SocketLogger with popular logging frameworks in this repo.

### Carthage

Since Carthage has no notion of subspecs, these must be copied manually:

- Run `carthage checkout`.
- Drag `Carthage/Checkouts/SocketLogger.swift/Examples/{library}` to your
  project. Make sure the "Copy items if needed" toggle is turned off.
- Integrate according to instructions with your logging framework.

## Providers

SocketLogger currently supports:

- [Papertrail](https://papertrailapp.com/)
- [Loggly](https://www.loggly.com/)
- [LogDNA](https://logdna.com/)

Don't see yours listed? 
[Add it](https://github.com/instacart/SocketLogger.swift/blob/607184c/Sources/SocketLogger.swift#L88)
[today](https://github.com/instacart/SocketLogger.swift/pulls/)!

## License

```
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
