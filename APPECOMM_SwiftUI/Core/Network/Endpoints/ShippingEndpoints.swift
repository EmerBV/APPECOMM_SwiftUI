//
//  ShippingEndpoints.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 28/3/25.
//

import Foundation

/// Endpoints para los detalles de envío
enum ShippingEndpoints: APIEndpoint {
    case getShippingDetails(userId: Int)
    case updateShippingDetails(details: ShippingDetailsRequest, userId: Int)
    
    var path: String {
        switch self {
        case .getShippingDetails(let userId):
            return "/shipping/\(userId)"
        case .updateShippingDetails:
            return "/shipping/update"
        }
    }
    
    var method: String {
        switch self {
        case .getShippingDetails:
            return HTTPMethod.get.rawValue
        case .updateShippingDetails:
            return HTTPMethod.post.rawValue
        }
    }
    
    var parameters: [String: Any]? {
        switch self {
        case .updateShippingDetails(let details, let userId):
            // Convertir details a parámetros JSON para el body
            let encoder = JSONEncoder()
            if let data = try? encoder.encode(details),
               let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                return dict
            }
            return nil
        case .getShippingDetails:
            return nil
        }
    }
    
    var encoding: ParameterEncoding {
        switch self {
        case .updateShippingDetails:
            return .json
        case .getShippingDetails:
            return .url
        }
    }
    
    var queryParameters: [String: Any]? {
        switch self {
        case .updateShippingDetails(_, let userId):
            return ["userId": userId]
        default:
            return nil
        }
    }
    
    var requiresAuthentication: Bool {
        return true
    }
}
