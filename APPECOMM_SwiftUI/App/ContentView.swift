//
//  ContentView.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 18/3/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject var coordinator: AppCoordinator
    @ObservedObject private var notificationService = NotificationService.shared
    
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
        ZStack {
            // Contenido principal con AnyView para resolver problemas de tipado
            contentView
                .onChange(of: coordinator.currentScreen) { newValue in
                    Logger.info("ContentView: Screen changed to \(newValue)")
                }
            
            // Overlay de notificaciones (integrado directamente aquí)
            notificationOverlay
        }
    }
    
    // Vista del contenido principal extraída a una propiedad computada
    private var contentView: some View {
        switch coordinator.currentScreen {
        case .splash:
            return AnyView(
                SplashView()
                    .onAppear {
                        Logger.info("ContentView: SplashView appeared")
                    }
            )
        case .login:
            return AnyView(
                LoginView(viewModel: DependencyInjector.shared.resolve(AuthViewModel.self))
                    .onAppear {
                        Logger.info("ContentView: LoginView appeared")
                    }
            )
        case .main:
            return AnyView(
                MainTabView()
                    .onAppear {
                        Logger.info("ContentView: MainTabView appeared")
                    }
            )
        }
    }
    
    // Overlay de notificaciones extraído a una propiedad computada
    private var notificationOverlay: some View {
        ZStack {
            if let notification = notificationService.currentNotification {
                VStack {
                    Spacer()
                    
                    // El contenido de la notificación
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: notification.type.icon)
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(notification.title)
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text(notification.message)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.9))
                                .multilineTextAlignment(.leading)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            notificationService.dismissCurrentNotification()
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white.opacity(0.7))
                                .frame(width: 24, height: 24)
                        }
                    }
                    .padding()
                    .background(notification.type.color)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
                    .padding(.horizontal)
                    .padding(.bottom, 12)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .animation(.spring(), value: true)
            }
        }
        .zIndex(999)
    }
}

