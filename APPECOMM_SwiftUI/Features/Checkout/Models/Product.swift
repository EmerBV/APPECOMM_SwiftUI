struct Product: Codable, Identifiable {
    let id: Int
    let name: String
    let description: String
    let price: Double
    let imageUrl: String
    let category: String
    let brand: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case price
        case imageUrl = "image_url"
        case category
        case brand
    }
} 