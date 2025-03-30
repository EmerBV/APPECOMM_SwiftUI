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
        ZStack {
            contentView
                .navigationTitle(navigationTitle)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    toolbarItems
                }
                .disabled(viewModel.isLoading)
            
            // Loading overlay
            if viewModel.isLoading {
                LoadingOverlay()
            }
            
            // Error toast
            if let errorMessage = viewModel.errorMessage {
                ErrorToastView(message: errorMessage) {
                    viewModel.errorMessage = nil
                }
            }
        }
        .sheet(isPresented: $showingPaymentForm) {
            if let order = selectedOrder {
                PaymentFormView(orderId: order.id, amount: order.totalAmount)
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "Ha ocurrido un error")
        }
    }
    
    // MARK: - Content Views
    
    /// The main content view based on the current checkout step
    @ViewBuilder
    private var contentView: some View {
        switch viewModel.currentStep {
        case .shippingInfo:
            ShippingInfoView(viewModel: viewModel)
        case .paymentMethod:
            PaymentMethodSelectionView(viewModel: viewModel)
        case .cardDetails:
            CreditCardDetailsView(viewModel: viewModel)
        case .review:
            OrderReviewView(viewModel: viewModel)
        case .processing:
            PaymentProcessingView()
        case .confirmation:
            PaymentConfirmationView(viewModel: viewModel)
        case .error:
            PaymentErrorView(viewModel: viewModel)
        }
    }
    
    /// Dynamic navigation title based on the current step
    private var navigationTitle: String {
        switch viewModel.currentStep {
        case .shippingInfo:
            return "Shipping"
        case .paymentMethod:
            return "Payment Method"
        case .cardDetails:
            return "Card Details"
        case .review:
            return "Order Review"
        case .processing:
            return "Processing"
        case .confirmation:
            return "Confirmation"
        case .error:
            return "Error"
        }
    }
    
    /// Toolbar content based on the current step
    private var toolbarItems: some ToolbarContent {
        Group {
            ToolbarItem(placement: .navigationBarLeading) {
                if canGoBack {
                    Button(action: viewModel.goBack) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.blue)
                    }
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                if viewModel.currentStep == .confirmation {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    /// Determines if the back button should be shown
    private var canGoBack: Bool {
        switch viewModel.currentStep {
        case .shippingInfo, .processing, .confirmation, .error:
            return false
        default:
            return true
        }
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
