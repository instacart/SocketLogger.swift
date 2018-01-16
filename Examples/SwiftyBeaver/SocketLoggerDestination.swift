//
//  SocketLoggerDestination.swift
//  SocketLogger
//
//  Created by Michael Sanders on 1/18/18.
//  Copyright 2018 Instacart. All rights reserved.
//

import Foundation
import SocketLogger
import SwiftyBeaver

/// An optional log destination that sends logs to the given SocketLogger.
final class SocketLoggerDestination: BaseDestination {
    let logger: SocketLogger
    let date: () -> Date
    let hostname: () -> String
    let application: () -> String
    let headers: () -> [String]

    @available(*, unavailable)
    override init() { fatalError() }
    required init(logger: SocketLogger,
                  date: @escaping () -> Date = Date.init,
                  hostname: @escaping @autoclosure () -> String,
                  application: @escaping @autoclosure () -> String,
                  headers: @escaping @autoclosure () -> [String] = []) {
        self.logger = logger
        self.date = date
        self.hostname = hostname
        self.application = application
        self.headers = headers
        super.init()
    }

    override public func send(_ level: SwiftyBeaver.Level,
                              msg: String, 
                              thread: String,
                              file: String, 
                              function: String, 
                              line: Int, 
                              context: Any? = nil) -> String? {
        let now = date()
        guard let formatted = super.send(level, msg: msg, thread: thread, file: file, 
                                         function: function, line: line, context: context) else { 
            return nil 
        }

        let details = SocketLogDetails(severity: level.syslogSeverity,
                                       date: now,
                                       hostname: hostname(),
                                       application: application(),
                                       headers: headers())
        logger.log(details: details, message: formatted)
        return formatted
    }
}

private extension SwiftyBeaver.Level {
    var syslogSeverity: SyslogSeverity {
        let mapping: [SwiftyBeaver.Level: SyslogSeverity] = [
            .verbose: .debug,
            .debug: .debug,
            .info: .info,
            .warning: .warning,
            .error: .error,
        ]
        return mapping[self] ?? .info
    }
}
