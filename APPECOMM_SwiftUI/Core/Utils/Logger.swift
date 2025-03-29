//
//  Logger.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 19/3/25.
//

import Foundation
import OSLog

enum LogLevel: String {
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"
}

class Logger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.emerbv.APPECOMM-SwiftUI"
    private static let logger = os.Logger(subsystem: subsystem, category: "AppLog")
    private static let isDebugMode: Bool = {
#if DEBUG
        return true
#else
        return false
#endif
    }()
    
    static func log(_ level: LogLevel, message: String, file: String = #file, function: String = #function, line: Int = #line) {
        guard isDebugMode else { return }
        
        let fileName = (file as NSString).lastPathComponent
        let logMessage = "[\(fileName):\(line)] \(function) - \(message)"
        
        switch level {
        case .debug:
            logger.debug("🔵 \(logMessage)")
        case .info:
            logger.info("🟢 \(logMessage)")
        case .warning:
            logger.warning("🟠 \(logMessage)")
        case .error:
            logger.error("🔴 \(logMessage)")
        }
        
        // También imprimimos a consola para facilitar el debug durante desarrollo
        print("[\(level.rawValue)] \(logMessage)")
    }
    
    static func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(.debug, message: message, file: file, function: function, line: line)
    }
    
    static func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(.info, message: message, file: file, function: function, line: line)
    }
    
    static func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(.warning, message: message, file: file, function: function, line: line)
    }
    
    static func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(.error, message: message, file: file, function: function, line: line)
    }
    
    static func payment(_ message: String, level: LogLevel = .info, file: String = #file, function: String = #function, line: Int = #line) {
        let fileURL = URL(fileURLWithPath: file)
        let fileName = fileURL.lastPathComponent
        
        let logMessage = "[\(fileName):\(line)] \(function) - \(message)"
        //os_log("%{public}@", log: paymentLogger, type: level.osLogType, logMessage)
        log(level, message: logMessage, file: file, function: function, line: line)
        
        
#if DEBUG
        print("[\(level.rawValue)] [Payment] \(logMessage)")
#endif
    }
}
