//
//  RegistrationView.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 24/4/25.
//

import SwiftUI

struct RegistrationView: View {
    @StateObject private var viewModel: RegistrationViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var isKeyboardVisible = false
    @State private var showTermsAndConditions = false
    
    init() {
        _viewModel = StateObject(wrappedValue: DependencyInjector.shared.resolve(RegistrationViewModel.self))
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 25) {
                    if !isKeyboardVisible {
                        LogoHeader()
                            .padding(.top, 20)
                    }
                    
                    RegistrationForm(
                        viewModel: viewModel,
                        showTermsAndConditions: $showTermsAndConditions
                    )
                    .padding(.horizontal)
                    
                    if !isKeyboardVisible {
                        Spacer()
                            .frame(height: 40)
                    }
                    
                    PrimaryButton(
                        title: "sign_up".localized,
                        isLoading: viewModel.isRegistering,
                        isEnabled: viewModel.isFormValid
                    ) {
                        hideKeyboard()
                        viewModel.register()
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                    
                    if !isKeyboardVisible {
                        HStack {
                            Text("already_have_account".localized)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Button(action: {
                                dismiss()
                            }) {
                                Text("sign_in".localized)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.bottom, 40)
                    }
                }
                .padding()
                .frame(minHeight: geometry.size.height)
            }
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("back_label".localized)
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
            .background(backgroundColor.edgesIgnoringSafeArea(.all))
            .keyboardAdaptive(isKeyboardVisible: $isKeyboardVisible)
            .onTapGesture {
                hideKeyboard()
            }
            
            .circularLoading(
                isLoading: viewModel.isRegistering,
                message: "creating_account".localized,
                strokeColor: .blue,
                backgroundColor: .gray.opacity(0.1),
                showBackdrop: true,
                containerSize: 80,
                logoSize: 50
            )
        }
        .accentColor(.blue)
        .sheet(isPresented: $showTermsAndConditions) {
            TermsAndConditionsView(isPresented: $showTermsAndConditions)
        }
        .overlay {
            if let errorMessage = viewModel.errorMessage {
                ErrorToast(message: errorMessage) {
                    viewModel.errorMessage = nil
                }
            }
        }
    }
    
    private var backgroundColor: Color {
        colorScheme == .dark ? .black : .white
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}

// MARK: - Components

private struct LogoHeader: View {
    var body: some View {
        VStack(spacing: 16) {
            Image("logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80)
                .accessibilityLabel("App Logo")
            
            Text("create_your_account".localized)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)
                .accessibilityAddTraits(.isHeader)
            
            Text("join_us_message".localized)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
}

private struct RegistrationForm: View {
    @ObservedObject var viewModel: RegistrationViewModel
    @Binding var showTermsAndConditions: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            // Nombre
            CustomTextField(
                title: "first_name".localized,
                placeholder: "first_name_placeholder".localized,
                type: .regular,
                state: viewModel.firstNameState,
                text: $viewModel.firstName,
                onEditingChanged: { isEditing in
                    if !isEditing {
                        viewModel.validateFirstName()
                    }
                }
            )
            .textContentType(.givenName)
            .autocapitalization(.words)
            
            // Apellido
            CustomTextField(
                title: "last_name".localized,
                placeholder: "last_name_placeholder".localized,
                type: .regular,
                state: viewModel.lastNameState,
                text: $viewModel.lastName,
                onEditingChanged: { isEditing in
                    if !isEditing {
                        viewModel.validateLastName()
                    }
                }
            )
            .textContentType(.familyName)
            .autocapitalization(.words)
            
            // Email
            CustomTextField(
                title: "email".localized,
                placeholder: "email_placeholder".localized,
                type: .regular,
                state: viewModel.emailState,
                text: $viewModel.email,
                onEditingChanged: { isEditing in
                    if !isEditing {
                        viewModel.validateEmail()
                    }
                }
            )
            .textContentType(.emailAddress)
            .keyboardType(.emailAddress)
            .autocapitalization(.none)
            
            // Contraseña
            CustomTextField(
                title: "password".localized,
                placeholder: "password_placeholder".localized,
                type: .secure,
                state: viewModel.passwordState,
                text: $viewModel.password,
                onEditingChanged: { isEditing in
                    if !isEditing {
                        viewModel.validatePassword()
                    }
                }
            )
            .textContentType(.newPassword)
            
            // Confirmar contraseña
            CustomTextField(
                title: "confirm_password".localized,
                placeholder: "confirm_password_placeholder".localized,
                type: .secure,
                state: viewModel.confirmPasswordState,
                text: $viewModel.confirmPassword,
                onEditingChanged: { isEditing in
                    if !isEditing {
                        viewModel.validateConfirmPassword()
                    }
                }
            )
            .textContentType(.newPassword)
            
            // Terms and conditions
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .center, spacing: 10) {
                    Toggle("", isOn: $viewModel.acceptTerms)
                        .labelsHidden()
                        .onChange(of: viewModel.acceptTerms) { _ in
                            viewModel.validateTerms()
                        }
                    
                    HStack(spacing: 0) {
                        Text("registration_accept_terms".localized)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("terms_and_conditions".localized)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }
                    .onTapGesture {
                        showTermsAndConditions = true
                    }
                }
                
                if case .invalid(let errorMessage) = viewModel.termsState {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.leading, 30)
                }
            }
            .padding(.vertical, 5)
        }
    }
}

struct TermsAndConditionsView: View {
    @Binding var isPresented: Bool
    @Environment(\.presentationMode) private var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    Group {
                        Text("terms_and_conditions".localized)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .padding(.bottom, 10)
                        
                        Text(String(format: "last_updated".localized, "24 de abril de 2025"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.bottom, 20)
                        
                        Text("agreement_to_terms".localized)
                            .font(.headline)
                        
                        Text("agreement_to_terms_text".localized)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Text("user_accounts".localized)
                            .font(.headline)
                            .padding(.top, 10)
                        
                        Text("user_accounts_text".localized)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Text("purchases_and_payments".localized)
                            .font(.headline)
                            .padding(.top, 10)
                        
                        Text("purchases_and_payments_text".localized)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    Group {
                        Text("privacy_policy_section".localized)
                            .font(.headline)
                            .padding(.top, 10)
                        
                        Text("privacy_policy_section_text".localized)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Text("product_information".localized)
                            .font(.headline)
                            .padding(.top, 10)
                        
                        Text("product_information_text".localized)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Text("limitations_of_liability".localized)
                            .font(.headline)
                            .padding(.top, 10)
                        
                        Text("limitations_of_liability_text".localized)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Text("governing_law".localized)
                            .font(.headline)
                            .padding(.top, 10)
                        
                        Text("governing_law_text".localized)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Text("i_accept".localized)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .padding(.top, 20)
                    }
                }
                .padding()
            }
            .navigationBarTitle("terms_and_conditions".localized, displayMode: .inline)
            .navigationBarItems(trailing:
                                Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("close".localized)
                    .foregroundColor(.blue)
            }
            )
        }
    }
}
