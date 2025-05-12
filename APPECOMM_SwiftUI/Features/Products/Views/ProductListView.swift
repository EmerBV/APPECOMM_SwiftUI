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
    
    // For option selection sheets
    @State private var showSortOptions = false
    @State private var showAvailabilityOptions = false
    @State private var showCategoryOptions = false
    @State private var showBrandOptions = false
    
    // Ensure we load the brands when the view appears
    var body: some View {
        NavigationView {
            Form {
                // Sort By Section
                Section {
                    Button(action: {
                        showSortOptions = true
                    }) {
                        HStack {
                            Text("sort_by".localized)
                            Spacer()
                            Text(filter.sortBy?.displayName ?? "newest".localized)
                                .foregroundColor(.secondary)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
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
                    Button(action: {
                        showAvailabilityOptions = true
                    }) {
                        HStack {
                            Text("availability_label".localized)
                            Spacer()
                            Text(filter.availability?.displayName ?? "all".localized)
                                .foregroundColor(.secondary)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Category Section
                if !viewModel.categories.isEmpty {
                    Section {
                        Button(action: {
                            showCategoryOptions = true
                        }) {
                            HStack {
                                Text("category_filter_label".localized)
                                Spacer()
                                Text(filter.selectedCategory ?? "all_categories".localized)
                                    .foregroundColor(.secondary)
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                // Brand Section
                if !viewModel.brands.isEmpty {
                    Section {
                        Button(action: {
                            showBrandOptions = true
                        }) {
                            HStack {
                                Text("brands_filter_label".localized)
                                Spacer()
                                Text(filter.selectedBrand ?? "all_brands".localized)
                                    .foregroundColor(.secondary)
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
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
            .sheet(isPresented: $showSortOptions) {
                OptionSelectionView(
                    title: "sort_by".localized,
                    options: ProductSortOption.allCases.map { OptionItem(id: $0.rawValue, title: $0.displayName) },
                    selectedId: filter.sortBy?.rawValue,
                    onSelect: { optionId in
                        if let selectedOption = ProductSortOption.allCases.first(where: { $0.rawValue == optionId }) {
                            filter.sortBy = selectedOption
                        }
                        showSortOptions = false
                    }
                )
            }
            .sheet(isPresented: $showAvailabilityOptions) {
                OptionSelectionView(
                    title: "availability_label".localized,
                    options: [OptionItem(id: "all", title: "all".localized)] +
                    ProductStatus.allCases.map { OptionItem(id: $0.rawValue, title: $0.displayName) },
                    selectedId: filter.availability?.rawValue ?? "all",
                    onSelect: { optionId in
                        if optionId == "all" {
                            filter.availability = nil
                        } else if let status = ProductStatus.allCases.first(where: { $0.rawValue == optionId }) {
                            filter.availability = status
                        }
                        showAvailabilityOptions = false
                    }
                )
            }
            .sheet(isPresented: $showCategoryOptions) {
                OptionSelectionView(
                    title: "category_filter_label".localized,
                    options: [OptionItem(id: "all", title: "all_categories".localized)] +
                    viewModel.categories.map { OptionItem(id: $0, title: $0) },
                    selectedId: filter.selectedCategory ?? "all",
                    onSelect: { optionId in
                        if optionId == "all" {
                            filter.selectedCategory = nil
                        } else {
                            filter.selectedCategory = optionId
                        }
                        showCategoryOptions = false
                    }
                )
            }
            .sheet(isPresented: $showBrandOptions) {
                OptionSelectionView(
                    title: "brands_filter_label".localized,
                    options: [OptionItem(id: "all", title: "all_brands".localized)] +
                    viewModel.brands.map { OptionItem(id: $0, title: $0) },
                    selectedId: filter.selectedBrand ?? "all",
                    onSelect: { optionId in
                        if optionId == "all" {
                            filter.selectedBrand = nil
                        } else {
                            filter.selectedBrand = optionId
                        }
                        showBrandOptions = false
                    }
                )
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

