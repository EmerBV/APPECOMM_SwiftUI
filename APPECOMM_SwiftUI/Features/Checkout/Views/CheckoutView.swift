//
//  CheckoutView.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 28/3/25.
//

import SwiftUI

struct CheckoutView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: CheckoutViewModel
    @State private var showingPaymentForm = false
    @State private var selectedOrder: Order?
    
    // MARK: - Initialization
    
    init(cart: Cart?) {
        // Injecting dependencies using DependencyInjector
        let dependencies = DependencyInjector.shared
        let checkoutService = dependencies.resolve(CheckoutServiceProtocol.self)
        let paymentService = dependencies.resolve(PaymentServiceProtocol.self)
        let authRepository = dependencies.resolve(AuthRepositoryProtocol.self)
        let validator = dependencies.resolve(InputValidatorProtocol.self)
        let shippingService = dependencies.resolve(ShippingServiceProtocol.self)
        let stripeService = dependencies.resolve(StripeServiceProtocol.self)
        
        // Create view model with dependencies
        _viewModel = StateObject(wrappedValue: CheckoutViewModel(
            cart: cart,
            checkoutService: checkoutService,
            paymentService: paymentService,
            authRepository: authRepository,
            validator: validator,
            shippingService: shippingService,
            stripeService: stripeService
        ))
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            CheckoutContentView(
                viewModel: viewModel,
                showingPaymentForm: $showingPaymentForm,
                selectedOrder: $selectedOrder
            )
        }
        .interactiveDismissDisabled()
    }
}

// MARK: - Helper Views
struct ErrorToastView: View {
    let message: String
    let onDismiss: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundColor(.white)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.red)
            )
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
    }
}

/*
 struct CartItemRow: View {
 let item: CartItem
 
 var body: some View {
 HStack {
 AsyncImage(url: URL(string: item.product.imageUrl)) { image in
 image
 .resizable()
 .aspectRatio(contentMode: .fit)
 } placeholder: {
 ProgressView()
 }
 .frame(width: 60, height: 60)
 
 VStack(alignment: .leading) {
 Text(item.product.name)
 .font(.headline)
 Text("Cantidad: \(item.quantity)")
 .font(.subheadline)
 Text(String(format: "%.2f €", item.product.price * Double(item.quantity)))
 .font(.subheadline)
 .foregroundColor(.blue)
 }
 }
 .padding(.vertical, 8)
 }
 }
 
 
 struct AddressRow: View {
 let address: Address
 
 var body: some View {
 VStack(alignment: .leading, spacing: 4) {
 Text(address.name)
 .font(.headline)
 Text(address.street)
 .font(.subheadline)
 Text("\(address.city), \(address.postalCode)")
 .font(.subheadline)
 Text(address.country)
 .font(.subheadline)
 }
 }
 }
 */
