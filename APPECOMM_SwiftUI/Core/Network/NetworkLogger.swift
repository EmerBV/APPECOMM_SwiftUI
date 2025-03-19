//
//  NetworkLogger.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 19/3/25.
//

import Foundation
import OSLog

protocol NetworkLoggerProtocol {
    func logRequest(_ request: URLRequest)
    func logResponse(_ response: URLResponse?, data: Data?, error: Error?)
}

final class NetworkLogger: NetworkLoggerProtocol {
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.emerbv.APPECOMM-SwiftUI", category: "Network")
    private let isDebugMode: Bool
    
    init(isDebugMode: Bool = true) {
        self.isDebugMode = isDebugMode
    }
    
    func logRequest(_ request: URLRequest) {
        guard isDebugMode else { return }
        
        logger.debug("⬆️ OUTGOING REQUEST")
        
        if let url = request.url?.absoluteString {
            logger.debug("URL: \(url)")
        }
        
        if let method = request.httpMethod {
            logger.debug("Method: \(method)")
        }
        
        if let headers = request.allHTTPHeaderFields, !headers.isEmpty {
            logger.debug("Headers: \(self.prettyPrint(headers))")
        }
        
        if let body = request.httpBody, !body.isEmpty, let bodyString = String(data: body, encoding: .utf8) {
            let sanitizedBody = self.sanitizeJSON(bodyString)
            logger.debug("Body: \(sanitizedBody)")
        }
    }
    
    func logResponse(_ response: URLResponse?, data: Data?, error: Error?) {
        guard isDebugMode else { return }
        
        logger.debug("⬇️ INCOMING RESPONSE")
        
        if let error = error {
            logger.error("Error: \(error.localizedDescription)")
            return
        }
        
        if let httpResponse = response as? HTTPURLResponse {
            logger.debug("Status Code: \(httpResponse.statusCode)")
            
            if !httpResponse.allHeaderFields.isEmpty {
                logger.debug("Headers: \(self.prettyPrint(httpResponse.allHeaderFields as? [String: Any] ?? [:]))")
            }
        }
        
        if let data = data, !data.isEmpty {
            if let responseString = String(data: data, encoding: .utf8) {
                let sanitizedResponse = self.sanitizeJSON(responseString)
                if sanitizedResponse.count > 1000 {
                    logger.debug("Response: \(sanitizedResponse.prefix(1000))... (truncated)")
                } else {
                    logger.debug("Response: \(sanitizedResponse)")
                }
            } else {
                logger.debug("Response: Unable to convert data to string")
            }
        }
    }
    
    private func prettyPrint(_ dict: [String: Any]) -> String {
        var result = "{\n"
        for (key, value) in dict {
            let sanitizedValue = key.lowercased().contains("password") || key.lowercased().contains("token")
                ? "***REDACTED***"
                : "\(value)"
            result += "  \(key): \(sanitizedValue)\n"
        }
        result += "}"
        return result
    }
    
    private func sanitizeJSON(_ jsonString: String) -> String {
        // Expresión regular básica para encontrar passwords y tokens
        // En un proyecto real, esto sería más sofisticado
        let passwordPattern = "\"password\"\\s*:\\s*\"[^\"]*\""
        let tokenPattern = "\"token\"\\s*:\\s*\"[^\"]*\""
        
        var sanitized = jsonString
        sanitized = sanitized.replacingOccurrences(of: passwordPattern, with: "\"password\":\"***REDACTED***\"", options: .regularExpression)
        sanitized = sanitized.replacingOccurrences(of: tokenPattern, with: "\"token\":\"***REDACTED***\"", options: .regularExpression)
        
        return sanitized
    }
}
