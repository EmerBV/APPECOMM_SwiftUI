//
//  LoginView.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 19/3/25.
//

import SwiftUI

struct LoginView: View {
    @ObservedObject var viewModel: AuthViewModel
    @Environment(\.colorScheme) var colorScheme
    @State private var isKeyboardVisible = false
    @State private var showBiometricPrompt = false
    
    var body: some View {
        GeometryReader { geometry in
            NavigationView {
                ScrollView {
                    VStack(spacing: 30) {
                        // Espaciador superior - se ajusta cuando el teclado está visible
                        if !isKeyboardVisible {
                            Spacer().frame(height: geometry.size.height * 0.05)
                        }
                        
                        // Logo y título
                        VStack(spacing: 16) {
                            Image("logo")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 100, height: 100)
                            
                            Text("Welcome to Kaioland")
                                .font(.title)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.primary)
                            
                            Text("Sign in to your account")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.bottom, isKeyboardVisible ? 10 : 30)
                        
                        // Login Form
                        VStack(spacing: 20) {
                            // Email field
                            CustomTextField(
                                title: "Email",
                                placeholder: "example@email.com",
                                type: .regular,
                                state: viewModel.emailState,
                                text: $viewModel.email,
                                onEditingChanged: { isEditing in
                                    if !isEditing && !viewModel.email.isEmpty {
                                        viewModel.validateEmail()
                                    }
                                }
                            )
                            
                            // Password field
                            CustomTextField(
                                title: "Password",
                                placeholder: "Your password",
                                type: .secure,
                                state: viewModel.passwordState,
                                text: $viewModel.password,
                                onEditingChanged: { isEditing in
                                    if !isEditing && !viewModel.password.isEmpty {
                                        viewModel.validatePassword()
                                    }
                                }
                            )
                            
                            // Forgot password
                            HStack {
                                Spacer()
                                Button(action: {
                                    // Mostrar pantalla de recuperación de contraseña
                                    NotificationService.shared.showInfo(
                                        title: "Recuperación de contraseña",
                                        message: "Esta función estará disponible próximamente."
                                    )
                                }) {
                                    Text("Forgot your password?")
                                        .font(.footnote)
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(.top, -10)
                            
                            // Remember me
                            if !isKeyboardVisible {
                                Toggle(isOn: $viewModel.rememberMe) {
                                    Text("Remember me")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 5)
                            }
                            
                            // Login button
                            PrimaryButton(
                                title: "Sign In",
                                isLoading: viewModel.isLoginInProgress,
                                isEnabled: viewModel.isFormValid,
                                action: {
                                    // Ocultar teclado
                                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                    viewModel.login()
                                }
                            )
                            .padding(.top, 10)
                            
                            // Separator
                            if !isKeyboardVisible {
                                HStack {
                                    VStack { Divider() }
                                    
                                    Text("or")
                                        .font(.footnote)
                                        .foregroundColor(.secondary)
                                    
                                    VStack { Divider() }
                                }
                                .padding(.vertical, 10)
                                
                                // Biometric login
                                if viewModel.isBiometricAvailable {
                                    Button(action: {
                                        showBiometricPrompt = true
                                    }) {
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
                                
                                // Register button
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
                        }
                        .padding(.horizontal)
                    }
                    .padding()
                    .frame(minHeight: geometry.size.height - (isKeyboardVisible ? 0 : 20))
                }
                .background(backgroundColor.edgesIgnoringSafeArea(.all))
                .navigationBarHidden(true)
                .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
                    isKeyboardVisible = true
                }
                .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                    isKeyboardVisible = false
                }
                .alert(isPresented: $viewModel.showAuthAlert) {
                    Alert(
                        title: Text(viewModel.authAlertTitle),
                        message: Text(viewModel.authAlertMessage),
                        dismissButton: .default(Text("OK"))
                    )
                }
                .sheet(isPresented: $showBiometricPrompt) {
                    BiometricAuthView(
                        onSuccess: {
                            showBiometricPrompt = false
                            viewModel.loginWithBiometrics()
                        },
                        onFailure: { error in
                            showBiometricPrompt = false
                            if let error = error {
                                NotificationService.shared.showError(
                                    title: "Error de autenticación",
                                    message: error.localizedDescription
                                )
                            }
                        },
                        biometricType: viewModel.biometricType
                    )
                }
            }
            .accentColor(.blue)
        }
    }
    
    private var backgroundColor: Color {
        colorScheme == .dark ? Color.black : Color.white
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
