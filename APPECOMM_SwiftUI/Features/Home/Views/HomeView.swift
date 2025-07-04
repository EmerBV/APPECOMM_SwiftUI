//
//  HomeView.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 20/3/25.
//

import SwiftUI

// MARK: - HomeView
struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel
    @State private var isSearchPresented = false
    
    init(viewModel: HomeViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        NavigationStack {
            HomeContentView(viewModel: viewModel)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Image("logo")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 30)
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        SearchButton(isSearchPresented: $isSearchPresented)
                    }
                }
                .sheet(isPresented: $isSearchPresented) {
                    SearchView(viewModel: DependencyInjector.shared.resolve(ProductListViewModel.self))
                }
        }
        .task {
            await viewModel.loadInitialDataIfNeeded()
        }
    }
}

// MARK: - HomeContentView
private struct HomeContentView: View {
    @ObservedObject var viewModel: HomeViewModel
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 16) {
                PromotionBannerView()
                    .padding(.top)
                
                CategoriesSection(
                    categories: viewModel.categories,
                    isLoading: viewModel.isLoading
                )
                
                if !viewModel.newProducts.isEmpty {
                    ProductSection(
                        title: "new_arrivals".localized,
                        subtitle: "new_arrivals_subtitle".localized,
                        products: viewModel.newProducts,
                        viewModel: viewModel
                    )
                }
                
                if !viewModel.bestSellingProducts.isEmpty {
                    ProductSection(
                        title: "best_sellers".localized,
                        subtitle: "best_sellers_subtitle".localized,
                        products: viewModel.bestSellingProducts,
                        viewModel: viewModel
                    )
                }
                
                Divider()
                    .padding(.vertical)
                
                WhyShopSection()
                
                Divider()
                    .padding(.vertical)
                
                ConnectSection()
                
                Spacer(minLength: 40)
            }
        }
        .refreshable {
            await viewModel.loadData()
        }
        
        /*
         .overlay {
         if viewModel.isLoading {
         LoadingView()
         }
         }
         */
        
        .circularLoading(
            isLoading: viewModel.isLoading,
            message: "loading".localized,
            strokeColor: .blue,
            backgroundColor: .gray.opacity(0.1),
            showBackdrop: true,
            containerSize: 80,
            logoSize: 50
        )
        
        .overlay {
            if let error = viewModel.errorMessage {
                ErrorToast(message: error) {
                    viewModel.dismissError()
                }
            }
        }
    }
}

// MARK: - Search Button
private struct SearchButton: View {
    @Binding var isSearchPresented: Bool
    
    var body: some View {
        Button {
            isSearchPresented.toggle()
        } label: {
            Image(systemName: "magnifyingglass")
                .imageScale(.large)
                .accessibilityLabel("search".localized)
        }
    }
}

// MARK: - Categories Section
private struct CategoriesSection: View {
    let categories: [Category]
    let isLoading: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("featured_categories".localized)
                .font(.title3)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 20) {
                    if isLoading {
                        ForEach(0..<6, id: \.self) { _ in
                            CategoryPlaceholderView()
                        }
                    } else {
                        ForEach(categories.prefix(6)) { category in
                            NavigationLink(destination: makeCategoryDestination(for: category.name)) {
                                CategoryItemView(category: category)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
        }
        .padding(.top, 8)
    }
    
    private func makeCategoryDestination(for category: String) -> some View {
        let viewModel = DependencyInjector.shared.resolve(ProductListViewModel.self)
        return ProductListView(viewModel: viewModel)
            .onAppear {
                viewModel.selectedCategory = category
            }
    }
}

