//
//  PerformanceLogger.swift
//  BookMate
//
//  Created by 한채림 on 6/17/26.
//

import Foundation
import os

// Instruments 타임라인 위에 내가 직접 꽂는 성능 측정용 표시판
enum PerformanceLogger {
    static let log = OSLog(
        subsystem: Bundle.main.bundleIdentifier ?? "BookMate",
        category: "MiniRoom"
    )

    static func makeSignpostID() -> OSSignpostID {
        OSSignpostID(log: log)
    }

    static func begin(_ name: StaticString, id: OSSignpostID) {
        os_signpost(.begin, log: log, name: name, signpostID: id)
    }

    static func end(_ name: StaticString, id: OSSignpostID) {
        os_signpost(.end, log: log, name: name, signpostID: id)
    }

    static func event(_ name: StaticString) {
        os_signpost(.event, log: log, name: name)
    }
}
