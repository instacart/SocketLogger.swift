//
//  SocketLoggerXCGDestination.swift
//  SocketLogger
//
//  Created by Jason Kozemczak on 7/19/16.
//  Copyright 2016 Instacart. All rights reserved.
//

import XCGLogger
import SocketLogger

/// An optional log destination that sends logs to the given SocketLogger.
final class SocketLoggerXCGDestination: BaseDestination {
    static let defaultIdentifier = "com.instacart.socketlogger.xcgdestination"
    let logger: SocketLogger
    let hostname: () -> String
    let application: () -> String
    let headers: () -> [String]

    @available(*, unavailable)
    override init(owner: XCGLogger?, identifier: String) { fatalError() }
    required init(owner: XCGLogger?, 
                  identifier: String = SocketLoggerXCGDestination.defaultIdentifier,
                  logger: SocketLogger,
                  hostname: @escaping @autoclosure () -> String,
                  application: @escaping @autoclosure () -> String,
                  headers: @escaping @autoclosure () -> [String] = []) {
        self.logger = logger
        self.hostname = hostname
        self.application = application
        self.headers = headers
        super.init(owner: owner, identifier: identifier)
        showDate = false
    }
  
    override func output(logDetails: LogDetails, message: String) {
        let details = SocketLogDetails(severity: logDetails.level.syslogSeverity,
                                       date: logDetails.date,
                                       hostname: hostname(),
                                       application: application(),
                                       headers: headers())
        logger.log(details: details, message: message)
    }
}

private extension XCGLogger.Level {
    var syslogSeverity: SyslogSeverity {
        let mapping: [XCGLogger.Level: SyslogSeverity] = [
            .debug: .debug,
            .error: .error,
            .info: .info,
            .none: .info,
            .severe: .critical,
            .verbose: .debug,
            .warning: .warning,
        ]
        return mapping[self] ?? .info
    }
}
