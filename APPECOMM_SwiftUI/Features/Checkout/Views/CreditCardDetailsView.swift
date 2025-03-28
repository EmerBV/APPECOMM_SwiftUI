//
//  CreditCardDetailsView.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 28/3/25.
//

import SwiftUI

struct CreditCardDetailsView: View {
    @ObservedObject var viewModel: CheckoutViewModel
    @FocusState private var focusedField: CardField?
    
    enum CardField {
        case cardNumber
        case cardholderName
        case expiryDate
        case cvv
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Credit Card Form
                VStack(alignment: .leading, spacing: 16) {
                    Text("Card Information")
                        .font(.headline)
                        .padding(.bottom, 8)
                    
                    // Card visual representation
                    creditCardPreview
                        .padding(.bottom, 12)
                    
                    // Card Number Field
                    let cardNumberState: FieldState = viewModel.creditCardDetails.isCardNumberValid
                    ? .valid
                    : (viewModel.creditCardDetails.cardNumber.isEmpty ? .normal : .error("Invalid card number"))
                    
                    CustomTextField(
                        title: "Card Number",
                        placeholder: "4242 4242 4242 4242",
                        type: .numeric,
                        state: cardNumberState,
                        text: Binding(
                            get: { viewModel.creditCardDetails.cardNumber },
                            set: {
                                let formatted = viewModel.formatCardNumber($0)
                                viewModel.creditCardDetails.cardNumber = formatted
                                let (isValid, errorMessage) = viewModel.validateCardNumber(formatted)
                                viewModel.creditCardDetails.isCardNumberValid = isValid
                                viewModel.creditCardDetails.cardNumberError = errorMessage
                            }
                        )
                    )
                    .focused($focusedField, equals: .cardNumber)
                    .submitLabel(.next)
                    .onSubmit {
                        focusedField = .cardholderName
                    }
                    
                    // Cardholder Name Field
                    let cardholderNameState: FieldState = viewModel.creditCardDetails.isCardholderNameValid
                    ? .valid
                    : (viewModel.creditCardDetails.cardholderName.isEmpty ? .normal : .error("Invalid cardholder name"))
                    
                    CustomTextField(
                        title: "Cardholder Name",
                        placeholder: "John Doe",
                        type: .regular,
                        state: cardholderNameState,
                        text: Binding(
                            get: { viewModel.creditCardDetails.cardholderName },
                            set: {
                                viewModel.creditCardDetails.cardholderName = $0
                                viewModel.creditCardDetails.isCardholderNameValid = viewModel.validateCardholderName($0)
                            }
                        )
                    )
                    .focused($focusedField, equals: .cardholderName)
                    .submitLabel(.next)
                    .onSubmit {
                        focusedField = .expiryDate
                    }
                    
                    // Expiry Date and CVV
                    HStack(spacing: 12) {
                        let expiryDateState: FieldState = viewModel.creditCardDetails.isExpiryDateValid
                        ? .valid
                        : (viewModel.creditCardDetails.expiryDate.isEmpty ? .normal : .error("Invalid expiry date"))
                        
                        CustomTextField(
                            title: "Expiry Date",
                            placeholder: "MM/YY",
                            type: .numeric,
                            state: expiryDateState,
                            text: Binding(
                                get: { viewModel.creditCardDetails.expiryDate },
                                set: {
                                    let formatted = viewModel.formatExpiryDate($0)
                                    viewModel.creditCardDetails.expiryDate = formatted
                                    let (isValid, errorMessage) = viewModel.validateExpiryDate(formatted)
                                    viewModel.creditCardDetails.isExpiryDateValid = isValid
                                    viewModel.creditCardDetails.expiryDateError = errorMessage
                                }
                            )
                        )
                        .focused($focusedField, equals: .expiryDate)
                        .submitLabel(.next)
                        .onSubmit {
                            focusedField = .cvv
                        }
                        
                        let cvvState: FieldState = viewModel.creditCardDetails.isCvvValid
                        ? .valid
                        : (viewModel.creditCardDetails.cvv.isEmpty ? .normal : .error("Invalid CVV"))
                        
                        CustomTextField(
                            title: "CVV",
                            placeholder: "123",
                            type: .numeric,
                            state: cvvState,
                            text: Binding(
                                get: { viewModel.creditCardDetails.cvv },
                                set: {
                                    viewModel.creditCardDetails.cvv = $0
                                    let (isValid, errorMessage) = viewModel.validateCVV($0)
                                    viewModel.creditCardDetails.isCvvValid = isValid
                                    viewModel.creditCardDetails.cvvError = errorMessage
                                }
                            )
                        )
                        .focused($focusedField, equals: .cvv)
                        .submitLabel(.done)
                        .onSubmit {
                            focusedField = nil
                        }
                    }
                }
                .padding(.horizontal)
                
                OrderSummaryCard(viewModel: viewModel)
                    .padding(.horizontal)
                
                PrimaryButton(
                    title: "Continue to Review",
                    isLoading: viewModel.isLoading,
                    isEnabled: viewModel.creditCardDetails.isValid
                ) {
                    focusedField = nil
                    viewModel.validateCreditCardForm() // Validar todos los campos antes de continuar
                    if viewModel.creditCardDetails.isValid {
                        viewModel.proceedToNextStep()
                    } else {
                        viewModel.errorMessage = "Please fill in all card details correctly"
                    }
                }
                .padding([.top, .horizontal])
            }
            .padding(.vertical)
        }
        .navigationTitle("Card Details")
        .toolbar {
            ToolbarItem(placement: .keyboard) {
                HStack {
                    Spacer()
                    
                    Button("Done") {
                        focusedField = nil
                    }
                }
            }
        }
    }
    
    private var creditCardPreview: some View {
        ZStack {
            // Card background
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(radius: 4)
            
            VStack(alignment: .leading, spacing: 16) {
                // Card brand logo or chip
                HStack {
                    Image(systemName: "creditcard.fill")
                        .font(.title)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Determine brand based on first digit
                    if !viewModel.creditCardDetails.cardNumber.isEmpty {
                        let firstDigit = viewModel.creditCardDetails.cardNumber.prefix(1)
                        Text(getBrandFromFirstDigit(firstDigit))
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                }
                
                // Card number
                Text(viewModel.creditCardDetails.cardNumber.isEmpty ? "•••• •••• •••• ••••" : viewModel.creditCardDetails.cardNumber)
                    .font(.system(size: 18, weight: .medium, design: .monospaced))
                    .foregroundColor(.white)
                
                Spacer()
                
                // Cardholder information
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Card Holder")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text(viewModel.creditCardDetails.cardholderName.isEmpty ? "Your Name" : viewModel.creditCardDetails.cardholderName)
                            .font(.footnote)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    // Expiry date
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Expires")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text(viewModel.creditCardDetails.expiryDate.isEmpty ? "MM/YY" : viewModel.creditCardDetails.expiryDate)
                            .font(.footnote)
                            .foregroundColor(.white)
                    }
                }
            }
            .padding()
        }
        .frame(height: 180)
    }
    
    private func getBrandFromFirstDigit(_ digit: String.SubSequence) -> String {
        switch digit {
        case "4":
            return "VISA"
        case "5":
            return "MASTERCARD"
        case "3":
            return "AMEX"
        case "6":
            return "DISCOVER"
        default:
            return "CARD"
        }
    }
}
