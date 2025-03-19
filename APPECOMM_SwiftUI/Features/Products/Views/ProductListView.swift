//
//  ProductListView.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 18/3/25.
//

import SwiftUI

struct ProductListView: View {
    @ObservedObject var viewModel: ProductListViewModel
    @State private var showingCategoryFilter = false
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Search and filter bar
                VStack(spacing: 0) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        
                        TextField("Search products", text: $viewModel.searchText)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                        
                        if !viewModel.searchText.isEmpty {
                            Button(action: {
                                viewModel.searchText = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    
                    // Category filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            // All products filter
                            CategoryFilterItem(
                                name: "All",
                                isSelected: viewModel.selectedCategory == nil,
                                action: {
                                    viewModel.selectedCategory = nil
                                }
                            )
                            
                            // Individual category filters
                            ForEach(viewModel.categories, id: \.self) { category in
                                CategoryFilterItem(
                                    name: category,
                                    isSelected: viewModel.selectedCategory == category,
                                    action: {
                                        viewModel.selectedCategory = category
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                    }
                    
                    Divider()
                }
                
                // Product list
                if viewModel.filteredProducts.isEmpty && !viewModel.isLoading {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.magnifyingglass")
                            .font(.system(size: 64))
                            .foregroundColor(.gray)
                        
                        Text("No products found")
                            .font(.headline)
                        
                        if viewModel.selectedCategory != nil || !viewModel.searchText.isEmpty {
                            Button(action: {
                                viewModel.selectedCategory = nil
                                viewModel.searchText = ""
                            }) {
                                Text("Clear filters")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground))
                } else {
                    List {
                        ForEach(viewModel.filteredProducts) { product in
                            NavigationLink(destination: ProductDetailView(product: product, viewModel: viewModel)) {
                                ProductRowView(product: product, viewModel: viewModel)
                            }
                            .listRowSeparator(.hidden)
                        }
                    }
                    .listStyle(PlainListStyle())
                    .refreshable {
                        viewModel.loadProducts()
                    }
                }
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
        .navigationTitle("Products")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    viewModel.loadProducts()
                }) {
                    Image(systemName: "arrow.clockwise")
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

struct CategoryFilterItem: View {
    let name: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(name)
                .font(.subheadline)
                .fontWeight(isSelected ? .bold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
                .foregroundColor(isSelected ? .blue : .primary)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isSelected ? Color.blue : Color.gray.opacity(0.5), lineWidth: 1)
                )
        }
    }
}

struct ProductRowView: View {
    let product: Product
    let viewModel: ProductListViewModel
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Product Image
            ZStack {
                if let images = product.images, !images.isEmpty, let imageUrl = URL(string: images[0].downloadUrl) {
                    AsyncImage(url: imageUrl) { phase in
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
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 80, height: 80)
                    .clipped()
                    .cornerRadius(8)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 80, height: 80)
                        .cornerRadius(8)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                        )
                }
                
                // Discount badge if applicable
                if product.discountPercentage > 0 {
                    VStack {
                        HStack {
                            Text("-\(product.discountPercentage)%")
                                .font(.caption)
                                .fontWeight(.bold)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(4)
                            
                            Spacer()
                        }
                        
                        Spacer()
                    }
                    .padding(4)
                }
            }
            .frame(width: 80, height: 80)
            
            // Product Information
            VStack(alignment: .leading, spacing: 8) {
                Text(product.name)
                    .font(.headline)
                    .lineLimit(2)
                
                Text(product.brand)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    // Price information
                    if product.discountPercentage > 0, let discountedPrice = viewModel.formattedDiscountedPrice(for: product) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(viewModel.formattedPrice(for: product))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .strikethrough()
                            
                            Text(discountedPrice)
                                .font(.headline)
                                .foregroundColor(.green)
                        }
                    } else {
                        Text(viewModel.formattedPrice(for: product))
                            .font(.headline)
                    }
                    
                    Spacer()
                    
                    // Status badge
                    StatusBadge(status: product.status)
                }
                
                // Inventory indicator
                InventoryIndicator(inventory: product.inventory)
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct InventoryIndicator: View {
    let inventory: Int
    
    private var inventoryLevel: InventoryLevel {
        if inventory <= 0 {
            return .none
        } else if inventory < 5 {
            return .low
        } else if inventory < 10 {
            return .medium
        } else {
            return .high
        }
    }
    
    private enum InventoryLevel {
        case none, low, medium, high
        
        var color: Color {
            switch self {
            case .none:
                return .red
            case .low:
                return .orange
            case .medium:
                return .yellow
            case .high:
                return .green
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Rectangle()
                    .fill(index < self.inventoryBars ? inventoryLevel.color : Color.gray.opacity(0.3))
                    .frame(height: 6)
                    .cornerRadius(3)
            }
            
            Text("\(inventory) in stock")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.leading, 4)
        }
        .frame(maxWidth: 150, alignment: .leading)
    }
    
    private var inventoryBars: Int {
        switch inventoryLevel {
        case .none: return 0
        case .low: return 1
        case .medium: return 2
        case .high: return 3
        }
    }
}
