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
        _coordinator = StateObject(wrappedValue: AppCoordinator(authRepository: authRepository))
    }
    
    var body: some View {
        Group {
            switch coordinator.currentScreen {
            case .splash:
                SplashView()
            case .login:
                LoginView(viewModel: DependencyInjector.shared.resolve(AuthViewModel.self))
            case .main:
                MainTabView()
            }
        }
    }
}

struct SplashView: View {
    var body: some View {
        ZStack {
            Color.blue.edgesIgnoringSafeArea(.all)
            
            VStack {
                Image(systemName: "bag.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .foregroundColor(.white)
                
                Text("APPECOMM")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top, 16)
                
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .padding(.top, 32)
            }
        }
    }
}
