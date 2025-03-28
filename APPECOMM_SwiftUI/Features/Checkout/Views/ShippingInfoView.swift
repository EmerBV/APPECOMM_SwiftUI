//
//  ShippingInfoView.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 28/3/25.
//

import SwiftUI

struct ShippingInfoView: View {
    @ObservedObject var viewModel: CheckoutViewModel
    @FocusState private var focusedField: ShippingField?
    
    enum ShippingField {
        case fullName
        case address
        case city
        case state
        case postalCode
        case country
        case phoneNumber
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                Text("Shipping Information")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                
                // Content: existing details or form
                VStack(alignment: .leading, spacing: 16) {
                    if viewModel.hasExistingShippingDetails && !viewModel.isEditingShippingDetails {
                        // Show existing details
                        existingShippingDetailsView
                    } else {
                        // Show form
                        shippingFormView
                    }
                    
                    // Order summary
                    OrderSummaryCard(viewModel: viewModel)
                    
                    // Continue button
                    PrimaryButton(
                        title: "Continue to Payment",
                        isLoading: viewModel.isLoading,
                        isEnabled: viewModel.hasExistingShippingDetails || viewModel.shippingDetailsForm.isValid
                    ) {
                        focusedField = nil
                        viewModel.proceedToNextStep()
                    }
                    .padding(.top, 16)
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("Shipping Information")
        .toolbar {
            ToolbarItem(placement: .keyboard) {
                HStack {
                    Spacer()
                    
                    Button("Next") {
                        moveToNextField()
                    }
                    
                    Button("Done") {
                        focusedField = nil
                    }
                }
            }
        }
        .alert(isPresented: Binding<Bool>(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Alert(
                title: Text("Error"),
                message: Text(viewModel.errorMessage ?? "An unknown error occurred"),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    // View for existing shipping details
    private var existingShippingDetailsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with edit button
            HStack {
                Text("Your Shipping Address")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    viewModel.isEditingShippingDetails = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "pencil")
                        Text("Edit")
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                }
            }
            
            // Address details
            if let details = viewModel.existingShippingDetails {
                VStack(alignment: .leading, spacing: 6) {
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
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6).opacity(0.5))
                .cornerRadius(8)
            }
        }
    }
    
    // Shipping details form
    private var shippingFormView: some View {
        VStack(spacing: 16) {
            CustomTextField(
                title: "Full Name",
                placeholder: "John Doe",
                type: .regular,
                state: viewModel.shippingDetailsForm.isFullNameValid ?
                    .valid :
                    (viewModel.shippingDetailsForm.fullName.isEmpty ? .normal : .error("Name is required")),
                text: Binding(
                    get: { viewModel.shippingDetailsForm.fullName },
                    set: {
                        viewModel.shippingDetailsForm.fullName = $0
                        viewModel.shippingDetailsForm.isFullNameValid = !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    }
                )
            )
            .focused($focusedField, equals: .fullName)
            .submitLabel(.next)
            .onSubmit {
                focusedField = .address
            }
            
            CustomTextField(
                title: "Address",
                placeholder: "123 Main St",
                type: .regular,
                state: viewModel.shippingDetailsForm.isAddressValid ? .valid : .normal,
                text: Binding(
                    get: { viewModel.shippingDetailsForm.address },
                    set: {
                        viewModel.shippingDetailsForm.address = $0
                        viewModel.shippingDetailsForm.isAddressValid = !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    }
                )
            )
            .focused($focusedField, equals: .address)
            .submitLabel(.next)
            .onSubmit {
                focusedField = .city
            }
            
            HStack(spacing: 12) {
                CustomTextField(
                    title: "City",
                    placeholder: "New York",
                    type: .regular,
                    state: viewModel.shippingDetailsForm.isCityValid ? .valid : .normal,
                    text: Binding(
                        get: { viewModel.shippingDetailsForm.city },
                        set: {
                            viewModel.shippingDetailsForm.city = $0
                            viewModel.shippingDetailsForm.isCityValid = !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        }
                    )
                )
                .focused($focusedField, equals: .city)
                .submitLabel(.next)
                .onSubmit {
                    focusedField = .state
                }
                
                CustomTextField(
                    title: "State",
                    placeholder: "NY",
                    type: .regular,
                    state: viewModel.shippingDetailsForm.isStateValid ? .valid : .normal,
                    text: Binding(
                        get: { viewModel.shippingDetailsForm.state },
                        set: {
                            viewModel.shippingDetailsForm.state = $0
                            viewModel.shippingDetailsForm.isStateValid = !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        }
                    )
                )
                .focused($focusedField, equals: .state)
                .submitLabel(.next)
                .onSubmit {
                    focusedField = .postalCode
                }
            }
            
            HStack(spacing: 12) {
                CustomTextField(
                    title: "Postal Code",
                    placeholder: "10001",
                    type: .numeric,
                    state: viewModel.shippingDetailsForm.isPostalCodeValid ? .valid : .normal,
                    text: Binding(
                        get: { viewModel.shippingDetailsForm.postalCode },
                        set: {
                            viewModel.shippingDetailsForm.postalCode = $0
                            viewModel.shippingDetailsForm.isPostalCodeValid = !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        }
                    )
                )
                .focused($focusedField, equals: .postalCode)
                .submitLabel(.next)
                .onSubmit {
                    focusedField = .country
                }
                
                CustomTextField(
                    title: "Country",
                    placeholder: "United States",
                    type: .regular,
                    state: viewModel.shippingDetailsForm.isCountryValid ? .valid : .normal,
                    text: Binding(
                        get: { viewModel.shippingDetailsForm.country },
                        set: {
                            viewModel.shippingDetailsForm.country = $0
                            viewModel.shippingDetailsForm.isCountryValid = !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        }
                    )
                )
                .focused($focusedField, equals: .country)
                .submitLabel(.next)
                .onSubmit {
                    focusedField = .phoneNumber
                }
            }
            
            CustomTextField(
                title: "Phone Number",
                placeholder: "+1 (555) 123-4567",
                type: .phone,
                state: viewModel.shippingDetailsForm.isPhoneNumberValid ? .valid : .normal,
                text: Binding(
                    get: { viewModel.shippingDetailsForm.phoneNumber },
                    set: {
                        viewModel.shippingDetailsForm.phoneNumber = $0
                        viewModel.shippingDetailsForm.isPhoneNumberValid = !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    }
                )
            )
            .focused($focusedField, equals: .phoneNumber)
            .submitLabel(.done)
            .onSubmit {
                focusedField = nil
            }
        }
    }
    
    private func moveToNextField() {
        switch focusedField {
        case .fullName:
            focusedField = .address
        case .address:
            focusedField = .city
        case .city:
            focusedField = .state
        case .state:
            focusedField = .postalCode
        case .postalCode:
            focusedField = .country
        case .country:
            focusedField = .phoneNumber
        case .phoneNumber:
            focusedField = nil
        case nil:
            focusedField = nil
        }
    }
}
