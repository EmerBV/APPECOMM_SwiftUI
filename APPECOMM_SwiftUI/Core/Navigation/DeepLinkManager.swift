import Foundation

enum DeepLinkRoute: String {
    case product = "product"
    case category = "category"
    case cart = "cart"
    case profile = "profile"
    
    var path: String {
        return "/\(rawValue)"
    }
}

class DeepLinkManager {
    static let shared = DeepLinkManager()
    
    private init() {}
    
    func handleDeepLink(_ url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            Logger.error("Invalid deep link URL")
            return
        }
        
        let path = components.path
        let queryItems = components.queryItems ?? []
        
        switch path {
        case DeepLinkRoute.product.path:
            handleProductDeepLink(queryItems: queryItems)
        case DeepLinkRoute.category.path:
            handleCategoryDeepLink(queryItems: queryItems)
        case DeepLinkRoute.cart.path:
            handleCartDeepLink()
        case DeepLinkRoute.profile.path:
            handleProfileDeepLink()
        default:
            Logger.error("Unknown deep link route: \(path)")
        }
    }
    
    private func handleProductDeepLink(queryItems: [URLQueryItem]) {
        guard let productId = queryItems.first(where: { $0.name == "id" })?.value,
              let id = Int(productId) else {
            Logger.error("Invalid product ID in deep link")
            return
        }
        
        NotificationCenter.default.post(
            name: Notification.Name("NavigateToProduct"),
            object: nil,
            userInfo: ["productId": id]
        )
    }
    
    private func handleCategoryDeepLink(queryItems: [URLQueryItem]) {
        guard let categoryName = queryItems.first(where: { $0.name == "name" })?.value else {
            Logger.error("Invalid category name in deep link")
            return
        }
        
        NotificationCenter.default.post(
            name: Notification.Name("NavigateToCategory"),
            object: nil,
            userInfo: ["categoryName": categoryName]
        )
    }
    
    private func handleCartDeepLink() {
        NotificationCenter.default.post(name: Notification.Name("NavigateToCart"), object: nil)
    }
    
    private func handleProfileDeepLink() {
        NotificationCenter.default.post(name: Notification.Name("NavigateToProfile"), object: nil)
    }
} 