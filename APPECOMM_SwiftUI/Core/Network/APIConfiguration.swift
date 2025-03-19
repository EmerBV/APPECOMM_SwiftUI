//
//  APIConfiguration.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 19/3/25.
//

import Foundation

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
        // Usar la configuración centralizada desde AppConfig
        let config = AppConfig.shared
        
        guard let url = URL(string: config.apiBaseUrl) else {
            fatalError("URL base inválida: \(config.apiBaseUrl)")
        }
        
        self.baseURL = url
        self.timeoutInterval = config.apiTimeout
        self.defaultHeaders = [
            "Content-Type": "application/json",
            "Accept": "application/json",
            "User-Agent": config.getUserAgent()
        ]
    }
}
