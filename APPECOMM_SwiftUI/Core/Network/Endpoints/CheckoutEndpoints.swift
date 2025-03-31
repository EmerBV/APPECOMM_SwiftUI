import Foundation

enum CheckoutEndpoints: APIEndpoint {
    case createOrder(Order)
    case getOrder(id: Int)
    case updateOrderStatus(id: Int, status: String)
    
    var path: String {
        switch self {
        case .createOrder:
            return "orders/user/place-order"
        case .getOrder(let id):
            return "orders/\(id)"
        case .updateOrderStatus(let id, _):
            return "orders/\(id)/status"
        }
    }
    
    var method: String {
        switch self {
        case .createOrder:
            return HTTPMethod.post.rawValue
        case .getOrder:
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