//
//  CartView.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 21/3/25.
//

import SwiftUI

struct CartView: View {
    @StateObject var viewModel: CartViewModel
    @State private var showingClearCartConfirmation = false
    
    init(viewModel: CartViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.isLoading {
                    LoadingView()
                } else if let cart = viewModel.cart, !cart.items.isEmpty {
                    cartContentView(cart: cart)
                } else {
                    emptyCartView
                }
                
                // Error message
                if let errorMessage = viewModel.errorMessage {
                    ErrorToast(message: errorMessage) {
                        viewModel.errorMessage = nil
                    }
                }
                
                // Success message
                if let successMessage = viewModel.successMessage {
                    SuccessToast(message: successMessage) {
                        viewModel.successMessage = nil
                    }
                }
            }
            .navigationTitle("My Cart")
            .toolbar {
                if let cart = viewModel.cart, !cart.items.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            showingClearCartConfirmation = true
                        }) {
                            Text("Clear All")
                                .foregroundColor(.red)
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        viewModel.refreshCart()
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .refreshable {
                viewModel.refreshCart()
            }
            .alert(isPresented: $showingClearCartConfirmation) {
                Alert(
                    title: Text("Clear Cart"),
                    message: Text("Are you sure you want to remove all items from your cart?"),
                    primaryButton: .destructive(Text("Clear")) {
                        viewModel.clearCart()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
        .onAppear {
            if viewModel.isUserLoggedIn {
                viewModel.refreshCart()
            }
        }
    }
    
    // MARK: - Cart Content View
    private func cartContentView(cart: Cart) -> some View {
        VStack(spacing: 0) {
            // Cart items list
            List {
                ForEach(cart.items) { item in
                    CartItemRow(
                        item: item,
                        formattedPrice: viewModel.formattedPrice(item.totalPrice),
                        onUpdateQuantity: { newQuantity in
                            viewModel.updateItemQuantity(
                                itemId: item.itemId,
                                productId: item.product.id,
                                newQuantity: newQuantity
                            )
                        },
                        onRemove: {
                            viewModel.removeItem(
                                itemId: item.itemId,
                                productId: item.product.id
                            )
                        }
                    )
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                }
            }
            .listStyle(PlainListStyle())
            
            // Order summary
            orderSummaryView(cart: cart)
            
            // Checkout button
            checkoutButton(cart: cart)
        }
    }
    
    // MARK: - Empty Cart View
    private var emptyCartView: some View {
        VStack(spacing: 20) {
            Image(systemName: "cart")
                .font(.system(size: 64))
                .foregroundColor(.gray)
            
            Text("Your cart is empty")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Looks like you haven't added any items to your cart yet")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            NavigationLink(destination: ProductListView(viewModel: DependencyInjector.shared.resolve(ProductListViewModel.self))) {
                HStack {
                    Image(systemName: "bag")
                    Text("Browse Products")
                }
                .padding()
                .foregroundColor(.white)
                .background(Color.blue)
                .cornerRadius(10)
            }
            .padding(.top, 20)
        }
        .padding()
    }
    
    // MARK: - Order Summary View
    private func orderSummaryView(cart: Cart) -> some View {
        VStack(spacing: 12) {
            Divider()
                .padding(.bottom, 8)
            
            HStack {
                Text("Order Summary")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal)
            
            HStack {
                Text("Subtotal")
                    .foregroundColor(.secondary)
                Spacer()
                Text(viewModel.formattedPrice(cart.totalAmount))
                    .fontWeight(.semibold)
            }
            .padding(.horizontal)
            
            HStack {
                Text("Shipping")
                    .foregroundColor(.secondary)
                Spacer()
                Text("Calculated at checkout")
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            Divider()
                .padding(.vertical, 8)
            
            HStack {
                Text("Total")
                    .font(.headline)
                Spacer()
                Text(viewModel.formattedPrice(cart.totalAmount))
                    .font(.headline)
            }
            .padding(.horizontal)
            
            Divider()
                .padding(.top, 8)
        }
        .padding(.vertical)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Checkout Button
    private func checkoutButton(cart: Cart) -> some View {
        Button(action: {
            viewModel.proceedToCheckout()
        }) {
            HStack {
                Text("Proceed to Checkout")
                    .fontWeight(.semibold)
                
                if viewModel.isProcessingCheckout {
                    ProgressView()
                        .padding(.leading, 5)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .padding([.horizontal, .bottom])
        }
        .disabled(viewModel.isProcessingCheckout)
    }
}

// MARK: - CartItemRow
struct CartItemRow: View {
    let item: CartItem
    let formattedPrice: String
    let onUpdateQuantity: (Int) -> Void
    let onRemove: () -> Void
    
    @State private var quantity: Int
    @State private var showingRemoveConfirmation = false
    
    init(item: CartItem, formattedPrice: String, onUpdateQuantity: @escaping (Int) -> Void, onRemove: @escaping () -> Void) {
        self.item = item
        self.formattedPrice = formattedPrice
        self.onUpdateQuantity = onUpdateQuantity
        self.onRemove = onRemove
        _quantity = State(initialValue: item.quantity)
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Product image or placeholder
            productImageView
            
            // Product details
            VStack(alignment: .leading, spacing: 8) {
                // Product name and variant
                productInfoView
                
                // Price and remove button
                priceAndRemoveView
                
                // Quantity controls
                quantityControlsView
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
        .alert(isPresented: $showingRemoveConfirmation) {
            Alert(
                title: Text("Remove Item"),
                message: Text("Are you sure you want to remove this item from your cart?"),
                primaryButton: .destructive(Text("Remove")) {
                    onRemove()
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    // MARK: - Product Image View
    private var productImageView: some View {
        ZStack {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 80, height: 80)
                .cornerRadius(8)
            
            // This would be an AsyncImage with the product image URL in a real app
            Image(systemName: "photo")
                .font(.largeTitle)
                .foregroundColor(.gray)
        }
        .frame(width: 80, height: 80)
    }
    
    // MARK: - Product Info View
    private var productInfoView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.product.name)
                .font(.headline)
                .lineLimit(2)
            
            if let variantName = item.variantName {
                Text("Variant: \(variantName)")
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
        }
    }
    
    // MARK: - Price and Remove View
    private var priceAndRemoveView: some View {
        HStack {
            Text(formattedPrice)
                .font(.headline)
            
            Spacer()
            
            Button(action: {
                showingRemoveConfirmation = true
            }) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
        }
    }
    
    // MARK: - Quantity Controls View
    private var quantityControlsView: some View {
        HStack {
            Text("Quantity:")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            HStack(spacing: 12) {
                Button(action: {
                    if quantity > 1 {
                        quantity -= 1
                        onUpdateQuantity(quantity)
                    }
                }) {
                    Image(systemName: "minus.circle.fill")
                        .foregroundColor(quantity > 1 ? .blue : .gray)
                        .font(.title3)
                }
                
                Text("\(quantity)")
                    .font(.headline)
                    .frame(minWidth: 20, alignment: .center)
                
                Button(action: {
                    if quantity < 10 { // Assuming a max of 10 items
                        quantity += 1
                        onUpdateQuantity(quantity)
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(quantity < 10 ? .blue : .gray)
                        .font(.title3)
                }
            }
        }
    }
}
