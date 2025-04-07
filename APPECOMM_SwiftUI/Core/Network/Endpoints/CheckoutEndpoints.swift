//
//  CheckoutEndpoints.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 28/3/25.
//

import Foundation

enum CheckoutEndpoints: APIEndpoint {
    case createOrder(Order)
    case getOrderById(orderId: Int)
    case getUserOrders(userId: Int)
    case updateOrderStatus(orderId: Int, status: String)
    
    var path: String {
        switch self {
        case .createOrder:
            return "orders/user/place-order"
        case .getOrderById(let orderId):
            return "orders/\(orderId)/order"
        case .getUserOrders(let userId):
            return "orders/user/\(userId)/order"
        case .updateOrderStatus(let orderId, _):
            return "orders/\(orderId)/status"
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
        case .createOrder(let order):
            return [
                "items": order.items.map { item in
                    [
                        "productId": item.productId,
                        "quantity": item.quantity
                    ]
                }
            ]
        case .updateOrderStatus(_, let status):
            return ["status": status]
        default:
            return nil
        }
    }
    
    var queryParameters: [String: Any]? {
        switch self {
        case .createOrder(let order):
            return ["userId": order.userId]
        default:
            return nil
        }
    }
    
    var encoding: ParameterEncoding {
        switch self {
        case .createOrder, .updateOrderStatus:
            return .json
        default:
            return .url
        }
    }
    
    var requiresAuthentication: Bool {
        return true
    }
} 
