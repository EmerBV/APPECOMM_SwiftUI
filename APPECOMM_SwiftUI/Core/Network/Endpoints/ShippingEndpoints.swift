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
    case getAllShippingAddresses(userId: Int)
    case updateShippingDetails(details: ShippingDetailsRequest, userId: Int)
    case createShippingAddress(details: ShippingDetailsRequest, userId: Int)
    case deleteShippingAddress(userId: Int, addressId: Int)
    case setDefaultShippingAddress(userId: Int, addressId: Int)
    
    var path: String {
        switch self {
        case .getShippingDetails(let userId):
            return "/shipping/\(userId)/default"
        case .getAllShippingAddresses(let userId):
            return "/shipping/\(userId)"
        case .updateShippingDetails:
            return "/shipping/update"
        case .createShippingAddress:
            // Aquí usamos el mismo endpoint que para actualizar, ya que el backend utiliza addOrUpdate
            return "/shipping/update"
        case .deleteShippingAddress(let userId, let addressId):
            return "/shipping/\(userId)/address/\(addressId)"
        case .setDefaultShippingAddress(let userId, let addressId):
            return "/shipping/\(userId)/address/\(addressId)/default"
        }
    }
    
    var method: String {
        switch self {
        case .getShippingDetails, .getAllShippingAddresses:
            return HTTPMethod.get.rawValue
        case .updateShippingDetails, .createShippingAddress:
            return HTTPMethod.post.rawValue
        case .deleteShippingAddress:
            return HTTPMethod.delete.rawValue
        case .setDefaultShippingAddress:
            return HTTPMethod.put.rawValue
        }
    }
    
    var parameters: [String: Any]? {
        switch self {
        case .updateShippingDetails(let details, _), .createShippingAddress(let details, _):
            // Convertir details a parámetros JSON para el body
            let encoder = JSONEncoder()
            if let data = try? encoder.encode(details),
               let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                return dict
            }
            return nil
        default:
            return nil
        }
    }
    
    var encoding: ParameterEncoding {
        switch self {
        case .updateShippingDetails, .createShippingAddress, .setDefaultShippingAddress:
            return .json
        default:
            return .url
        }
    }
    
    var queryParameters: [String: Any]? {
        switch self {
        case .updateShippingDetails(_, let userId), .createShippingAddress(_, let userId):
            return ["userId": userId]
        default:
            return nil
        }
    }
    
    var requiresAuthentication: Bool {
        return true
    }
}
