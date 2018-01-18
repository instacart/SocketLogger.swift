//
//  SocketLoggerSpec.swift
//  SocketLoggerTests
//
//  Created by Michael Sanders on 1/17/18.
//

import CocoaAsyncSocket
import Quick
import Nimble
import SwiftCheck
@testable import SocketLogger

final class SocketLoggerSpec: QuickSpec {
    override func spec() {
        it("should log to localhost") {
            self.testLocalConnection(host: "localhost", port: .randomPort, logs: self.generateLogs())
        }

        it("should log to IPv4 host") {
            self.testLocalConnection(host: "127.0.0.1", port: .randomPort, logs: self.generateLogs())
        }

        it("should log to IPv6 host") {
            self.testLocalConnection(host: "::1", port: .randomPort, logs: self.generateLogs())
        }
    }
}

private extension SocketLoggerSpec {
    func testLocalConnection(host: String, port: Int, logs: [SocketLogEntry]) {
        let proxy = SocketProxy()
        let serverSocket = GCDAsyncSocket(delegate: proxy, delegateQueue: .main)
        let logger = SocketLogger(host: host, port: port, isTLSEnabled: false)
        var acceptedServerSocket: GCDAsyncSocket?
        waitUntil { done in
            var expectedLogs: [SocketLogEntry] = logs
            proxy.socketDidAcceptNewSocketCallback = { _, newSocket in
                acceptedServerSocket = newSocket
                acceptedServerSocket?.readData(withTimeout: -1, tag: 0)
            }
            proxy.socketDidReadDataCallback = { socket, data, _ in
                let joinedMessage = String(data: data, encoding: .utf8) ?? "(null)"
                let messages = joinedMessage.split(separator: "\n")
                for message in messages {
                    guard let expectedLog = expectedLogs.first else {
                        fail("Unexpected message: \(message)")
                        return
                    }
                    let prefix = expectedLog.details.prefix(withFormatter: logger.dateFormatter)
                    let expectedMessage = "\(prefix) - \(expectedLog.message)"
                    print("Got message: \(message)")
                    expect(String(message)) == expectedMessage
                    expectedLogs.removeFirst()

                    if expectedLogs.isEmpty {
                        done()
                    } else {
                        socket.readData(withTimeout: -1, tag: 0)
                    }
                }
            }

            evaluate { try serverSocket.accept(onInterface: host, port: UInt16(port)) }
            for log in logs {
                logger.log(details: log.details, message: log.message)
            }
        }
    }

    func generateLogs() -> [SocketLogEntry] {
        return (0..<8).map { idx in
            SocketLogEntry(details: .init(hostname: "mymachine\(idx).example.com", application: "SocketLogger"),
                           message: "This is message \(idx + 1)")
        } + SocketLogEntry.arbitrary.sample
    }
}

private extension Int {
    static var randomPort: Int {
        return (1024..<Int(UInt16.max)).randomElement
    }
}

private extension CountableRange {
    var randomElement: Element {
        let distance = self.distance(from: startIndex, to: endIndex)
        let offset = arc4random_uniform(UInt32(distance))
        return self[index(startIndex, offsetBy: Bound.Stride(offset))]
    }
}
