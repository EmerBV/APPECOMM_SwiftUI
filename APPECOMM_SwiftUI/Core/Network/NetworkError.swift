//
//  NetworkError.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 18/3/25.
//

import Foundation

struct APIError: Codable {
    let message: String
    let code: String?
    let details: String?
}

enum NetworkError: Error, Equatable {
    case invalidURL
    case invalidResponse
    case noData
    case unauthorized
    case forbidden
    case notFound
    case badRequest(APIError?)
    case serverError(APIError?)
    case decodingError(DecodingError)
    case unknown(Error)
    
    static func == (lhs: NetworkError, rhs: NetworkError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidURL, .invalidURL),
             (.invalidResponse, .invalidResponse),
             (.noData, .noData),
             (.unauthorized, .unauthorized),
             (.forbidden, .forbidden),
             (.notFound, .notFound):
            return true
        case (.badRequest(let lhsError), .badRequest(let rhsError)):
            return lhsError?.message == rhsError?.message
        case (.serverError(let lhsError), .serverError(let rhsError)):
            return lhsError?.message == rhsError?.message
        case (.decodingError(let lhsError), .decodingError(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}

extension NetworkError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return NSLocalizedString("La URL no es válida", comment: "")
        case .invalidResponse:
            return NSLocalizedString("Respuesta del servidor inválida", comment: "")
        case .noData:
            return NSLocalizedString("No se recibieron datos", comment: "")
        case .unauthorized:
            return NSLocalizedString("No autorizado. Por favor inicie sesión nuevamente", comment: "")
        case .forbidden:
            return NSLocalizedString("No tiene permisos para realizar esta acción", comment: "")
        case .notFound:
            return NSLocalizedString("El recurso solicitado no existe", comment: "")
        case .badRequest(let apiError):
            return apiError?.message ?? NSLocalizedString("Solicitud inválida", comment: "")
        case .serverError(let apiError):
            return apiError?.message ?? NSLocalizedString("Error en el servidor", comment: "")
        case .decodingError:
            return NSLocalizedString("Error al procesar la respuesta", comment: "")
        case .unknown:
            return NSLocalizedString("Error desconocido", comment: "")
        }
    }
}
