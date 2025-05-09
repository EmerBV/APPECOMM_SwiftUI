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
                        selectedCategory: $viewModel.filter.selectedCategory,
                        categories: viewModel.categories,
                        viewModel: viewModel
                    )
                    
                    if viewModel.filteredProducts.isEmpty {
                        EmptyStateView(
                            hasFilters: viewModel.hasActiveFilters || viewModel.filter.hasActiveFilters,
                            onClearFilters: {
                                viewModel.temporaryFilter.reset()
                                viewModel.applyFilter()
                                viewModel.clearFilters()
                            }
                        )
                    } else {
                        ProductList(
                            products: viewModel.filteredProducts,
                            viewModel: viewModel
                        )
                        .refreshable {
                            await viewModel.loadProductsWithFilter(forceRefresh: true)
                        }
                    }
                }
                
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
                    RefreshButton(action: {
                        viewModel.loadProductsWithFilter(forceRefresh: true)
                    })
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
                await viewModel.loadProductsWithFilter()
            }
        }
    }
}

// MARK: - Search and Filter Components
private struct SearchAndFilterBar: View {
    @Binding var searchText: String
    @Binding var selectedCategory: String?
    let categories: [String]
    @ObservedObject var viewModel: ProductListViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                SearchBarView(text: $searchText)
                
                // Filter button
                Button(action: {
                    viewModel.showFilterSheet()
                }) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(viewModel.filter.hasActiveFilters ? .blue : .primary)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                .accessibilityLabel("filter_products".localized)
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 12)
            
            CategoryFilterScrollView(
                selectedCategory: $selectedCategory,
                categories: categories
            )
            
            // Active filters indicators
            if viewModel.filter.hasActiveFilters {
                ActiveFiltersView(viewModel: viewModel)
            }
            
            Divider()
        }
        .background(Color(.systemBackground))
        .sheet(isPresented: $viewModel.isFilterSheetPresented) {
            FilterSheetView(
                viewModel: viewModel,
                filter: $viewModel.temporaryFilter
            )
        }
    }
}

private struct ActiveFiltersView: View {
    @ObservedObject var viewModel: ProductListViewModel
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Sort filter chip
                if let sortBy = viewModel.filter.sortBy {
                    FilterChip(
                        text: sortBy.displayName,
                        action: {
                            viewModel.temporaryFilter.sortBy = .newest
                            viewModel.applyFilter()
                        }
                    )
                }
                
                // Price range filter chip
                if viewModel.filter.minPrice != nil || viewModel.filter.maxPrice != nil {
                    let priceText = formatPriceRange(
                        min: viewModel.filter.minPrice,
                        max: viewModel.filter.maxPrice
                    )
                    FilterChip(
                        text: priceText,
                        action: {
                            viewModel.temporaryFilter.minPrice = nil
                            viewModel.temporaryFilter.maxPrice = nil
                            viewModel.applyFilter()
                        }
                    )
                }
                
                // Availability filter chip
                if let availability = viewModel.filter.availability {
                    FilterChip(
                        text: availability.displayName,
                        action: {
                            viewModel.temporaryFilter.availability = nil
                            viewModel.applyFilter()
                        }
                    )
                }
                
                // Category filter chip
                if let category = viewModel.filter.selectedCategory {
                    FilterChip(
                        text: category,
                        action: {
                            viewModel.temporaryFilter.selectedCategory = nil
                            viewModel.applyFilter()
                        }
                    )
                }
                
                // Brand filter chip
                if let brand = viewModel.filter.selectedBrand {
                    FilterChip(
                        text: brand,
                        action: {
                            viewModel.temporaryFilter.selectedBrand = nil
                            viewModel.applyFilter()
                        }
                    )
                }
                
                // Clear all filters button
                Button(action: {
                    viewModel.temporaryFilter.reset()
                    viewModel.applyFilter()
                }) {
                    Text("clear_filters".localized)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(16)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
    
    private func formatPriceRange(min: Decimal?, max: Decimal?) -> String {
        if let min = min, let max = max {
            return "\(min.toCurrentLocalePrice) - \(max.toCurrentLocalePrice)"
        } else if let min = min {
            return "≥ \(min.toCurrentLocalePrice)"
        } else if let max = max {
            return "≤ \(max.toCurrentLocalePrice)"
        }
        return ""
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

private struct FilterSheetView: View {
    @ObservedObject var viewModel: ProductListViewModel
    @Binding var filter: ProductFilter
    @Environment(\.dismiss) private var dismiss
    
    // For price range slider
    @State private var minPrice: Double = 0
    @State private var maxPrice: Double = 1000
    @State private var priceFilterEnabled = false
    
    // Ensure we load the brands when the view appears
    var body: some View {
        NavigationView {
            Form {
                // Sort By Section
                Section {
                    Picker("sort_by".localized, selection: $filter.sortBy) {
                        ForEach(ProductSortOption.allCases) { option in
                            Text(option.displayName).tag(option as ProductSortOption?)
                        }
                    }
                    .pickerStyle(DefaultPickerStyle())
                }
                
                // Price Range Section
                Section {
                    Toggle("enable_price_filter".localized, isOn: $priceFilterEnabled)
                        .onChange(of: priceFilterEnabled) { newValue in
                            if !newValue {
                                filter.minPrice = nil
                                filter.maxPrice = nil
                            } else {
                                filter.minPrice = Decimal(minPrice)
                                filter.maxPrice = Decimal(maxPrice)
                            }
                        }
                    
                    if priceFilterEnabled {
                        HStack {
                            Text("\(minPrice, specifier: "%.0f")")
                            Slider(value: $minPrice, in: 0...maxPrice)
                                .onChange(of: minPrice) { newValue in
                                    filter.minPrice = Decimal(newValue)
                                }
                            Text("\(Decimal(minPrice).toCurrentLocalePrice)")
                        }
                        
                        HStack {
                            Text("\(maxPrice, specifier: "%.0f")")
                            Slider(value: $maxPrice, in: minPrice...5000)
                                .onChange(of: maxPrice) { newValue in
                                    filter.maxPrice = Decimal(newValue)
                                }
                            Text("\(Decimal(maxPrice).toCurrentLocalePrice)")
                        }
                    }
                }
                
                // Availability Section
                Section {
                    Picker("availability_label".localized, selection: $filter.availability) {
                        Text("all".localized).tag(nil as ProductStatus?)
                        ForEach(ProductStatus.allCases, id: \.self) { status in
                            Text(status.displayName).tag(status as ProductStatus?)
                        }
                    }
                    .pickerStyle(DefaultPickerStyle())
                }
                
                // Category Section
                if !viewModel.categories.isEmpty {
                    Section {
                        Picker("category_filter_label".localized, selection: $filter.selectedCategory) {
                            Text("all_categories".localized).tag(nil as String?)
                            ForEach(viewModel.categories, id: \.self) { category in
                                Text(category).tag(category as String?)
                            }
                        }
                        .pickerStyle(DefaultPickerStyle())
                    }
                }
                
                // Brand Section
                if !viewModel.brands.isEmpty {
                    Section {
                        Picker("brands_filter_label".localized, selection: $filter.selectedBrand) {
                            Text("all_brands".localized).tag(nil as String?)
                            ForEach(viewModel.brands, id: \.self) { brand in
                                Text(brand).tag(brand as String?)
                            }
                        }
                        .pickerStyle(DefaultPickerStyle())
                    }
                }
            }
            .navigationTitle("filter_products".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("reset_label".localized) {
                        viewModel.resetFilter()
                        priceFilterEnabled = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("apply_label".localized) {
                        viewModel.applyFilter()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                // Initialize price filter UI based on existing filter values
                if let minP = filter.minPrice {
                    minPrice = Double(truncating: minP as NSDecimalNumber)
                    priceFilterEnabled = true
                }
                
                if let maxP = filter.maxPrice {
                    maxPrice = Double(truncating: maxP as NSDecimalNumber)
                    priceFilterEnabled = true
                }
                
                // Load brands if needed
                viewModel.loadBrands()
            }
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

