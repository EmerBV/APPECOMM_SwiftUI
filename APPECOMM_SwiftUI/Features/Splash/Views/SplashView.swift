//
//  SplashView.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 19/3/25.
//

import SwiftUI

struct SplashView: View {
    @State private var isAnimating = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    // Inyectar el AuthRepository para verificar estado
    @StateObject private var viewModel = SplashViewModel(
        authRepository: DependencyInjector.shared.resolve(AuthRepositoryProtocol.self)
    )
    
    var body: some View {
        ZStack {
            // Fondo
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.blue]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 30) {
                // Logo
                Image("logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 220, height: 100)
                    .opacity(isAnimating ? 1 : 0)
                    .scaleEffect(isAnimating ? 1 : 0.8)
                
                if viewModel.isLoading {
                    // Indicador de progreso
                    VStack(spacing: 20) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                        
                        Text(viewModel.statusMessage)
                            .foregroundColor(.white)
                            .opacity(0.9)
                            .padding(.top, 10)
                    }
                    .opacity(isAnimating ? 1 : 0)
                }
                
                // Mensaje de error
                if showError {
                    VStack(spacing: 10) {
                        Text("splash_error".localized)
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button("splash_retry".localized) {
                            showError = false
                            viewModel.checkAuth()
                        }
                        .padding()
                        .background(Color.white)
                        .foregroundColor(.blue)
                        .cornerRadius(10)
                    }
                    .padding()
                    .background(Color.red.opacity(0.8))
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
            }
        }
        .onAppear {
            // Iniciar animación
            withAnimation(.easeOut(duration: 0.8)) {
                isAnimating = true
            }
            
            // Iniciar proceso de verificación después de la animación
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                viewModel.checkAuth()
            }
        }
        .onReceive(viewModel.$error) { error in
            if let error = error {
                errorMessage = error
                showError = true
            }
        }
    }
}
