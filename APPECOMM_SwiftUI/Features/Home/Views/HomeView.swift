//
//  HomeView.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 20/3/25.
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel
    @State private var showingSearchBar = false
    
    var body: some View {
        NavigationView {
            ZStack {
                ScrollView {
                    VStack(spacing: 16) {
                        // Banner / Promotion section
                        PromotionBannerView()
                        
                        // Featured categories section
                        FeaturedCategoriesView(categories: viewModel.categories)
                        
                        // New arrivals
                        if !viewModel.newProducts.isEmpty {
                            ProductSection(
                                title: "New Arrivals",
                                subtitle: "Check out our latest products",
                                products: viewModel.newProducts,
                                viewModel: viewModel
                            )
                        }
                        
                        // Best sellers
                        if !viewModel.bestSellingProducts.isEmpty {
                            ProductSection(
                                title: "Best Sellers",
                                subtitle: "Our most popular products",
                                products: viewModel.bestSellingProducts,
                                viewModel: viewModel
                            )
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.bottom)
                }
                .refreshable {
                    viewModel.loadData()
                }
                
                // Loading overlay
                if viewModel.isLoading {
                    LoadingView()
                }
                
                // Error message
                if let errorMessage = viewModel.errorMessage {
                    ErrorToast(message: errorMessage) {
                        viewModel.errorMessage = nil
                    }
                }
            }
            .navigationTitle("Home")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingSearchBar.toggle()
                    }) {
                        Image(systemName: "magnifyingglass")
                    }
                }
            }
            .sheet(isPresented: $showingSearchBar) {
                SearchView(viewModel: DependencyInjector.shared.resolve(ProductListViewModel.self))
            }
        }
        .onAppear {
            if viewModel.newProducts.isEmpty || viewModel.bestSellingProducts.isEmpty {
                viewModel.loadData()
            }
        }
    }
}

// MARK: - Promotion Banner
struct PromotionBannerView: View {
    var body: some View {
        TabView {
            ForEach(0..<3) { index in
                ZStack(alignment: .bottomLeading) {
                    Rectangle()
                        .fill(Color.blue.opacity(0.8 - Double(index) * 0.2))
                        .cornerRadius(12)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(promotions[index].title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text(promotions[index].subtitle)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                        
                        Button(action: {
                            // Action for the promotion
                        }) {
                            Text("Shop Now")
                                .fontWeight(.semibold)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.white)
                                .foregroundColor(.blue)
                                .cornerRadius(20)
                        }
                        .padding(.top, 8)
                    }
                    .padding(20)
                }
                .frame(height: 180)
                .padding(.horizontal)
            }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
        .frame(height: 200)
    }
    
    private let promotions = [
        (title: "Spring Collection", subtitle: "Discover our new arrivals for the season"),
        (title: "Limited Time Offer", subtitle: "Get 20% off on selected items"),
        (title: "Free Shipping", subtitle: "On all orders over $50")
    ]
}

// MARK: - Featured Categories
struct FeaturedCategoriesView: View {
    let categories: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Featured Categories")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(Array(categories.prefix(6)), id: \.self) { category in
                        NavigationLink(destination:
                                        ProductListView(viewModel: DependencyInjector.shared.resolve(ProductListViewModel.self))
                            .onAppear {
                                // Set the filter for this category
                                DependencyInjector.shared.resolve(ProductListViewModel.self).selectedCategory = category
                            }
                        ) {
                            CategoryItemView(name: category)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.top, 8)
    }
}

struct CategoryItemView: View {
    let name: String
    
    var body: some View {
        VStack {
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 70, height: 70)
                
                // Use SF Symbol based on category name
                Image(systemName: symbolForCategory(name))
                    .font(.system(size: 30))
                    .foregroundColor(.blue)
            }
            
            Text(name)
                .font(.caption)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .foregroundColor(.primary)
        }
        .frame(width: 80)
    }
    
    private func symbolForCategory(_ category: String) -> String {
        switch category.lowercased() {
        case let name where name.contains("dragon ball"):
            return "sparkles"
        case let name where name.contains("one piece"):
            return "flag.fill"
        case let name where name.contains("naruto"):
            return "hurricane"
        case let name where name.contains("demon slayer"):
            return "bolt.fill"
        case let name where name.contains("jujutsu"):
            return "eye.fill"
        case let name where name.contains("bleach"):
            return "flame.fill"
        case let name where name.contains("chainsaw"):
            return "scissors"
        case let name where name.contains("spy"):
            return "person.fill.questionmark"
        case let name where name.contains("attack"):
            return "shield.fill"
        case let name where name.contains("punch"):
            return "hand.raised.fill"
        default:
            return "star.fill"
        }
    }
}

// MARK: - Product Section
struct ProductSection: View {
    let title: String
    let subtitle: String
    let products: [Product]
    let viewModel: HomeViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                NavigationLink(destination:
                                ProductListView(viewModel: DependencyInjector.shared.resolve(ProductListViewModel.self))
                ) {
                    Text("See All")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(products) { product in
                        NavigationLink(destination:
                                        ProductDetailView(
                                            product: product,
                                            viewModel: DependencyInjector.shared.resolve(ProductListViewModel.self)
                                        )
                        ) {
                            ProductCardView(product: product, viewModel: viewModel)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.top, 16)
    }
}

struct ProductCardView: View {
    let product: Product
    let viewModel: HomeViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Product Image
            ZStack(alignment: .topTrailing) {
                if let images = product.images, !images.isEmpty, let imageUrl = URL(string: images[0].downloadUrl) {
                    AsyncImage(url: imageUrl) { phase in
                        switch phase {
                        case .empty:
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .aspectRatio(1, contentMode: .fit)
                                .overlay(
                                    ProgressView()
                                )
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 150, height: 150)
                                .clipped()
                        case .failure:
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .aspectRatio(1, contentMode: .fit)
                                .overlay(
                                    Image(systemName: "photo")
                                        .font(.largeTitle)
                                        .foregroundColor(.gray)
                                )
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(width: 150, height: 150)
                    .cornerRadius(10)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 150, height: 150)
                        .cornerRadius(10)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                        )
                }
                
                if product.discountPercentage > 0 {
                    Text("-\(product.discountPercentage)%")
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .padding(8)
                }
            }
            
            // Product Info
            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .foregroundColor(.primary)
                
                Text(product.brand)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // Price
                if product.discountPercentage > 0 {
                    HStack(spacing: 4) {
                        Text(formattedPrice(product.price))
                            .font(.caption)
                            .strikethrough()
                            .foregroundColor(.secondary)
                        
                        Text(formattedDiscountedPrice(product))
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                } else {
                    Text(formattedPrice(product.price))
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                // Status indicator
                HStack {
                    Circle()
                        .fill(product.status == .inStock ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                    
                    Text(product.status == .inStock ? "In Stock" : "Out of Stock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 150)
        }
        .frame(width: 150)
        .padding(.bottom, 8)
    }
    
    private func formattedPrice(_ price: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        return formatter.string(from: price as NSDecimalNumber) ?? "$\(price)"
    }
    
    private func formattedDiscountedPrice(_ product: Product) -> String {
        let discount = product.price * Decimal(product.discountPercentage) / 100
        let discountedPrice = (product.price - discount).rounded(2)
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        return formatter.string(from: discountedPrice as NSDecimalNumber) ?? "$\(discountedPrice)"
    }
}

// MARK: - Search View
struct SearchView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: ProductListViewModel
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            VStack {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search products", text: $searchText)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding()
                
                // Results
                if searchText.isEmpty {
                    SuggestedSearchesView(onSelect: { suggestion in
                        searchText = suggestion
                    })
                } else {
                    // Filter products based on search text
                    let filteredProducts = viewModel.products.filter {
                        $0.name.localizedCaseInsensitiveContains(searchText) ||
                        $0.brand.localizedCaseInsensitiveContains(searchText) ||
                        $0.description?.localizedCaseInsensitiveContains(searchText) ?? false
                    }
                    
                    if filteredProducts.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 48))
                                .foregroundColor(.gray)
                            
                            Text("No results found for '\(searchText)'")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxHeight: .infinity)
                    } else {
                        List {
                            ForEach(filteredProducts) { product in
                                NavigationLink(destination:
                                                ProductDetailView(product: product, viewModel: viewModel)
                                    .onAppear {
                                        presentationMode.wrappedValue.dismiss()
                                    }
                                ) {
                                    HStack {
                                        // Thumbnail
                                        if let images = product.images, !images.isEmpty, let imageUrl = URL(string: images[0].downloadUrl) {
                                            AsyncImage(url: imageUrl) { phase in
                                                switch phase {
                                                case .empty:
                                                    Color.gray.opacity(0.3)
                                                case .success(let image):
                                                    image
                                                        .resizable()
                                                        .aspectRatio(contentMode: .fill)
                                                case .failure:
                                                    Image(systemName: "photo")
                                                        .foregroundColor(.gray)
                                                @unknown default:
                                                    EmptyView()
                                                }
                                            }
                                            .frame(width: 50, height: 50)
                                            .cornerRadius(6)
                                        } else {
                                            Rectangle()
                                                .fill(Color.gray.opacity(0.3))
                                                .frame(width: 50, height: 50)
                                                .cornerRadius(6)
                                                .overlay(
                                                    Image(systemName: "photo")
                                                        .foregroundColor(.gray)
                                                )
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(product.name)
                                                .font(.subheadline)
                                                .lineLimit(1)
                                            
                                            Text(product.brand)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                            }
                        }
                        .listStyle(PlainListStyle())
                    }
                }
                
                Spacer()
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark")
                    }
                }
            }
            .onAppear {
                if viewModel.products.isEmpty {
                    viewModel.loadProducts()
                }
            }
        }
    }
}

struct SuggestedSearchesView: View {
    let onSelect: (String) -> Void
    
    let suggestions = [
        "Dragon Ball",
        "One Piece",
        "Naruto",
        "Demon Slayer",
        "Jujutsu Kaisen",
        "Bleach",
        "Chainsaw Man"
    ]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Suggested Searches")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(suggestions, id: \.self) { suggestion in
                        Button(action: {
                            onSelect(suggestion)
                        }) {
                            Text(suggestion)
                                .font(.subheadline)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(Color(.systemGray6))
                                .cornerRadius(20)
                                .foregroundColor(.primary)
                        }
                    }
                }
                .padding()
            }
            
            Spacer()
        }
        .padding(.top)
    }
}
