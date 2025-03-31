//
//  Logger+Payment.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 31/3/25.
//

import Foundation
import OSLog

extension Logger {
    static func payment(_ message: String, level: LogLevel = .info, file: String = #file, function: String = #function, line: Int = #line) {
        let fileURL = URL(fileURLWithPath: file)
        let fileName = fileURL.lastPathComponent
        
        let logMessage = "[\(fileName):\(line)] \(function) - \(message)"
        log(level, message: "[Payment] \(logMessage)", file: file, function: function, line: line)
        
        #if DEBUG
        print("[\(level.rawValue)] [Payment] \(logMessage)")
        #endif
    }
}
