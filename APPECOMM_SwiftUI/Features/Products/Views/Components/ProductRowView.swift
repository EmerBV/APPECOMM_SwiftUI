import SwiftUI
import Kingfisher

struct ProductRowView: View {
    let product: Product
    let viewModel: ProductListViewModel
    
    private var baseURL: String {
        AppConfig.shared.imageBaseUrl
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Contenedor de imagen
            ZStack {
                // Imagen del producto
                if let firstImage = product.images?.first {
                    let fullImageUrl = "\(baseURL)\(firstImage.downloadUrl)"
                    
                    if let imageUrl = URL(string: fullImageUrl) {
                        KFImage(imageUrl)
                            .placeholder {
                                ProgressView()
                            }
                            .onFailure { error in
                                Logger.error("Error al cargar imagen: \(error.localizedDescription)")
                            }
                            .fade(duration: 0.3)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 160, height: 160)
                            .clipped()
                    } else {
                        Image(systemName: "photo")
                            .font(.system(size: 30))
                            .foregroundColor(.gray)
                            .frame(width: 160, height: 160)
                            .background(Color.gray.opacity(0.2))
                    }
                } else {
                    Image(systemName: "photo")
                        .font(.system(size: 30))
                        .foregroundColor(.gray)
                        .frame(width: 160, height: 160)
                        .background(Color.gray.opacity(0.2))
                }
                
                // Overlay para Sin Stock
                if product.status == .outOfStock {
                    Rectangle()
                        .fill(Color.black.opacity(0.6))
                        .frame(width: 160, height: 160)
                    
                    Text("Sin Stock")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 1)
                }
                
                // Badge de Pre-order
                if product.preOrder {
                    VStack {
                        HStack {
                            Spacer()
                            StatusBadge.preOrder
                                .padding(8)
                        }
                        Spacer()
                    }
                }
            }
            .frame(width: 160, height: 160)
            .cornerRadius(8)
            
            // Información del producto
            VStack(alignment: .leading, spacing: 8) {
                Text(product.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
                    .padding(.top, 4)
                
                if let discountedPrice = viewModel.formattedDiscountedPrice(for: product) {
                    Text(discountedPrice)
                        .font(.system(.body, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    
                    Text(viewModel.formattedPrice(for: product))
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.secondary)
                        .strikethrough()
                } else {
                    Text(viewModel.formattedPrice(for: product))
                        .font(.system(.body, design: .rounded))
                        .fontWeight(.bold)
                }
            }
            .padding(12)
        }
        .frame(width: 160)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
} 