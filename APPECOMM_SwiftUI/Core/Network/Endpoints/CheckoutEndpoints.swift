import Foundation

enum CheckoutEndpoints: APIEndpoint {
    case createOrder(Order)
    case getOrder(id: Int)
    case updateOrderStatus(id: Int, status: String)
    
    var path: String {
        switch self {
        case .createOrder:
            return "/orders"
        case .getOrder(let id):
            return "/orders/\(id)"
        case .updateOrderStatus(let id, _):
            return "/orders/\(id)/status"
        }
    }
    
    var method: String {
        switch self {
        case .createOrder:
            return HTTPMethod.post.rawValue
        case .getOrder:
            return HTTPMethod.get.rawValue
        case .updateOrderStatus:
            return HTTPMethod.patch.rawValue
        }
    }
    
    var parameters: [String: Any]? {
        switch self {
        case .createOrder(let order):
            let encoder = JSONEncoder()
            if let data = try? encoder.encode(order),
               let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                return dict
            }
            return nil
        case .updateOrderStatus(_, let status):
            return ["status": status]
        default:
            return nil
        }
    }
    
    var requiresAuthentication: Bool {
        return true
    }
} 