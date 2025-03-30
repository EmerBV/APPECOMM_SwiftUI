import SwiftUI

struct CheckoutContentView: View {
    @ObservedObject var viewModel: CheckoutViewModel
    @Binding var showingPaymentForm: Bool
    @Binding var selectedOrder: Order?
    
    var body: some View {
        NavigationStack {
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
                                // Dismiss will be handled by the parent view
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
                        ErrorToastView(message: errorMessage) {
                            viewModel.errorMessage = nil
                        }
                    }
                }
                .sheet(isPresented: $showingPaymentForm) {
                    if let order = selectedOrder {
                        PaymentFormView(
                            orderId: order.id,
                            amount: NSDecimalNumber(decimal: order.totalAmount).doubleValue
                        )
                    }
                }
                .alert("Error", isPresented: $viewModel.showError) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text(viewModel.errorMessage ?? "Ha ocurrido un error")
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
