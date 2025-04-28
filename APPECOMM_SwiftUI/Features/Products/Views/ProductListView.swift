//
//  ProductListView.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 18/3/25.
//

import SwiftUI

struct ProductListView: View {
    @ObservedObject var viewModel: ProductListViewModel
    @State private var isShowingCategoryFilter = false
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    init(viewModel: ProductListViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack(spacing: 0) {
                    SearchAndFilterBar(
                        searchText: $viewModel.searchText,
                        selectedCategory: $viewModel.selectedCategory,
                        categories: viewModel.categories
                    )
                    
                    if viewModel.filteredProducts.isEmpty {
                        EmptyStateView(
                            hasFilters: viewModel.hasActiveFilters,
                            onClearFilters: viewModel.clearFilters
                        )
                    } else {
                        ProductList(
                            products: viewModel.filteredProducts,
                            viewModel: viewModel
                        )
                        .refreshable {
                            await viewModel.loadProducts(forceRefresh: true)
                        }
                    }
                }
                
                /*
                 if viewModel.isLoading {
                 LoadingView()
                 }
                 */
                
                if let errorMessage = viewModel.errorMessage {
                    ErrorToast(message: errorMessage) {
                        viewModel.dismissError()
                    }
                }
            }
            .navigationTitle("products".localized)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    RefreshButton(action: { viewModel.loadProducts(forceRefresh: true) })
                }
            }
            
            .circularLoading(
                isLoading: viewModel.isLoading,
                message: "loading".localized,
                strokeColor: .blue,
                backgroundColor: .gray.opacity(0.1),
                showBackdrop: true,
                containerSize: 80,
                logoSize: 50
            )
            
            .task {
                await viewModel.loadProducts()
            }
        }
    }
}

// MARK: - Search and Filter Components
private struct SearchAndFilterBar: View {
    @Binding var searchText: String
    @Binding var selectedCategory: String?
    let categories: [String]
    
    var body: some View {
        VStack(spacing: 0) {
            SearchBar(text: $searchText)
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 12)
            
            CategoryFilterScrollView(
                selectedCategory: $selectedCategory,
                categories: categories
            )
            
            Divider()
        }
        .background(Color(.systemBackground))
    }
}

private struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("search_products".localized, text: $text)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
            
            if !text.isEmpty {
                ClearButton(text: $text)
            }
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

private struct ClearButton: View {
    @Binding var text: String
    
    var body: some View {
        Button(action: { text = "" }) {
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(.secondary)
                .accessibilityLabel("clear_search".localized)
        }
    }
}

private struct CategoryFilterScrollView: View {
    @Binding var selectedCategory: String?
    let categories: [String]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                CategoryFilterItem(
                    name: "all".localized,
                    isSelected: selectedCategory == nil
                ) {
                    selectedCategory = nil
                }
                
                ForEach(categories, id: \.self) { category in
                    CategoryFilterItem(
                        name: category,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
    }
}

// MARK: - Product List Components
private struct ProductList: View {
    let products: [Product]
    let viewModel: ProductListViewModel
    
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(products) { product in
                    NavigationLink(
                        destination: ProductDetailView(
                            product: product,
                            viewModel: viewModel
                        )
                    ) {
                        ProductRowView(
                            product: product,
                            viewModel: viewModel
                        )
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
    }
}

