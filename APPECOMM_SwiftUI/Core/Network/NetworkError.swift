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
            return "invalid_url".localized
        case .invalidResponse:
            return "invalid_response".localized
        case .noData:
            return "no_data".localized
        case .unauthorized:
            return "unauthorized".localized
        case .forbidden:
            return "forbidden".localized
        case .notFound:
            return "not_found".localized
        case .badRequest(let apiError):
            return apiError?.message ?? "invalid_request".localized
        case .serverError(let apiError):
            return apiError?.message ?? "server_error".localized
        case .decodingError:
            return "processing_error".localized
        case .unknown:
            return "unknown_error".localized
        }
    }
}
