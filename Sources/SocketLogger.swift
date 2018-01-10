//
//  SocketLogger.swift
//  InstaShopper
//
//  Created by Jason Kozemczak on 7/20/16.
//  Copyright © 2016 Instacart. All rights reserved.
//

import CocoaAsyncSocket

public struct LogDetails {
    public let date: Date
    public let programName: String

    public init(date: Date, programName: String) {
        self.date = date
        self.programName = programName
    }
}

/// A logging interface to socket-based providers, e.g. Papertrail, Loggly.
public final class SocketLogger: NSObject {
    public let useTLS: Bool
    public let host: String
    public let port: Int
    public let senderName: String
    public let token: String?

    public static func papertrail(senderName: String) -> SocketLogger {
        return .init(host: "logs.papertrailapp.com", port: 46865, senderName: senderName)
    }

    public static func loggly(senderName: String, token: String) -> SocketLogger {
        let token = "\(token)@41058"
        return .init(host: "logs-01.loggly.com", port: 6514, senderName: senderName, token: token)
    }

    public init(host: String, port: Int, useTLS: Bool = true, senderName: String, token: String? = nil) {
        self.host = host
        self.port = port
        self.useTLS = useTLS
        self.senderName = senderName
        self.token = token
        messageQueue = DispatchQueue(label: "\(messageQueueID).\(host)", attributes: [])
    }

    public func log(details: LogDetails, message: String) {
        messageQueue.async {
            self.enqueueLog(details: details, message: message)
        }
    }

    private let messageQueue: DispatchQueue
    private var enqueuedLogs: [String] = []
    private lazy var tcpSocket: GCDAsyncSocket = .init(delegate: self, delegateQueue: self.messageQueue)
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        let posixLocale = Locale(identifier: posixLocaleID)
        formatter.locale = posixLocale
        formatter.timeZone = TimeZone(abbreviation: "PST")
        formatter.dateFormat = defaultDateFormat
        return formatter
    }()

    private func enqueueLog(details: LogDetails, message: String) {
        let msg = formatted(details: details, message: message)
        if !msg.isEmpty {
            enqueuedLogs.append(msg)
        }
        if tcpSocket.isDisconnected {
            connectToHost()
        } else if tcpSocket.isConnected {
            writeLogs()
        }
    }

    private func writeLogs() {
        guard tcpSocket.isConnected else { return }
        while let msg = enqueuedLogs.first {
            if let data = msg.data(using: .utf8) {
                tcpSocket.write(data, withTimeout: -1, tag: 1)
            }
            enqueuedLogs.removeFirst()
        }
    }

    private func formatted(details: LogDetails, message: String) -> String {
        let strippedMessage = message.replacingOccurrences(of: "\n", with: " ")
        let header: String
        if let token = token {
            header = "[\(token) tag=\"\(senderName)\" tag=\"\(details.programName)\"]"
        } else {
            header = "-"
        }
        return "<22>1 \(dateFormatter.string(from: details.date)) \(senderName) " +
               "\(details.programName) - - \(header) \(strippedMessage)\n"
    }

    private func connectToHost() {
        do {
            try tcpSocket.connect(toHost: host, onPort: UInt16(port))
            if useTLS {
                tcpSocket.startTLS(nil)
            }
            writeLogs()
        } catch {
            print("Error connecting to logger: \(error)")
        }
    }
}

extension SocketLogger: GCDAsyncSocketDelegate {}

private let posixLocaleID: String = "en_US_POSIX"
private let messageQueueID: String = "com.instacart.SocketLogger"

// See https://tools.ietf.org/html/rfc5424#section-6.2.3
private let defaultDateFormat: String = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZZZZZ"
