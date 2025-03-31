//
//  CheckoutView.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 28/3/25.
//

import SwiftUI
import Stripe

// MARK: - Payment Confirmation View

struct PaymentConfirmationView: View {
    @ObservedObject var viewModel: CheckoutViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var navigateToOrderDetails = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Success icon
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.1))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.green)
                        .frame(width: 80, height: 80)
                }
                .padding(.top, 30)
                
                Text("Payment Successful!")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Thank you for your order. Your payment has been processed successfully.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                if let order = viewModel.order {
                    // Order details card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Order Details")
                            .font(.headline)
                            .padding(.bottom, 8)
                        
                        HStack {
                            Text("Order Number")
                            Spacer()
                            Text("#\(order.id)")
                                .fontWeight(.semibold)
                        }
                        
                        HStack {
                            Text("Date")
                            Spacer()
                            Text(formattedDate(from: order.orderDate))
                        }
                        
                        HStack {
                            Text("Order Total")
                            Spacer()
                            Text(order.totalAmount.toCurrentLocalePrice)
                                .fontWeight(.semibold)
                        }
                        
                        Divider()
                        
                        Text("A confirmation email has been sent to your email address.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                } else {
                    // Order Summary if no order object is available
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Order Summary")
                            .font(.headline)
                            .padding(.bottom, 8)
                        
                        HStack {
                            Text("Order Total")
                            Spacer()
                            Text(viewModel.orderSummary.formattedTotal)
                                .fontWeight(.semibold)
                        }
                        
                        Divider()
                        
                        Text("A confirmation email has been sent to your email address.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                }
                
                // Continue Shopping button
                Button(action: {
                    // Return to home screen
                    dismiss()
                    
                    // Post notification to navigate to home tab
                    NotificationCenter.default.post(
                        name: Notification.Name("NavigateToHomeTab"),
                        object: nil
                    )
                }) {
                    Text("Continue Shopping")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding(.top, 20)
                
                // View Order button
                if let order = viewModel.order {
                    Button(action: {
                        navigateToOrderDetails = true
                    }) {
                        Text("View Order")
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.blue, lineWidth: 1)
                            )
                    }
                    .background(
                        NavigationLink(
                            destination: OrderDetailView(orderId: order.id),
                            isActive: $navigateToOrderDetails,
                            label: { EmptyView() }
                        )
                    )
                }
            }
            .padding()
        }
        .navigationTitle("Payment Confirmation")
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
    
    private func formattedDate(from dateString: String) -> String {
        // Convert API date string to a formatted date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS" // Adjust based on API date format
        
        if let date = dateFormatter.date(from: dateString) {
            dateFormatter.dateFormat = "MMM d, yyyy"
            return dateFormatter.string(from: date)
        }
        
        return dateString // Return original if parsing fails
    }
}

// MARK: - Payment Error View

struct PaymentErrorView: View {
    @ObservedObject var viewModel: CheckoutViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            // Error icon
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "exclamationmark.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(.red)
                    .frame(width: 80, height: 80)
            }
            
            Text("Payment Failed")
                .font(.title)
                .fontWeight(.bold)
            
            Text(viewModel.errorMessage ?? "There was a problem processing your payment. Please try again.")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Try Again button
            Button(action: {
                // Return to review screen to try again
                viewModel.currentStep = .review
                viewModel.errorMessage = nil
            }) {
                Text("Try Again")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.top, 20)
            
            // Go back to cart button
            Button(action: {
                // Return to cart screen
                dismiss()
            }) {
                Text("Return to Cart")
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.blue, lineWidth: 1)
                    )
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Payment Failed")
        .navigationBarBackButtonHidden(true)
    }
}

// MARK: - Helper Components

struct OrderReviewItemRow: View {
    let item: CartItem
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 60, height: 60)
                
                Text("\(item.quantity)×")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.product.name)
                    .font(.headline)
                    .lineLimit(2)
                
                if let variantName = item.variantName {
                    Text("Variant: \(variantName)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Text(item.totalPrice.toCurrentLocalePrice)
                .font(.headline)
        }
        .padding(.vertical, 4)
    }
}

struct ShippingDetailsSection: View {
    let details: ShippingDetailsResponse
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let fullName = details.fullName {
                Text(fullName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            
            Text(details.address)
                .font(.subheadline)
            
            Text("\(details.city), \(details.state ?? "") \(details.postalCode)")
                .font(.subheadline)
            
            Text(details.country)
                .font(.subheadline)
            
            if let phoneNumber = details.phoneNumber {
                Text(phoneNumber)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct ShippingFormSummary: View {
    let form: ShippingDetailsForm
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(form.fullName)
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Text(form.address)
                .font(.subheadline)
            
            Text("\(form.city), \(form.state) \(form.postalCode)")
                .font(.subheadline)
            
            Text(form.country)
                .font(.subheadline)
            
            Text(form.phoneNumber)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

struct CheckoutView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var viewModel: CheckoutViewModel
    @State private var showingPaymentForm = false
    @State private var selectedOrder: Order?
    
    // MARK: - Initialization
    
    init(cart: Cart?) {
        // Inject dependencies using DependencyInjector
        let dependencies = DependencyInjector.shared
        let checkoutService = dependencies.resolve(CheckoutServiceProtocol.self)
        let paymentService = dependencies.resolve(PaymentServiceProtocol.self)
        let authRepository = dependencies.resolve(AuthRepositoryProtocol.self)
        let validator = dependencies.resolve(InputValidatorProtocol.self)
        let shippingService = dependencies.resolve(ShippingServiceProtocol.self)
        let stripeService = dependencies.resolve(StripeServiceProtocol.self)
        
        // Create view model with dependencies
        _viewModel = ObservedObject(wrappedValue: CheckoutViewModel(
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
                selectedOrder: $selectedOrder,
                dismiss: dismiss
            )
            .fullScreenCover(isPresented: $viewModel.showPaymentSheet) {
                if let paymentSheetViewModel = viewModel.paymentSheetViewModel {
                    PaymentSheetView(viewModel: paymentSheetViewModel)
                }
            }
        }
        .interactiveDismissDisabled()
    }
}

// MARK: - CheckoutContentView

struct CheckoutContentView: View {
    @ObservedObject var viewModel: CheckoutViewModel
    @Binding var showingPaymentForm: Bool
    @Binding var selectedOrder: Order?
    var dismiss: DismissAction
    
    var body: some View {
        contentView
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    if canGoBack {
                        Button(action: viewModel.goBack) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    if viewModel.currentStep == .confirmation {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
            }
            .overlay {
                if viewModel.isLoading {
                    LoadingOverlay()
                }
            }
            .overlay {
                if let errorMessage = viewModel.errorMessage {
                    ErrorToast(message: errorMessage) {
                        viewModel.errorMessage = nil
                    }
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
        case .review:
            return "Order Review"
        case .processing:
            return "Processing"
        case .confirmation:
            return "Payment Confirmation"
        case .error:
            return "Error"
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

// MARK: - Order Review View

struct OrderReviewView: View {
    @ObservedObject var viewModel: CheckoutViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Order summary section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Order Summary")
                        .font(.headline)
                    
                    if let cart = viewModel.cart, !cart.items.isEmpty {
                        ForEach(cart.items) { item in
                            OrderReviewItemRow(item: item)
                        }
                    } else {
                        Text("No items in cart")
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                
                // Shipping information section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Shipping Information")
                        .font(.headline)
                    
                    if viewModel.hasExistingShippingDetails, let details = viewModel.existingShippingDetails {
                        ShippingDetailsSection(details: details)
                    } else {
                        ShippingFormSummary(form: viewModel.shippingDetailsForm)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                
                // Payment method section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Payment Method")
                        .font(.headline)
                    
                    HStack {
                        Image(systemName: viewModel.selectedPaymentMethod.iconName)
                            .foregroundColor(.blue)
                        Text(viewModel.selectedPaymentMethod.displayName)
                            .fontWeight(.semibold)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                
                // Total summary
                VStack(spacing: 16) {
                    HStack {
                        Text("Subtotal")
                            .fontWeight(.medium)
                        Spacer()
                        Text(viewModel.orderSummary.formattedSubtotal)
                    }
                    
                    HStack {
                        Text("Tax")
                            .fontWeight(.medium)
                        Spacer()
                        Text(viewModel.orderSummary.formattedTax)
                    }
                    
                    HStack {
                        Text("Shipping")
                            .fontWeight(.medium)
                        Spacer()
                        Text(viewModel.orderSummary.formattedShipping)
                    }
                    
                    Divider()
                    
                    HStack {
                        Text("Total")
                            .font(.headline)
                        Spacer()
                        Text(viewModel.orderSummary.formattedTotal)
                            .font(.headline)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                
                PrimaryButton(
                    title: "Place Order",
                    isLoading: viewModel.isLoading,
                    isEnabled: true
                ) {
                    viewModel.proceedToNextStep()
                }
                .padding(.top, 16)
            }
            .padding()
        }
        .navigationTitle("Review Order")
    }
}

// MARK: - Payment Processing View

struct PaymentProcessingView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            ProcessingAnimation()
                .frame(width: 200, height: 200)
            
            Text("Processing Your Payment")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Please wait while we process your payment...")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
        }
        .padding()
        .navigationBarBackButtonHidden(true)
    }
}

struct ProcessingAnimation: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Outer circle
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 10)
                .frame(width: 150, height: 150)
            
            // Animated arc
            Circle()
                .trim(from: 0, to: 0.8)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [.blue, .purple]),
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .frame(width: 150, height: 150)
                .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
                .animation(
                    Animation.linear(duration: 1)
                        .repeatForever(autoreverses: false),
                    value: isAnimating
                )
                .onAppear {
                    isAnimating = true
                }
            
            // Credit card icon
            Image(systemName: "creditcard.fill")
                .font(.system(size: 40))
                .foregroundColor(.blue)
        }
    }
}
