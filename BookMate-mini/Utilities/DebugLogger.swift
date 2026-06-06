//
//  DebugLogger.swift
//  BookMate-mini
//
//  Created by Codex on 6/6/26.
//

import Foundation

enum DebugLogger {
    static func log(_ items: Any..., file: StaticString = #fileID, line: UInt = #line) {
        #if DEBUG
        let message = items.map { "\($0)" }.joined(separator: " ")
        print("[DEBUG] \(file):\(line)", message)
        #endif
    }
}
