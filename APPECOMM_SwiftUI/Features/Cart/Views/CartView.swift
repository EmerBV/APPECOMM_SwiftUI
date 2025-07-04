//
//  CartView.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 21/3/25.
//

import SwiftUI

struct CartView: View {
    @ObservedObject var viewModel: CartViewModel
    @State private var shouldShowClearCartAlert = false
    @State private var isShowingCheckout = false
    @ObservedObject private var navigationCoordinator = NavigationCoordinator.shared
    
    init(viewModel: CartViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                contentView
            }
            .navigationTitle("cart".localized)
            .toolbar {
                leadingToolbarItems
                trailingToolbarItems
            }
            .refreshable {
                await viewModel.refreshCart()
            }
            .alert("clear_cart".localized, isPresented: $shouldShowClearCartAlert) {
                Button("clear".localized, role: .destructive) {
                    Task {
                        await viewModel.clearCart()
                    }
                }
                Button("cancel".localized, role: .cancel) {}
            } message: {
                Text("clear_cart_confirmation".localized)
            }
            .fullScreenCover(isPresented: $isShowingCheckout) {
                // Navigate back to cart when checkout is dismissed
                Task {
                    await viewModel.refreshCart()
                }
            } content: {
                NavigationView {
                    CheckoutView(cart: viewModel.cart)
                }
            }
            .onChange(of: navigationCoordinator.showingCheckout) { showCheckout in
                if showCheckout {
                    isShowingCheckout = true
                    // Reset the coordinator's flag after we've handled it
                    DispatchQueue.main.async {
                        navigationCoordinator.showingCheckout = false
                    }
                }
            }
        }
        .task {
            if viewModel.isUserLoggedIn {
                await viewModel.refreshCart()
            }
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        if viewModel.isLoading {
            CircularLoadingView(
                message: "loading".localized,
                strokeColor: .blue,
                backgroundColor: .gray.opacity(0.1),
                showBackdrop: true,
                containerSize: 80,
                logoSize: 50
            )
        } else if let cart = viewModel.cart, !cart.items.isEmpty {
            CartContentView(cart: cart, viewModel: viewModel, isShowingCheckout: $isShowingCheckout)
        } else {
            EmptyCartView()
        }
    }
    
    private var leadingToolbarItems: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button {
                Task {
                    await viewModel.refreshCart()
                }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .accessibilityLabel("Refresh Cart")
            }
        }
    }
    
    private var trailingToolbarItems: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            if let cart = viewModel.cart, !cart.items.isEmpty {
                Button {
                    shouldShowClearCartAlert = true
                } label: {
                    Text("clear_all".localized)
                        .foregroundColor(.red)
                }
            }
        }
    }
}

// MARK: - Cart Content View
private struct CartContentView: View {
    let cart: Cart
    @ObservedObject var viewModel: CartViewModel
    @Binding var isShowingCheckout: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            cartItemsList
            
            OrderSummaryView(
                cart: cart,
                viewModel: viewModel
            )
            
            CheckoutButton(
                viewModel: viewModel,
                isShowingCheckout: $isShowingCheckout
            )
        }
    }
    
    private var cartItemsList: some View {
        List {
            ForEach(cart.items) { item in
                CartItemRow(
                    item: item,
                    formattedPrice: item.totalPrice.toCurrentLocalePrice,
                    onUpdateQuantity: { newQuantity in
                        Task {
                            await viewModel.updateItemQuantity(
                                itemId: item.itemId,
                                productId: item.product.id,
                                newQuantity: newQuantity
                            )
                        }
                    },
                    onRemove: {
                        Task {
                            await viewModel.removeItem(
                                itemId: item.itemId,
                                productId: item.product.id
                            )
                        }
                    }
                )
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
            }
        }
        .listStyle(.plain)
    }
}

// MARK: - Empty Cart View
private struct EmptyCartView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "cart")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
                .accessibilityHidden(true)
            
            Text("empty_cart".localized)
                .font(.title2.weight(.semibold))
            
            Text("empty_cart_message".localized)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            NavigationLink {
                ProductListView(viewModel: DependencyInjector.shared.resolve(ProductListViewModel.self))
            } label: {
                Label("browse_products".localized, systemImage: "bag")
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding(.top, 20)
        }
        .padding()
    }
}

// MARK: - Order Summary View
private struct OrderSummaryView: View {
    let cart: Cart
    let viewModel: CartViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            /*
            Divider()
                .padding(.bottom, 8)
            
            HStack {
                Text("order_summary".localized)
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal)
            
            summaryRow(title: "subtotal_label".localized, value: cart.totalAmount.toCurrentLocalePrice)
            
            //summaryRow(title: "shipping_label".localized, value: "shipping_calculated".localized, isSecondary: true)
            summaryRow(title: "tax_label".localized, value: "included_label".localized, isSecondary: true)
            summaryRow(title: "shipping_label".localized, value: "free_label".localized, isSecondary: true)
            
            Divider()
                .padding(.vertical, 8)
            
            summaryRow(
                title: "total_label".localized,
                value: cart.totalAmount.toCurrentLocalePrice,
                isBold: true
            )
             */
            
            // BLOQUE SOLO CON SUBTOTAL
            Divider()
                .padding(.bottom, 8)
            
            summaryRow(
                title: "subtotal_label".localized,
                value: cart.totalAmount.toCurrentLocalePrice,
                isBold: true
            )
            
            Divider()
                .padding(.top, 8)
        }
        .padding(.vertical)
        .background(Color(.systemBackground))
    }
    
    private func summaryRow(
        title: String,
        value: String,
        isBold: Bool = false,
        isSecondary: Bool = false
    ) -> some View {
        HStack {
            Text(title)
                .foregroundColor(isSecondary ? .secondary : .primary)
            Spacer()
            Text(value)
                .font(isBold ? .headline : .body)
                .foregroundColor(isSecondary ? .secondary : .primary)
        }
        .padding(.horizontal)
    }
}

// MARK: - Checkout Button
private struct CheckoutButton: View {
    @ObservedObject var viewModel: CartViewModel
    @Binding var isShowingCheckout: Bool
    
    var body: some View {
        Button {
            // Check if user is logged in first
            if viewModel.isUserLoggedIn {
                isShowingCheckout = true
            } else {
                // If not logged in, proceed through the regular flow that
                // will show a login prompt
                Task {
                    await viewModel.proceedToCheckout()
                }
            }
        } label: {
            HStack {
                Text("proceed_to_checkout".localized)
                    .fontWeight(.semibold)
                
                if viewModel.isProcessingCheckout {
                    ProgressView()
                        .padding(.leading, 5)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.accentColor)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding([.horizontal, .bottom])
        }
        .disabled(viewModel.isProcessingCheckout)
    }
}

// MARK: - Cart Item Row
struct CartItemRow: View {
    let item: CartItem
    let formattedPrice: String
    let onUpdateQuantity: (Int) -> Void
    let onRemove: () -> Void
    
    @State private var quantity: Int
    @State private var shouldShowRemoveAlert = false
    
    init(
        item: CartItem,
        formattedPrice: String,
        onUpdateQuantity: @escaping (Int) -> Void,
        onRemove: @escaping () -> Void
    ) {
        self.item = item
        self.formattedPrice = formattedPrice
        self.onUpdateQuantity = onUpdateQuantity
        self.onRemove = onRemove
        _quantity = State(initialValue: item.quantity)
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ProductImageView(
                size: 80,
                imageUrl: item.product.images?.first?.downloadUrl,
                baseURL: AppConfig.shared.imageBaseUrl
            )
            
            VStack(alignment: .leading, spacing: 8) {
                productDetails
                priceAndRemoveButton
                quantityControls
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
        .alert("remove_item".localized, isPresented: $shouldShowRemoveAlert) {
            Button("remove".localized, role: .destructive, action: onRemove)
            Button("cancel".localized, role: .cancel) {}
        } message: {
            Text("remove_item_confirmation".localized)
        }
    }
    
    private var productDetails: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.product.name)
                .font(.headline)
                .lineLimit(2)
            
            if let variantName = item.variantName {
                Text(String(format: "variant_label".localized, variantName))
                    .font(.subheadline)
                    .foregroundColor(.accentColor)
            }
        }
    }
    
    private var priceAndRemoveButton: some View {
        HStack {
            Text(formattedPrice)
                .font(.headline)
            
            Spacer()
            
            Button {
                shouldShowRemoveAlert = true
            } label: {
                Image(systemName: "trash")
                    .foregroundColor(.red)
                    .accessibilityLabel("remove".localized)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private var quantityControls: some View {
        HStack {
            Text("quantity_label".localized)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            QuantityStepperView(
                quantity: $quantity,
                range: 1...10,
                onValueChanged: onUpdateQuantity
            )
        }
    }
}

