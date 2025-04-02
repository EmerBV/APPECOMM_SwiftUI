import Foundation

struct Address: Codable, Identifiable {
    let id: Int
    let userId: Int
    let street: String
    let city: String
    let state: String
    let postalCode: String
    let country: String
    let isDefault: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case street
        case city
        case state
        case postalCode = "postal_code"
        case country
        case isDefault = "is_default"
    }
} 