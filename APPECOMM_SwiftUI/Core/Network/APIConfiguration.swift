//
//  APIConfiguration.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 19/3/25.
//

import Foundation
import UIKit

protocol APIConfigurationProtocol {
    var baseURL: URL { get }
    var timeoutInterval: TimeInterval { get }
    var defaultHeaders: [String: String] { get }
}

struct APIConfiguration: APIConfigurationProtocol {
    let baseURL: URL
    let timeoutInterval: TimeInterval
    let defaultHeaders: [String: String]
    
    init() {
        // Idealmente este valor sería inyectado desde la configuración del entorno (desarrollo, staging, producción)
        guard let url = URL(string: "http://localhost:9091/ecommdb/api/v1") else {
            fatalError("URL base inválida")
        }
        
        self.baseURL = url
        self.timeoutInterval = 30.0
        self.defaultHeaders = [
            "Content-Type": "application/json",
            "Accept": "application/json",
            "User-Agent": Self.generateUserAgent()
        ]
    }
    
    private static func generateUserAgent() -> String {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        let deviceModel = UIDevice.current.model
        let systemVersion = UIDevice.current.systemVersion
        
        return "eCommDB-iOS/\(appVersion) (\(buildNumber); \(deviceModel); iOS \(systemVersion))"
    }
}
