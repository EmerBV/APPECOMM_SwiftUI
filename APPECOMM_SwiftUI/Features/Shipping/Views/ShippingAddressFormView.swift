//
//  ShippingAddressFormView.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 3/4/25.
//

import SwiftUI

struct ShippingAddressFormView: View {
    @ObservedObject var viewModel: ShippingAddressesViewModel
    let isNewAddress: Bool
    var addressToEdit: ShippingDetails?
    let onSave: () -> Void
    let onCancel: () -> Void
    
    @State private var fullName: String = ""
    @State private var address: String = ""
    @State private var city: String = ""
    @State private var state: String = ""
    @State private var postalCode: String = ""
    @State private var country: String = ""
    @State private var phoneNumber: String = ""
    @State private var isDefault: Bool = false
    
    @FocusState private var focusedField: FormField?
    
    enum FormField {
        case fullName, address, city, state, postalCode, country, phoneNumber
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Contact Information")) {
                    TextField("Full Name", text: $fullName)
                        .focused($focusedField, equals: .fullName)
                        .submitLabel(.next)
                        .onSubmit {
                            focusedField = .address
                        }
                    
                    TextField("Phone Number", text: $phoneNumber)
                        .focused($focusedField, equals: .phoneNumber)
                        .keyboardType(.phonePad)
                        .submitLabel(.next)
                }
                
                Section(header: Text("Address Details")) {
                    TextField("Address", text: $address)
                        .focused($focusedField, equals: .address)
                        .submitLabel(.next)
                        .onSubmit {
                            focusedField = .city
                        }
                    
                    TextField("City", text: $city)
                        .focused($focusedField, equals: .city)
                        .submitLabel(.next)
                        .onSubmit {
                            focusedField = .state
                        }
                    
                    TextField("State / Province", text: $state)
                        .focused($focusedField, equals: .state)
                        .submitLabel(.next)
                        .onSubmit {
                            focusedField = .postalCode
                        }
                    
                    TextField("Postal Code", text: $postalCode)
                        .focused($focusedField, equals: .postalCode)
                        .keyboardType(.numbersAndPunctuation)
                        .submitLabel(.next)
                        .onSubmit {
                            focusedField = .country
                        }
                    
                    TextField("Country", text: $country)
                        .focused($focusedField, equals: .country)
                        .submitLabel(.done)
                }
                
                Section {
                    Toggle("Set as Default Address", isOn: $isDefault)
                    
                    Button(action: saveAddress) {
                        Text("Save Address")
                            .bold()
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .disabled(!isFormValid())
                }
            }
            .navigationTitle(isNewAddress ? "Add Address" : "Edit Address")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel", action: onCancel)
                }
                
                ToolbarItem(placement: .keyboard) {
                    HStack {
                        Spacer()
                        Button("Done") {
                            focusedField = nil
                        }
                    }
                }
            }
            .onAppear {
                if let address = addressToEdit {
                    // Pre-populate form with existing address details
                    fullName = address.fullName ?? ""
                    self.address = address.address ?? ""
                    city = address.city ?? ""
                    state = address.state ?? ""
                    postalCode = address.postalCode ?? ""
                    country = address.country ?? ""
                    phoneNumber = address.phoneNumber ?? ""
                    isDefault = address.isDefault ?? false
                }
            }
            .overlay {
                if viewModel.isLoading {
                    LoadingView()
                }
            }
        }
    }
    
    private func isFormValid() -> Bool {
        return !fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !city.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !state.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !postalCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !country.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func saveAddress() {
        let shippingForm = ShippingDetailsForm(
            fullName: fullName,
            address: address,
            city: city,
            state: state,
            postalCode: postalCode,
            country: country,
            phoneNumber: phoneNumber,
            isDefaultAddress: isDefault
        )
        
        if isNewAddress {
            viewModel.createShippingAddress(form: shippingForm)
        } else if let addressToEdit = addressToEdit {
            viewModel.updateShippingAddress(id: addressToEdit.id ?? 0, form: shippingForm)
        }
        
        onSave()
    }
}
