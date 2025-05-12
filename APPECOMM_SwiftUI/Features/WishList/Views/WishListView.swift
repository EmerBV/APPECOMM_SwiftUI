//
//  WishListView.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 24/4/25.
//

import SwiftUI
import Kingfisher

struct WishListView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject var viewModel: WishListViewModel
    
    private var baseURL: String {
        AppConfig.shared.imageBaseUrl
    }
    
    var body: some View {
        ZStack {
            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.5)
            } else if viewModel.isEmpty {
                EmptyWishListView()
            } else {
                wishListContent
            }
            
            if let errorMessage = viewModel.errorMessage {
                ErrorToast(message: errorMessage) {
                    viewModel.clearErrorMessage()
                }
            }
        }
        .navigationTitle("my_wishlist_title".localized)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "chevron.left")
                    //.foregroundColor(.blue)
                }
            }
        }
        .onAppear {
            viewModel.loadWishList()
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
    }
    
    private var wishListContent: some View {
        List {
            ForEach(viewModel.wishListItems) { product in
                NavigationLink(destination: ProductDetailView(
                    product: product,
                    viewModel: DependencyInjector.shared.resolve(ProductListViewModel.self)
                )) {
                    WishListItemRow(product: product, baseURL: baseURL)
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        viewModel.removeFromWishList(productId: product.id)
                    } label: {
                        Label("remove".localized, systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .refreshable {
            viewModel.loadWishList()
        }
    }
}

struct WishListItemRow: View {
    let product: Product
    let baseURL: String
    
    var body: some View {
        HStack(spacing: 16) {
            // Product Image
            if let images = product.images, !images.isEmpty,
               let imageUrl = images.first?.downloadUrl {
                KFImage(URL(string: "\(baseURL)\(imageUrl)"))
                    .placeholder {
                        Image(systemName: "photo")
                            .font(.system(size: 30))
                            .foregroundColor(.gray)
                            .frame(width: 80, height: 80)
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 80, height: 80)
                    .clipped()
                    .cornerRadius(8)
            } else {
                Image(systemName: "photo")
                    .font(.system(size: 30))
                    .foregroundColor(.gray)
                    .frame(width: 80, height: 80)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
            
            // Product Info
            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.headline)
                    .lineLimit(2)
                
                Text(product.brand)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(product.price.toCurrentLocalePrice)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                // Availability
                HStack {
                    Circle()
                        .fill(product.status == .inStock ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                    
                    Text(product.status == .inStock ? "in_stock".localized : "out_of_stock".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

struct EmptyWishListView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart.slash")
                .font(.system(size: 80))
                .foregroundColor(.gray)
            
            Text("wishlist_empty".localized)
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("wishlist_will_appear".localized)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: {
                // Navigate to product list
                if let window = UIApplication.shared.windows.first {
                    window.rootViewController?.dismiss(animated: true)
                }
                NotificationCenter.default.post(name: Notification.Name("NavigateToHomeTab"), object: nil)
            }) {
                Text("browse_products".localized)
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.top, 20)
        }
        .padding()
    }
}
