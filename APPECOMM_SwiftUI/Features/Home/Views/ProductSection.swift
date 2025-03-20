import SwiftUI

struct ProductSection: View {
    let title: String
    let subtitle: String
    let products: [Product]
    let viewModel: HomeViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: title, subtitle: subtitle)
            
            ProductScrollView(products: products, viewModel: viewModel)
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
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(products) { product in
                    NavigationLink(destination: ProductDetailView(product: product, viewModel: viewModel.productListViewModel)) {
                        ProductCardView(product: product, viewModel: viewModel)
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ProductImage(imageUrl: product.images?.first?.downloadUrl)
            
            ProductInfo(product: product, viewModel: viewModel)
        }
        .frame(width: 160)
    }
}

private struct ProductImage: View {
    let imageUrl: String?
    
    var body: some View {
        if let imageUrl = imageUrl, let url = URL(string: imageUrl) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    Image(systemName: "photo")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                @unknown default:
                    Color.gray
                }
            }
            .frame(width: 160, height: 160)
            .clipped()
            .cornerRadius(8)
        } else {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 160, height: 160)
                .cornerRadius(8)
                .overlay(
                    Image(systemName: "photo")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                )
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
            Text(viewModel.formattedPrice(product.price))
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
        Text(viewModel.formattedPrice(product.price))
            .fontWeight(.bold)
    }
} 