//
//  SocketLogger.swift
//  InstaShopper
//
//  Created by Jason Kozemczak on 7/20/16.
//  Copyright © 2016 Instacart. All rights reserved.
//

import CocoaAsyncSocket

struct LogDetails {
    let date: NSDate
    let programName: String
}

/// A logging interface to socket-based providers, e.g. Papertrail, Loggly.
final class SocketLogger: NSObject {
    let useTLS: Bool
    let host: String
    let port: UInt16
    let senderName: String
    let token: String?

    static func papertrail(senderName senderName: String) -> SocketLogger {
        return .init(host: "logs.papertrailapp.com", port: 46865, senderName: senderName)
    }

    static func loggly(senderName senderName: String, token: String) -> SocketLogger {
        let token = "\(token)@41058"
        return .init(host: "logs-01.loggly.com", port: 6514, senderName: senderName, token: token)
    }

    init(host: String, port: UInt16, useTLS: Bool = true, senderName: String, token: String? = nil) {
        self.host = host
        self.port = port
        self.useTLS = useTLS
        self.senderName = senderName
        self.token = token
        messageQueue = dispatch_queue_create("\(messageQueueID).\(host)", DISPATCH_QUEUE_SERIAL)
    }

    func log(details details: LogDetails, message: String) {
        dispatch_async(messageQueue) {
            self.enqueueLog(details: details, message: message)
        }
    }

    private let messageQueue: dispatch_queue_t
    private var enqueuedLogs: [String] = []
    private lazy var tcpSocket: GCDAsyncSocket = GCDAsyncSocket(delegate: self, delegateQueue: self.messageQueue)
    private lazy var dateFormatter: NSDateFormatter = {
        let formatter = NSDateFormatter()
        let posixLocale = NSLocale(localeIdentifier: posixLocaleID)
        formatter.locale = posixLocale
        formatter.timeZone = NSTimeZone(abbreviation: "PST")
        formatter.dateFormat = defaultDateFormat
        return formatter
    }()

    private func enqueueLog(details details: LogDetails, message: String) {
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
            if let data = msg.dataUsingEncoding(NSUTF8StringEncoding) {
                tcpSocket.writeData(data, withTimeout: -1, tag: 1)
            }
            enqueuedLogs.removeFirst()
        }
    }

    private func formatted(details details: LogDetails, message: String) -> String {
        let strippedMessage = message.stringByReplacingOccurrencesOfString("\n", withString: " ")
        let header: String
        if let token = token {
            header = "[\(token) tag=\"\(senderName)\" tag=\"\(details.programName)\"]"
        } else {
            header = "-"
        }
        return "<22>1 \(dateFormatter.stringFromDate(details.date)) \(senderName) " +
               "\(details.programName) - - \(header) \(strippedMessage)\n"
    }

    private func connectToHost() {
        do {
            try tcpSocket.connectToHost(host, onPort: port)
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
