//
//  NimbleExtensions.swift
//  SocketLoggerTests
//
//  Created by Michael Sanders on 1/17/18.
//

import Nimble

func evaluate<T>(file: Nimble.FileString = #file, line: UInt = #line, expression: @escaping () throws -> T) -> T? {
    var value: T?
    expect { try value = expression() }.notTo(throwError())
    return value
}
