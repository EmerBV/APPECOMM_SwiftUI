//
//  OrderEndpoints.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 28/3/25.
//

import Foundation
enum OrderEndpoints: APIEndpoint {
    case createOrder(userId: Int)
    case getOrderById(orderId: Int)
    case getUserOrders(userId: Int)
    case updateOrderStatus(orderId: Int, status: String)
    
    var path: String {
        switch self {
        case .createOrder:
            return "user/place-order"
        case .getOrderById(let orderId):
            return "orders/\(orderId)/order"
        case .getUserOrders(let userId):
            return "orders/user/\(userId)/order"
        case .updateOrderStatus(let orderId, _):
            return "orders/\(orderId)/update-status"
        }
    }
    
    var method: String {
        switch self {
        case .createOrder:
            return HTTPMethod.post.rawValue
        case .getOrderById, .getUserOrders:
            return HTTPMethod.get.rawValue
        case .updateOrderStatus:
            return HTTPMethod.put.rawValue
        }
    }
    
    var parameters: [String: Any]? {
        switch self {
        case .createOrder(let userId):
            return ["userId": userId]
        case .updateOrderStatus(_, let status):
            return ["status": status]
        default:
            return nil
        }
    }
    
    var encoding: ParameterEncoding {
        switch self {
        case .createOrder:
            return .url
        case .updateOrderStatus:
            return .json
        default:
            return .url
        }
    }
    
    var requiresAuthentication: Bool {
        return true
    }
}
