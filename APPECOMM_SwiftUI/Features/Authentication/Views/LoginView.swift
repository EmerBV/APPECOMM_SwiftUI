//
//  LoginView.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 19/3/25.
//

import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel: AuthViewModel
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.scenePhase) private var scenePhase
    @State private var isKeyboardVisible = false
    @State private var showBiometricPrompt = false
    
    init(viewModel: AuthViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        GeometryReader { geometry in
            NavigationView {
                VStack(spacing: 30) {
                    if !isKeyboardVisible {
                        Spacer()
                            .frame(height: geometry.size.height * 0.05)
                            .accessibilityHidden(true)
                    }
                    
                    LogoHeaderView()
                        .padding(.bottom, isKeyboardVisible ? 10 : 30)
                    
                    LoginFormView(
                        viewModel: viewModel,
                        isKeyboardVisible: isKeyboardVisible,
                        showBiometricPrompt: $showBiometricPrompt
                    )
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(backgroundColor.edgesIgnoringSafeArea(.all))
                .navigationBarHidden(true)
                .keyboardAdaptive(isKeyboardVisible: $isKeyboardVisible)
                .alert(isPresented: $viewModel.showAuthAlert) {
                    Alert(
                        title: Text(viewModel.authAlertTitle),
                        message: Text(viewModel.authAlertMessage),
                        dismissButton: .default(Text("OK"))
                    )
                }
                .sheet(isPresented: $showBiometricPrompt) {
                    BiometricAuthView(
                        onSuccess: handleBiometricSuccess,
                        onFailure: handleBiometricFailure,
                        biometricType: viewModel.biometricType
                    )
                }
                .onChange(of: scenePhase) { phase in
                    if phase == .active {
                        viewModel.checkBiometricAvailability()
                    }
                }
            }
            .accentColor(.blue)
        }
    }
    
    private var backgroundColor: Color {
        colorScheme == .dark ? .black : .white
    }
    
    private func handleBiometricSuccess() {
        showBiometricPrompt = false
        Task {
            await viewModel.loginWithBiometrics()
        }
    }
    
    private func handleBiometricFailure(_ error: Error?) {
        showBiometricPrompt = false
        if let error = error {
            NotificationService.shared.showError(
                title: "Authentication Error",
                message: error.localizedDescription
            )
        }
    }
}

private struct LogoHeaderView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image("logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
                .accessibilityLabel("App Logo")
            
            Text("Welcome to Kaioland")
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)
                .accessibilityAddTraits(.isHeader)
            
            Text("Sign in to your account")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

private struct LoginFormView: View {
    @ObservedObject var viewModel: AuthViewModel
    let isKeyboardVisible: Bool
    @Binding var showBiometricPrompt: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            emailField
            passwordField
            forgotPasswordButton
            
            if !isKeyboardVisible {
                rememberMeToggle
            }
            
            loginButton
            
            if !isKeyboardVisible {
                divider
                if viewModel.isBiometricAvailable {
                    biometricLoginButton
                }
                registerButton
            }
        }
    }
    
    private var emailField: some View {
        CustomTextField(
            title: "Email",
            placeholder: "example@email.com",
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
    }
    
    private var passwordField: some View {
        CustomTextField(
            title: "Password",
            placeholder: "Your password",
            type: .secure,
            state: viewModel.passwordState,
            text: $viewModel.password,
            onEditingChanged: { isEditing in
                if !isEditing {
                    viewModel.validatePassword()
                }
            }
        )
        .textContentType(.password)
    }
    
    private var forgotPasswordButton: some View {
        HStack {
            Spacer()
            Button(action: handleForgotPassword) {
                Text("Forgot your password?")
                    .font(.footnote)
                    .foregroundColor(.blue)
            }
        }
        .padding(.top, -10)
    }
    
    private var rememberMeToggle: some View {
        Toggle(isOn: $viewModel.rememberMe) {
            Text("Remember me")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 5)
    }
    
    private var loginButton: some View {
        PrimaryButton(
            title: ("login_button".localized),
            isLoading: viewModel.isLoginInProgress,
            isEnabled: viewModel.isFormValid
        ) {
            hideKeyboard()
            Task {
                await viewModel.login()
            }
        }
        .padding(.top, 10)
    }
    
    private var divider: some View {
        HStack {
            VStack { Divider() }
            Text("or")
                .font(.footnote)
                .foregroundColor(.secondary)
            VStack { Divider() }
        }
        .padding(.vertical, 10)
    }
    
    @ViewBuilder
    private var biometricLoginButton: some View {
        if viewModel.isBiometricAvailable {
            Button(action: { showBiometricPrompt = true }) {
                HStack {
                    Image(systemName: viewModel.biometricType == .face ? "faceid" : "touchid")
                        .font(.headline)
                    Text("Sign in with \(viewModel.biometricType == .face ? "Face ID" : "Touch ID")")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray6))
                .foregroundColor(.primary)
                .cornerRadius(10)
            }
            .padding(.bottom, 10)
        }
    }
    
    private var registerButton: some View {
        NavigationLink(destination: RegistrationView()) {
            Text("Create an account")
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray6))
                .foregroundColor(.primary)
                .cornerRadius(10)
        }
    }
    
    private func handleForgotPassword() {
        NotificationService.shared.showInfo(
            title: "Password Recovery",
            message: "This feature will be available soon."
        )
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

// Vista para autenticación biométrica
struct BiometricAuthView: View {
    let onSuccess: () -> Void
    let onFailure: (Error?) -> Void
    let biometricType: UIBiometricType
    
    @Environment(\.presentationMode) var presentationMode
    @State private var isAuthenticating = true
    @State private var error: Error?
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: biometricType == .face ? "faceid" : "touchid")
                .font(.system(size: 64))
                .foregroundColor(.blue)
            
            Text("Authenticate with \(biometricType == .face ? "Face ID" : "Touch ID")")
                .font(.title2)
                .fontWeight(.bold)
            
            if isAuthenticating {
                ProgressView()
                    .padding()
            }
            
            if let error = error {
                Text(error.localizedDescription)
                    .font(.callout)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            
            Button(action: {
                presentationMode.wrappedValue.dismiss()
                onFailure(nil)
            }) {
                Text("Cancel")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray5))
                    .foregroundColor(.primary)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
        .onAppear {
            // Simular autenticación biométrica
            // En un caso real, aquí utilizarías el framework LocalAuthentication
            // para realizar la autenticación biométrica
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                isAuthenticating = false
                // Simular éxito de autenticación (70% de probabilidad)
                let success = Int.random(in: 0...100) <= 70
                
                if success {
                    onSuccess()
                } else {
                    error = NSError(domain: "BiometricAuth", code: 0, userInfo: [NSLocalizedDescriptionKey: "Authentication failed"])
                }
            }
        }
    }
}

// Tipo de autenticación biométrica
enum UIBiometricType {
    case none
    case touch
    case face
}

// Placeholder para la vista de registro
struct RegistrationView: View {
    var body: some View {
        Text("Registration Screen")
            .navigationTitle("Create Account")
    }
}
