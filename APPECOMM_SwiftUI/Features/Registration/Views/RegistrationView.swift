//
//  RegistrationView.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 24/4/25.
//

import SwiftUI

struct RegistrationView: View {
    @StateObject private var viewModel: RegistrationViewModel
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.colorScheme) private var colorScheme
    @State private var isKeyboardVisible = false
    @State private var showTermsAndConditions = false
    
    init() {
        _viewModel = StateObject(wrappedValue: DependencyInjector.shared.resolve(RegistrationViewModel.self))
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
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
                    
                    // Spacer para empujar el contenido hacia arriba
                    if !isKeyboardVisible {
                        Spacer()
                            .frame(height: 40)
                    }
                    
                    // Botón de registro
                    PrimaryButton(
                        title: "Sign Up",
                        isLoading: viewModel.isRegistering,
                        isEnabled: viewModel.isFormValid
                    ) {
                        hideKeyboard()
                        viewModel.register()
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                    
                    // Enlace para volver a iniciar sesión
                    if !isKeyboardVisible {
                        HStack {
                            Text("Already have an account?")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Button(action: {
                                presentationMode.wrappedValue.dismiss()
                            }) {
                                Text("Sign In")
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
            .navigationBarTitle("Create Account", displayMode: .large)
            .navigationBarItems(leading: BackButton {
                presentationMode.wrappedValue.dismiss()
            })
            .background(backgroundColor.edgesIgnoringSafeArea(.all))
            .keyboardAdaptive(isKeyboardVisible: $isKeyboardVisible)
            .onTapGesture {
                hideKeyboard()
            }
            
            .circularLoading(
                isLoading: viewModel.isRegistering,
                message: "Creating account...",
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
            
            Text("Create Your Account")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)
                .accessibilityAddTraits(.isHeader)
            
            Text("Join us and start shopping with exclusive benefits!")
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
                title: "First Name",
                placeholder: "Enter your first name",
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
                title: "Last Name",
                placeholder: "Enter your last name",
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
                title: "Email",
                placeholder: "Enter your email address",
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
                title: "Password",
                placeholder: "Create a password",
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
                title: "Confirm Password",
                placeholder: "Enter your password again",
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
                HStack(alignment: .top, spacing: 10) {
                    Toggle("", isOn: $viewModel.acceptTerms)
                        .labelsHidden()
                        .onChange(of: viewModel.acceptTerms) { _ in
                            viewModel.validateTerms()
                        }
                    
                    // Versión corregida usando HStack
                    HStack(spacing: 0) {
                        Text("I accept the")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text(" Terms and Conditions")
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

private struct BackButton: View {
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .foregroundColor(.blue)
                .imageScale(.large)
                .accessibilityLabel("Back")
        }
    }
}

struct TermsAndConditionsView: View {
    @Binding var isPresented: Bool
    @Environment(\.presentationMode) private var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Group {
                        Text("Terms and Conditions")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .padding(.bottom, 10)
                        
                        Text("Last Updated: April 24, 2025")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.bottom, 20)
                        
                        Text("1. Agreement to Terms")
                            .font(.headline)
                        
                        Text("By accessing and using the APPECOMM app, you agree to be bound by these Terms and Conditions and our Privacy Policy. If you do not agree to these Terms, you may not access or use the app.")
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Text("2. User Accounts")
                            .font(.headline)
                            .padding(.top, 10)
                        
                        Text("When you create an account with us, you must provide accurate, complete, and current information. You are responsible for maintaining the confidentiality of your account and password and for restricting access to your device.")
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Text("3. Purchases and Payments")
                            .font(.headline)
                            .padding(.top, 10)
                        
                        Text("By providing a payment method, you represent that you are authorized to use the designated payment method and that the payment information you provide is true and accurate.")
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    Group {
                        Text("4. Privacy Policy")
                            .font(.headline)
                            .padding(.top, 10)
                        
                        Text("Your privacy is important to us. Our Privacy Policy explains how we collect, use, disclose, and safeguard your information. By using our app, you consent to the data practices described in our Privacy Policy.")
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Text("5. Product Information")
                            .font(.headline)
                            .padding(.top, 10)
                        
                        Text("We strive to provide accurate product descriptions, pricing, and availability information, but we do not warrant that product descriptions or other content is accurate, complete, reliable, or error-free.")
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Text("6. Limitations of Liability")
                            .font(.headline)
                            .padding(.top, 10)
                        
                        Text("In no event shall APPECOMM be liable for any direct, indirect, punitive, incidental, special, or consequential damages arising out of, or in any way connected with, your use of this app or with the delay or inability to use this app.")
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Text("7. Governing Law")
                            .font(.headline)
                            .padding(.top, 10)
                        
                        Text("These Terms shall be governed by and construed in accordance with the laws of the state or country where APPECOMM is headquartered, without regard to its conflict of law provisions.")
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("I Accept")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.top, 20)
                }
                .padding()
            }
            .navigationBarTitle("Terms and Conditions", displayMode: .inline)
            .navigationBarItems(trailing:
                                    Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("Close")
                    .foregroundColor(.blue)
            }
            )
        }
    }
}
