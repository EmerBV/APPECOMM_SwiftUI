//
//  AppConfig.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 19/3/25.
//

import Foundation
import UIKit

// Enum para definir los diferentes entornos de la aplicación
enum AppEnvironment: String {
    case development
    case staging
    case production
    
    var baseUrl: String {
        switch self {
        case .development:
            return "http://localhost:9091/ecommdb/api/v1"
        case .staging:
            return "https://staging-api.ecommdb.example.com/api/v1"
        case .production:
            return "https://api.ecommdb.example.com/api/v1"
        }
    }
    
    var timeout: TimeInterval {
        switch self {
        case .development:
            return 60.0  // Tiempo más largo para desarrollo (debugging)
        case .staging:
            return 30.0
        case .production:
            return 15.0  // Más corto en producción para mejor experiencia de usuario
        }
    }
}

// Clase singleton para gestionar la configuración de la aplicación
class AppConfig {
    static let shared = AppConfig()
    
    // Configuración actual de la aplicación
    private(set) var environment: AppEnvironment
    private(set) var appName: String
    private(set) var appVersion: String
    private(set) var buildNumber: String
    private(set) var apiBaseUrl: String
    private(set) var apiTimeout: TimeInterval
    private(set) var enableAnalytics: Bool
    private(set) var enableCrashReporting: Bool
    private(set) var enableDebugLogging: Bool
    
    private init() {
        // En un caso real, estos valores podrían venir de un archivo de configuración
        // o de variables de entorno durante el proceso de build
        
#if DEBUG
        self.environment = .development
        self.enableDebugLogging = true
        self.enableAnalytics = false
        self.enableCrashReporting = false
#else
        self.environment = .production
        self.enableDebugLogging = false
        self.enableAnalytics = true
        self.enableCrashReporting = true
#endif
        
        // Obtener información del Bundle
        let bundle = Bundle.main
        self.appName = bundle.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "APPECOMM_SwiftUI"
        self.appVersion = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
        self.buildNumber = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        
        self.apiBaseUrl = environment.baseUrl
        self.apiTimeout = environment.timeout
        
        // Log de la configuración para debug
        if enableDebugLogging {
            Logger.info("Configuración de la aplicación:")
            Logger.info("- Entorno: \(environment.rawValue)")
            Logger.info("- Versión: \(appVersion) (\(buildNumber))")
            Logger.info("- API URL: \(apiBaseUrl)")
            Logger.info("- Timeout: \(apiTimeout)s")
            Logger.info("- Analytics: \(enableAnalytics ? "Habilitado" : "Deshabilitado")")
            Logger.info("- Crash Reporting: \(enableCrashReporting ? "Habilitado" : "Deshabilitado")")
        }
    }
    
    // Método para cambiar el entorno (útil para testing o para usuarios de desarrollo)
    func setEnvironment(_ env: AppEnvironment) {
        environment = env
        apiBaseUrl = env.baseUrl
        apiTimeout = env.timeout
        
        Logger.info("Entorno cambiado a: \(env.rawValue)")
        Logger.info("- API URL: \(apiBaseUrl)")
        Logger.info("- Timeout: \(apiTimeout)s")
    }
    
    // Método para habilitar/deshabilitar analytics
    func setAnalyticsEnabled(_ enabled: Bool) {
        enableAnalytics = enabled
        Logger.info("Analytics: \(enabled ? "Habilitado" : "Deshabilitado")")
    }
    
    // Método para habilitar/deshabilitar crash reporting
    func setCrashReportingEnabled(_ enabled: Bool) {
        enableCrashReporting = enabled
        Logger.info("Crash Reporting: \(enabled ? "Habilitado" : "Deshabilitado")")
    }
    
    // Método para habilitar/deshabilitar logging
    func setDebugLoggingEnabled(_ enabled: Bool) {
        enableDebugLogging = enabled
        Logger.info("Debug Logging: \(enabled ? "Habilitado" : "Deshabilitado")")
    }
    
    // Generar User-Agent para peticiones HTTP
    func getUserAgent() -> String {
        let device = UIDevice.current
        return "\(appName)/\(appVersion) (\(buildNumber); \(device.model); iOS \(device.systemVersion))"
    }
}
