//
//  ArbitraryExtensions.swift
//  SocketLoggerTests
//
//  Created by Michael Sanders on 1/18/18.
//

@testable import SocketLogger
import Foundation
import SwiftCheck

struct SocketLogEntry {
    let details: SocketLogDetails
    let message: String
}

extension SocketLogEntry: Arbitrary {
    public static var arbitrary: Gen<SocketLogEntry> {
        return Gen<(SocketLogDetails, String)>.zip(SocketLogDetails.arbitrary,
                                                   String.arbitrary).map(SocketLogEntry.init)
    }
}

extension Date: Arbitrary {
    public static let arbitrary: Gen<Date> = Gen.one(of: [
        Gen.pure(Date()),
        Gen.pure(Date.distantFuture),
        Gen.pure(Date.distantPast),
        TimeInterval.arbitrary.map { Date(timeIntervalSinceReferenceDate: $0) }
    ])
}

extension SocketLogDetails: Arbitrary {
    public static var arbitrary: Gen<SocketLogDetails> {
        return Gen<(Int, Date, String, String, Int?, Int?, [String])>.zip(Int.arbitrary,
                                                                          Date.arbitrary,
                                                                          String.arbitrary,
                                                                          String.arbitrary,
                                                                          (Int?).arbitrary,
                                                                          (Int?).arbitrary,
                                                                          [String].arbitrary).map(SocketLogDetails.init)
    }
}
