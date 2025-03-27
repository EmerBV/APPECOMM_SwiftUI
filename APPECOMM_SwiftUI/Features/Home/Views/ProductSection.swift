import SwiftUI
import Kingfisher

struct ProductSection: View {
    let title: String
    let subtitle: String
    let products: [Product]
    let viewModel: HomeViewModel
    
    private var baseURL: String {
        AppConfig.shared.imageBaseUrl
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: title, subtitle: subtitle)
            
            ProductScrollView(products: products, viewModel: viewModel, baseURL: baseURL)
        }
        .padding(.vertical, 8)
    }
}

private struct SectionHeader: View {
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
    }
}

private struct ProductScrollView: View {
    let products: [Product]
    let viewModel: HomeViewModel
    let baseURL: String
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(products) { product in
                    NavigationLink(destination: ProductDetailView(product: product, viewModel: viewModel.productListViewModel)) {
                        ProductCardView(product: product, viewModel: viewModel, baseURL: baseURL)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

private struct ProductCardView: View {
    let product: Product
    let viewModel: HomeViewModel
    let baseURL: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                ProductImage(
                    imageUrl: product.images?.first?.downloadUrl,
                    baseURL: baseURL,
                    isOutOfStock: product.status == .outOfStock
                )
                
                if product.preOrder {
                    StatusBadge.preOrder
                        .padding(8)
                }
            }
            
            ProductInfo(product: product, viewModel: viewModel)
        }
        .frame(width: 160)
    }
}

private struct ProductImage: View {
    let imageUrl: String?
    let baseURL: String
    let isOutOfStock: Bool
    
    var body: some View {
        if let imageUrl = imageUrl {
            let fullImageUrl = "\(baseURL)\(imageUrl)"
            if let url = URL(string: fullImageUrl) {
                ZStack {
                    KFImage(url)
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
                    
                    if isOutOfStock {
                        Color.black.opacity(0.6)
                        
                        Text("Sin Stock")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 1)
                    }
                }
                .cornerRadius(8)
            } else {
                Image(systemName: "photo")
                    .font(.largeTitle)
                    .foregroundColor(.gray)
                    .frame(width: 160, height: 160)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(8)
            }
        } else {
            Image(systemName: "photo")
                .font(.largeTitle)
                .foregroundColor(.gray)
                .frame(width: 160, height: 160)
                .background(Color.gray.opacity(0.3))
                .cornerRadius(8)
        }
    }
}

private struct ProductInfo: View {
    let product: Product
    let viewModel: HomeViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ProductName(name: product.name)
            ProductBrand(brand: product.brand)
            ProductPrice(product: product, viewModel: viewModel)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 8)
    }
}

private struct ProductName: View {
    let name: String
    
    var body: some View {
        Text(name)
            .font(.headline)
            .lineLimit(2)
            .multilineTextAlignment(.leading)
    }
}

private struct ProductBrand: View {
    let brand: String
    
    var body: some View {
        Text(brand)
            .font(.subheadline)
            .foregroundColor(.secondary)
            .lineLimit(1)
    }
}

private struct ProductPrice: View {
    let product: Product
    let viewModel: HomeViewModel
    
    var body: some View {
        if product.discountPercentage > 0 {
            DiscountedPrice(product: product, viewModel: viewModel)
        } else {
            RegularPrice(product: product, viewModel: viewModel)
        }
    }
}

private struct DiscountedPrice: View {
    let product: Product
    let viewModel: HomeViewModel
    
    var body: some View {
        HStack {
            Text(product.price.toCurrentLocalePrice)
                .strikethrough()
                .foregroundColor(.secondary)
            
            Text(viewModel.formattedDiscountedPrice(for: product))
                .fontWeight(.bold)
                .foregroundColor(.green)
        }
    }
}

private struct RegularPrice: View {
    let product: Product
    let viewModel: HomeViewModel
    
    var body: some View {
        Text(product.price.toCurrentLocalePrice)
            .fontWeight(.bold)
    }
} 
