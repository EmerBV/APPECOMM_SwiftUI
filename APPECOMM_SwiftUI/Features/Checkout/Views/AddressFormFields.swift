//
//  AddressFormFields.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 28/3/25.
//

import SwiftUI

// MARK: - Address Form Fields
struct AddressFormFields: View {
    @ObservedObject var viewModel: CheckoutViewModel
    
    var body: some View {
        Group {
            // Form header
            HStack {
                Text(viewModel.hasExistingShippingDetails ? "Edit Shipping Address" : "Shipping Address")
                    .font(.headline)
                
                Spacer()
                
                if viewModel.hasExistingShippingDetails && viewModel.isEditingShippingDetails {
                    Button(action: {
                        viewModel.isEditingShippingDetails = false
                    }) {
                        Text("Cancel")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding(.bottom, 8)
            
            // Form fields
            CustomTextField(
                title: "Full Name",
                placeholder: "John Doe",
                type: .regular,
                state: viewModel.shippingDetailsForm.isFullNameValid ? .valid : .normal,
                text: Binding(
                    get: { viewModel.shippingDetailsForm.fullName },
                    set: {
                        viewModel.shippingDetailsForm.fullName = $0
                        viewModel.shippingDetailsForm.isFullNameValid = !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    }
                )
            )
            
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
            }
            
            HStack(spacing: 12) {
                CustomTextField(
                    title: "Postal Code",
                    placeholder: "10001",
                    type: .regular,
                    state: viewModel.shippingDetailsForm.isPostalCodeValid ? .valid : .normal,
                    text: Binding(
                        get: { viewModel.shippingDetailsForm.postalCode },
                        set: {
                            viewModel.shippingDetailsForm.postalCode = $0
                            viewModel.shippingDetailsForm.isPostalCodeValid = !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        }
                    )
                )
                .keyboardType(.numberPad)
                
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
            }
            
            CustomTextField(
                title: "Phone Number",
                placeholder: "+1 (555) 123-4567",
                type: .regular,
                state: viewModel.shippingDetailsForm.isPhoneNumberValid ? .valid : .normal,
                text: Binding(
                    get: { viewModel.shippingDetailsForm.phoneNumber },
                    set: {
                        viewModel.shippingDetailsForm.phoneNumber = $0
                        viewModel.shippingDetailsForm.isPhoneNumberValid = !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    }
                )
            )
            .keyboardType(.phonePad)
        }
    }
}
