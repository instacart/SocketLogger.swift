//
//  SocketLogWriter.swift
//  SocketLogger
//
//  Created by Michael Sanders on 8/17/16.
//  Copyright 2016 Instacart. All rights reserved.
//

import SocketLogger
import Willow

/// An optional log writer that sends logs to the given SocketLogger.
struct SocketLogWriter {
    let modifiers: [LogModifier]
    let logger: SocketLogger
    let severity: (LogLevel) -> SyslogSeverity
    let date: () -> Date
    let hostname: () -> String
    let application: () -> String
    let headers: () -> [String]

    init(modifiers: [LogModifier],
         logger: SocketLogger,
         severity: @escaping (LogLevel) -> SyslogSeverity = SocketLogWriter.defaultSeverityTransformer,
         date: @escaping () -> Date = Date.init,
         hostname: @escaping @autoclosure () -> String,
         application: @escaping @autoclosure () -> String,
         headers: @escaping @autoclosure () -> [String] = []) {
        self.modifiers = modifiers
        self.logger = logger
        self.date = date
        self.hostname = hostname
        self.application = application
        self.headers = headers
        self.severity = severity
    }

    static func defaultSeverityTransformer(logLevel: LogLevel) -> SyslogSeverity {
        let mapping: [LogLevel: SyslogSeverity] = [
            .debug: .debug,
            .error: .error,
            .event: .notice,
            .info: .info,
            .warn: .warning,
        ]
        return mapping[logLevel] ?? .info
    }
}

extension SocketLogWriter: LogModifierWriter {
    func writeMessage(_ message: String, logLevel: LogLevel) {
        let now = date()
        let details = SocketLogDetails(severity: severity(logLevel),
                                       date: now,
                                       hostname: hostname(),
                                       application: application(),
                                       headers: headers())
        logger.log(details: details, message: message)
    }

    func writeMessage(_ message: LogMessage, logLevel: LogLevel) {
        writeMessage(message.name, logLevel: logLevel)
    }
}
