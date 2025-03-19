//
//  ContentView.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 18/3/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject var coordinator: AppCoordinator
    
    init() {
        // Obtener las dependencias necesarias
        let authRepository = DependencyInjector.shared.resolve(AuthRepositoryProtocol.self)
        let tokenManager = DependencyInjector.shared.resolve(TokenManagerProtocol.self)
        _coordinator = StateObject(wrappedValue: AppCoordinator(
            authRepository: authRepository,
            tokenManager: tokenManager
        ))
    }
    
    var body: some View {
        Group {
            switch coordinator.currentScreen {
            case .splash:
                SplashView()
                    .onAppear {
                        print("ContentView: SplashView appeared")
                    }
            case .login:
                LoginView(viewModel: DependencyInjector.shared.resolve(AuthViewModel.self))
                    .onAppear {
                        print("ContentView: LoginView appeared")
                    }
            case .main:
                MainTabView()
                    .onAppear {
                        print("ContentView: MainTabView appeared")
                    }
            }
        }
        .onChange(of: coordinator.currentScreen) { newValue in
            print("ContentView: Screen changed to \(newValue)")
        }
    }
    
}

struct SplashView: View {
    var body: some View {
        ZStack {
            Color.blue.edgesIgnoringSafeArea(.all)
            
            VStack {
                Image("logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 220, height: 100)
                
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .padding(.top, 32)
            }
        }
        .onAppear {
            print("SplashView: appeared")
        }
    }
    
}
