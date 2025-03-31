//
//  PaymentError.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 31/3/25.
//

import Foundation

/// Definición unificada de PaymentError para toda la aplicación
enum PaymentError: Int, Error, LocalizedError, Identifiable {
    // Identificadores de error
    case notConfigured = 1001
    case invalidCardDetails = 1002
    case invalidExpiryDate = 1003
    case paymentMethodCreationFailed = 1004
    case paymentIntentCreationFailed = 1005
    case paymentConfirmationFailed = 1006
    case paymentAuthenticationRequired = 1007
    case insufficientFunds = 1008
    case cardDeclined = 1009
    case cardExpired = 1010
    case userCancelled = 1011
    case unknown = 1000
    case paymentFailed = 1012
    
    // Propiedad id para Identifiable
    var id: Int { rawValue }
    
    // Mensaje de error localizado
    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Stripe no está configurado"
        case .invalidCardDetails:
            return "Detalles de tarjeta inválidos"
        case .invalidExpiryDate:
            return "Fecha de expiración inválida"
        case .paymentMethodCreationFailed:
            return "Error al crear el método de pago"
        case .paymentIntentCreationFailed:
            return "Error al crear la intención de pago"
        case .paymentConfirmationFailed:
            return "Error al confirmar el pago"
        case .paymentAuthenticationRequired:
            return "Se requiere autenticación adicional"
        case .insufficientFunds:
            return "Fondos insuficientes"
        case .cardDeclined:
            return "Tarjeta rechazada"
        case .cardExpired:
            return "Tarjeta expirada"
        case .userCancelled:
            return "Pago cancelado por el usuario"
        case .unknown:
            return "Error desconocido en el pago"
        case .paymentFailed:
            return "El pago ha fallado"
        }
    }
    
    // Sugerencia de recuperación
    var recoverySuggestion: String? {
        switch self {
        case .invalidCardDetails:
            return "Verifique los datos de su tarjeta e intente nuevamente"
        case .invalidExpiryDate:
            return "Ingrese la fecha de expiración en formato MM/AA"
        case .insufficientFunds:
            return "Intente con otra tarjeta o método de pago"
        case .cardDeclined:
            return "Su tarjeta fue rechazada. Intente con otra o contacte a su banco"
        case .cardExpired:
            return "Su tarjeta ha expirado. Por favor utilice otra tarjeta"
        default:
            return "Por favor, intente nuevamente o contacte a soporte"
        }
    }
    
    // Constructor con mensaje personalizado
    init(message: String) {
        self = .paymentFailed
    }
    
    // Método para PaymentFailed con mensaje personalizado
    static func paymentFailed(_ message: String) -> PaymentError {
        return .paymentFailed
    }
    
    // Conversión a NSError
    func asNSError() -> NSError {
        return NSError(
            domain: "com.appecomm.PaymentError",
            code: self.rawValue,
            userInfo: [
                NSLocalizedDescriptionKey: self.errorDescription ?? "Unknown error",
                NSLocalizedRecoverySuggestionErrorKey: self.recoverySuggestion ?? ""
            ]
        )
    }
    
    // Propiedad para acceder al mensaje (compatibilidad con el código existente)
    var message: String {
        return self.errorDescription ?? "Error desconocido en el pago"
    }
}
