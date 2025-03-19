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
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundColor
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        // Logo
                        VStack(spacing: 16) {
                            Image("logo")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 100, height: 100)
                                .padding(.top, 50)
                            
                            Text("Welcome to Kaioland")
                                .font(.title)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)
                            
                            Text("Sign in to your account")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.bottom, 20)
                        
                        // Login Form
                        VStack(spacing: 20) {
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
                                    // Acción para recuperar contraseña
                                }) {
                                    Text("Forgot your password?")
                                        .font(.footnote)
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(.top, -10)
                            
                            // Login button
                            PrimaryButton(
                                title: "Sign In",
                                isLoading: viewModel.isLoginInProgress,
                                isEnabled: viewModel.isFormValid,
                                action: {
                                    viewModel.login()
                                }
                            )
                            .padding(.top, 10)
                            
                            // Separator
                            HStack {
                                VStack { Divider() }
                                
                                Text("or")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                                
                                VStack { Divider() }
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
                        .padding(.horizontal)
                    }
                    .padding()
                }
                
                // Error message
                if let errorMessage = viewModel.errorMessage {
                    ErrorToast(message: errorMessage) {
                        viewModel.errorMessage = nil
                    }
                }
                
                // Loading overlay
                if viewModel.isLoginInProgress {
                    LoadingView()
                        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("UserLoggedIn"))) { _ in
                            print("LoginView: Received UserLoggedIn notification")
                        }
                }
                
            }
            .navigationBarHidden(true)
        }
        .accentColor(.blue)
    }
    
    private var backgroundColor: Color {
        colorScheme == .dark ? Color.black : Color.white
    }
}

// Placeholder para la vista de registro
struct RegistrationView: View {
    var body: some View {
        Text("Registration Screen")
            .navigationTitle("Create Account")
    }
}
