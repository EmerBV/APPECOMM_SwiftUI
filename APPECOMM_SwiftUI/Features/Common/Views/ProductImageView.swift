import SwiftUI
import Kingfisher

struct ProductImageView: View {
    // MARK: - Properties
    let size: CGFloat
    let imageUrl: String?
    let baseURL: String
    let isOutOfStock: Bool?
    
    // MARK: - Customization Options
    private var cornerRadius: CGFloat = 8
    private var placeholderImage: String = "photo"
    private var outOfStockText: String = "Sin Stock"
    private var outOfStockOpacity: Double = 0.6
    private var fadeDuration: Double = 0.3
    
    // MARK: - Initializers
    init(
        size: CGFloat,
        imageUrl: String?,
        baseURL: String,
        isOutOfStock: Bool? = nil,
        cornerRadius: CGFloat? = nil,
        placeholderImage: String? = nil,
        outOfStockText: String? = nil,
        outOfStockOpacity: Double? = nil,
        fadeDuration: Double? = nil
    ) {
        self.size = size
        self.imageUrl = imageUrl
        self.baseURL = baseURL
        self.isOutOfStock = isOutOfStock
        
        if let cornerRadius = cornerRadius { self.cornerRadius = cornerRadius }
        if let placeholderImage = placeholderImage { self.placeholderImage = placeholderImage }
        if let outOfStockText = outOfStockText { self.outOfStockText = outOfStockText }
        if let outOfStockOpacity = outOfStockOpacity { self.outOfStockOpacity = outOfStockOpacity }
        if let fadeDuration = fadeDuration { self.fadeDuration = fadeDuration }
    }
    
    // MARK: - Body
    var body: some View {
        if let imageUrl = imageUrl {
            let fullImageURL = "\(baseURL)\(imageUrl)"
            if let url = URL(string: fullImageURL) {
                ZStack {
                    KFImage(url)
                        .placeholder {
                            ProgressView()
                        }
                        .onFailure { error in
                            Logger.error("Error al cargar imagen: \(error.localizedDescription)")
                        }
                        .fade(duration: fadeDuration)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: size, height: size)
                        .clipped()
                        .cornerRadius(cornerRadius)
                    
                    if isOutOfStock == true {
                        Color.black.opacity(outOfStockOpacity)
                            .cornerRadius(cornerRadius)
                        
                        Text(outOfStockText)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 1)
                    }
                }
            } else {
                placeholderView
            }
        } else {
            placeholderView
        }
    }
    
    // MARK: - Helper Views
    private var placeholderView: some View {
        Image(systemName: placeholderImage)
            .font(.largeTitle)
            .foregroundColor(.gray)
            .frame(width: size, height: size)
            .background(Color.gray.opacity(0.3))
            .cornerRadius(cornerRadius)
    }
}

