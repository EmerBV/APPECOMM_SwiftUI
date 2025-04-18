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
                ProductImageView(
                    size: 160,
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
