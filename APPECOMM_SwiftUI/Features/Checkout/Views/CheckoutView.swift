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
    
    // MARK: - Initialization
    
    init(cart: Cart?) {
        // Inyectando dependencias usando DependencyInjector
        let paymentService = DependencyInjector.shared.resolve(PaymentServiceProtocol.self)
        let authRepository = DependencyInjector.shared.resolve(AuthRepositoryProtocol.self)
        let validator = DependencyInjector.shared.resolve(InputValidatorProtocol.self)
        let shippingService = DependencyInjector.shared.resolve(ShippingServiceProtocol.self)
        
        // Crear el view model con dependencias
        _viewModel = StateObject(wrappedValue: CheckoutViewModel(
            cart: cart,
            paymentService: paymentService,
            authRepository: authRepository,
            validator: validator,
            shippingService: shippingService
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
                LoadingView()
            }
            
            // Error toast
            if let errorMessage = viewModel.errorMessage {
                ErrorToast(message: errorMessage) {
                    viewModel.errorMessage = nil
                }
            }
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
            return "Shipping Information"
        case .paymentMethod:
            return "Payment Method"
        case .cardDetails:
            return "Card Details"
        case .review:
            return "Order Review"
        case .processing:
            return "Processing Payment"
        case .confirmation:
            return "Payment Confirmation"
        case .error:
            return "Payment Error"
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

// MARK: - Payment Method Selection View

/// View for selecting payment method
struct PaymentMethodSelectionView: View {
    @ObservedObject var viewModel: CheckoutViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Select Payment Method")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                
                // Payment method options
                VStack(spacing: 16) {
                    ForEach(PaymentMethod.allCases) { method in
                        PaymentMethodCard(
                            method: method,
                            isSelected: viewModel.selectedPaymentMethod == method,
                            action: { viewModel.selectedPaymentMethod = method }
                        )
                    }
                }
                .padding(.horizontal)
                
                OrderSummaryCard(viewModel: viewModel)
                    .padding(.horizontal)
                
                // Continue button
                PrimaryButton(
                    title: "Continue",
                    isLoading: false,
                    isEnabled: true
                ) {
                    viewModel.proceedToNextStep()
                }
                .padding([.top, .horizontal])
            }
            .padding(.vertical)
        }
    }
}

/// Card UI for a payment method option
struct PaymentMethodCard: View {
    let method: PaymentMethod
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: method.iconName)
                    .font(.title2)
                    .foregroundColor(isSelected ? .blue : .gray)
                    .frame(width: 40)
                
                Text(method.displayName)
                    .font(.headline)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Credit Card Details View

/// View for entering credit card information
struct CreditCardDetailsView: View {
    @ObservedObject var viewModel: CheckoutViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Credit Card Form
                VStack(alignment: .leading, spacing: 16) {
                    Text("Card Information")
                        .font(.headline)
                        .padding(.bottom, 8)
                    
                    // Card Number Field
                    CustomTextField(
                        title: "Card Number",
                        placeholder: "4242 4242 4242 4242",
                        type: .regular,
                        state: viewModel.creditCardDetails.isCardNumberValid ? .valid : .normal,
                        text: Binding(
                            get: { viewModel.creditCardDetails.cardNumber },
                            set: {
                                let formatted = viewModel.formatCardNumber($0)
                                viewModel.creditCardDetails.cardNumber = formatted
                                viewModel.creditCardDetails.isCardNumberValid = viewModel.validateCardNumber(formatted)
                            }
                        )
                    )
                    .keyboardType(.numberPad)
                    
                    // Cardholder Name Field
                    CustomTextField(
                        title: "Cardholder Name",
                        placeholder: "John Doe",
                        type: .regular,
                        state: viewModel.creditCardDetails.isCardholderNameValid ? .valid : .normal,
                        text: Binding(
                            get: { viewModel.creditCardDetails.cardholderName },
                            set: {
                                viewModel.creditCardDetails.cardholderName = $0
                                viewModel.creditCardDetails.isCardholderNameValid = viewModel.validateCardholderName($0)
                            }
                        )
                    )
                    
                    // Expiry Date and CVV
                    HStack(spacing: 12) {
                        CustomTextField(
                            title: "Expiry Date",
                            placeholder: "MM/YY",
                            type: .regular,
                            state: viewModel.creditCardDetails.isExpiryDateValid ? .valid : .normal,
                            text: Binding(
                                get: { viewModel.creditCardDetails.expiryDate },
                                set: {
                                    let formatted = viewModel.formatExpiryDate($0)
                                    viewModel.creditCardDetails.expiryDate = formatted
                                    viewModel.creditCardDetails.isExpiryDateValid = viewModel.validateExpiryDate(formatted)
                                }
                            )
                        )
                        .keyboardType(.numberPad)
                        
                        CustomTextField(
                            title: "CVV",
                            placeholder: "123",
                            type: .regular,
                            state: viewModel.creditCardDetails.isCvvValid ? .valid : .normal,
                            text: Binding(
                                get: { viewModel.creditCardDetails.cvv },
                                set: {
                                    viewModel.creditCardDetails.cvv = $0
                                    viewModel.creditCardDetails.isCvvValid = viewModel.validateCVV($0)
                                }
                            )
                        )
                        .keyboardType(.numberPad)
                    }
                }
                .padding(.horizontal)
                
                OrderSummaryCard(viewModel: viewModel)
                    .padding(.horizontal)
                
                PrimaryButton(
                    title: "Continue to Review",
                    isLoading: false,
                    isEnabled: viewModel.creditCardDetails.isValid
                ) {
                    viewModel.proceedToNextStep()
                }
                .padding([.top, .horizontal])
            }
            .padding(.vertical)
        }
    }
}

// MARK: - Order Review View

/// View for reviewing the order before finalizing
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
                    
                    if viewModel.selectedPaymentMethod == .creditCard {
                        CreditCardSummaryView(details: viewModel.creditCardDetails)
                    } else {
                        HStack {
                            Image(systemName: viewModel.selectedPaymentMethod.iconName)
                                .foregroundColor(.blue)
                            Text(viewModel.selectedPaymentMethod.displayName)
                                .fontWeight(.semibold)
                        }
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
    }
}

// MARK: - Helper Views for Review

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

// MARK: - Other views remain unchanged

/// Row item for order review
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

/// Summary view for credit card information
struct CreditCardSummaryView: View {
    let details: CreditCardDetails
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "creditcard.fill")
                    .foregroundColor(.blue)
                    .imageScale(.large)
                
                Text("•••• \(details.cardNumber.suffix(4))")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            
            Text(details.cardholderName)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("Expires: \(details.expiryDate)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Payment Processing View

/// View shown while payment is being processed
struct PaymentProcessingView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            LottieView(animationName: "payment-processing")
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
    }
}

/// Placeholder for Lottie animation view
struct LottieView: View {
    let animationName: String
    @State private var isAnimating = false
    
    var body: some View {
        // In a real implementation, this would use Lottie
        // For now, use a placeholder animation
        ZStack {
            Circle()
                .stroke(Color.blue.opacity(0.3), lineWidth: 8)
                .frame(width: 120, height: 120)
            
            Circle()
                .trim(from: 0, to: 0.7)
                .stroke(Color.blue, lineWidth: 8)
                .frame(width: 120, height: 120)
                .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
                .animation(Animation.linear(duration: 1).repeatForever(autoreverses: false), value: isAnimating)
                .onAppear {
                    isAnimating = true
                }
        }
    }
}

// MARK: - Payment Confirmation View

/// View shown after successful payment
struct PaymentConfirmationView: View {
    @ObservedObject var viewModel: CheckoutViewModel
    
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
                
                // Order Summary
                VStack(alignment: .leading, spacing: 16) {
                    Text("Order Summary")
                        .font(.headline)
                        .padding(.bottom, 8)
                    
                    HStack {
                        Text("Order Total")
                            .fontWeight(.semibold)
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
                
                // Continue Shopping button
                Button(action: {
                    // Navigate back to the product list
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
            }
            .padding()
        }
    }
}

// MARK: - Payment Error View

/// View shown after payment failure
struct PaymentErrorView: View {
    @ObservedObject var viewModel: CheckoutViewModel
    
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
                // Navigate back to cart
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
    }
}

