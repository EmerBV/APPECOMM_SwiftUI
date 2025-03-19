//
//  ProductListView.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 18/3/25.
//

import SwiftUI

struct ProductListView: View {
    @StateObject private var viewModel = ProductViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                // Lista de productos
                List {
                    ForEach(viewModel.products) { product in
                        NavigationLink(destination: ProductDetailView(product: product, viewModel: viewModel)) {
                            ProductRowView(product: product, viewModel: viewModel)
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
                .refreshable {
                    viewModel.loadProducts()
                }
                
                // Estado de carga
                if viewModel.isLoading {
                    LoadingView()
                }
                
                // Mensaje de error
                if let errorMessage = viewModel.errorMessage {
                    ErrorView(message: errorMessage) {
                        viewModel.loadProducts()
                    }
                }
            }
            .navigationTitle("Productos")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.loadProducts()
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
        .onAppear {
            viewModel.loadProducts()
        }
    }
}
