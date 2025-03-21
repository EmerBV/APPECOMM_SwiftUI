import SwiftUI

struct SearchView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ProductListViewModel
    @State private var searchText = ""
    
    private let columns = [
        GridItem(.fixed(160), spacing: 16),
        GridItem(.fixed(160), spacing: 16)
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search products", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
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
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.filteredProducts.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 64))
                            .foregroundColor(.gray)
                        
                        Text("No products found")
                            .font(.headline)
                        
                        if !searchText.isEmpty {
                            Text("Try different keywords")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(viewModel.filteredProducts) { product in
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
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .onChange(of: searchText) { newValue in
            viewModel.searchText = newValue
        }
    }
} 