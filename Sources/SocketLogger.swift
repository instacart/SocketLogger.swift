//
//  SocketLogger.swift
//  SocketLogger
//
//  Created by Jason Kozemczak on 7/20/16.
//  Copyright © 2016 Instacart. All rights reserved.
//

import CocoaAsyncSocket

/// Severity level to attach to log message. 
///
/// See:
///
/// - https://en.wikipedia.org/wiki/Syslog#Severity_level
/// - https://tools.ietf.org/html/rfc5424#section-6.2.1
///
/// for full documentation.
public enum SyslogSeverity: Int {
    case emergency = 0
    case alert
    case critical
    case error
    case warning
    case notice
    case info
    case debug
}

/// Facility code to attach to log message.
///
/// See:
///
/// - https://en.wikipedia.org/wiki/Syslog#Facility
/// - https://tools.ietf.org/html/rfc5424#section-6.2.1
///
/// for full documentation.
public enum SyslogFacility: Int {
    case kernel = 0
    case user
    case mail
    case daemon
    case auth
    case syslog
    case lpr
    case news
    case uucp
    case clock
    case authpriv
    case ftp
    case ntp
    case audit
    case alert
    case cron
    case local0
    case local1
    case local2
    case local3
    case local4
    case local5
    case local6
    case local7
}

/// SocketLogDetails is a struct used to attach metadata for configuring each
/// syslog message.
///
/// See https://tools.ietf.org/html/rfc5424#page-8 for further details on
/// supported fields.
public struct SocketLogDetails {
    let priority: Int
    let date: Date
    let hostname: String
    let application: String
    let pid: Int?
    let messageID: Int?
    let headers: [String]
}

public extension SocketLogDetails {
    init(severity: SyslogSeverity = .info,
         facility: SyslogFacility = .user,
         date: Date = .init(),
         hostname: String,
         application: String,
         pid: Int? = nil,
         messageID: Int? = nil,
         headers: [String] = []) {
        self.init(priority: severity.rawValue + facility.rawValue * 8,
                  date: date,
                  hostname: hostname,
                  application: application,
                  pid: pid,
                  messageID: messageID,
                  headers: headers)
    }
}

/// SocketLogger is a syslog interface for socket-based logging providers,
/// e.g. Papertrail, Loggly, LogDNA.
public final class SocketLogger {
    let host: String
    let port: Int
    let useTLS: Bool
    let token: String

    /// Create a SocketLogger instance configured for Papertrail
    /// (https://papertrailapp.com).
    public static var papertrail: SocketLogger { return .init(host: "logs.papertrailapp.com", port: 46865) }

    /// Create a SocketLogger instance configured for Loggly
    /// (https://www.loggly.com).
    public static func loggly(token: String) -> SocketLogger {
        return .init(host: "logs-01.loggly.com", port: 6514, token: "\(token)@41058")
    }

    /// Create a SocketLogger instance configured for LogDNA
    /// (https://logdna.com).
    public static func logDNA(token: String, port: Int) -> SocketLogger {
        return .init(host: "syslog-a.logdna.com", port: port, token: "logdna@48950 key=\"\(token)\"")
    }

    /// Create a SocketLogger instance configured for a given host.
    ///
    /// - parameter host: Basename to connect socket.
    /// - parameter port: Port to configure socket.
    /// - parameter useTLS: Toggle to secure connection with TLS
    ///                     (defaults to true).
    /// - parameter token: Token to attach to syslog headers (typically used
    ///                    for API keys).
    ///
    /// - returns: SocketLogger instance configured for the given host.
    public init(host: String, port: Int, useTLS: Bool = true, token: String = "") {
        self.host = host
        self.port = port
        self.useTLS = useTLS
        self.token = token
        messageQueue = DispatchQueue(label: "\(messageQueueID).\(host)", attributes: [])
    }

    /// Asynchronously enqueues the given log message. Attempts to connect to
    /// host if not already connected.
    public func log(details: SocketLogDetails, message: String) {
        messageQueue.async {
            self.enqueueLog(details: details, message: message)
        }
    }

    private let messageQueue: DispatchQueue
    private var enqueuedLogs: [Data] = []
    private var isWriting: Bool = false
    private lazy var tcpSocket: GCDAsyncSocket = .init(delegate: self.socketProxy, delegateQueue: self.messageQueue)
    private lazy var socketProxy: SocketProxy = {
        let proxy = SocketProxy()
        proxy.socketDidDisconnectCallback = { [unowned self] _, _ in
            self.isWriting = false
        }
        proxy.socketDidWriteDataWithTagCallback = { [unowned self] _, tag in
            guard tag == writerTag, self.isWriting else { return }
            self.isWriting = false
            self.writeLogs()
        }
        return proxy
    }()
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: posixLocaleID)
        formatter.timeZone = TimeZone(abbreviation: "PST")
        formatter.dateFormat = defaultDateFormat
        return formatter
    }()
}

private final class SocketProxy: NSObject {
    var socketDidDisconnectCallback: ((GCDAsyncSocket, Error?) -> Void)?
    var socketDidWriteDataWithTagCallback: ((GCDAsyncSocket, Int) ->Void)?
}

extension SocketProxy: GCDAsyncSocketDelegate {
    func socketDidDisconnect(_ socket: GCDAsyncSocket, withError error: Error?) {
        socketDidDisconnectCallback?(socket, error)
    }

    func socket(_ socket: GCDAsyncSocket, didWriteDataWithTag tag: Int) {
        socketDidWriteDataWithTagCallback?(socket, tag)
    }
}

private extension SocketLogDetails {
    func prefix(withFormatter dateFormatter: DateFormatter) -> String {
        let formattedPID: String = pid.flatMap(String.init) ?? "-"
        let formattedMessageID: String = messageID.flatMap(String.init) ?? "-"
        return "<\(priority)>1 \(dateFormatter.string(from: date)) \(hostname) \(application) \(formattedPID) " +
               "\(formattedMessageID)"
    }
}

private extension SocketLogger {
    func enqueueLog(details: SocketLogDetails, message: String) {
        let msg = formatted(details: details, message: message)
        if let data = msg.data(using: .utf8), !msg.isEmpty, !data.isEmpty {
            enqueuedLogs.append(data)
        }
        if tcpSocket.isDisconnected {
            connectToHost()
        } else if tcpSocket.isConnected {
            writeLogs()
        }
    }

    func writeLogs() {
        guard let msg = enqueuedLogs.first, tcpSocket.isConnected, !isWriting else { return }
        isWriting = true
        enqueuedLogs.removeFirst()
        tcpSocket.write(msg, withTimeout: -1, tag: writerTag)
    }

    func formatted(details: SocketLogDetails, message: String) -> String {
        let strippedMessage = message.replacingOccurrences(of: "\n", with: " ")
        let header: String
        if token.isEmpty {
            header = "-"
        } else {
            let tags: [String] = [details.hostname, details.application] + details.headers
            let joinedHeader: String = tags.map { "tag=\"\($0)\"" }.reduce("", { $0 + " " + $1 })
            header = "[\(token)\(joinedHeader)]"
        }
        return "\(details.prefix(withFormatter: dateFormatter)) \(header) \(strippedMessage)\n"
    }

    func connectToHost() {
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

private let posixLocaleID: String = "en_US_POSIX"
private let messageQueueID: String = "com.instacart.socket-logger"
private let writerTag: Int = 0x2a

// See https://tools.ietf.org/html/rfc5424#section-6.2.3
private let defaultDateFormat: String = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZZZZZ"
