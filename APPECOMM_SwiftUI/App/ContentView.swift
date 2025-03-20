//
//  ContentView.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 18/3/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var coordinator: AppCoordinator
    @ObservedObject private var notificationService = NotificationService.shared
    
    init() {
        let dependencies = DependencyInjector.shared
        let authRepository = dependencies.resolve(AuthRepositoryProtocol.self)
        let tokenManager = dependencies.resolve(TokenManagerProtocol.self)
        
        _coordinator = StateObject(wrappedValue: AppCoordinator(
            authRepository: authRepository,
            tokenManager: tokenManager
        ))
    }
    
    var body: some View {
        ZStack {
            mainContentView
                .onChange(of: coordinator.currentScreen) { newScreen in
                    Logger.info("Screen changed to: \(newScreen)")
                }
            
            NotificationOverlayView(notificationService: notificationService)
        }
    }
    
    @ViewBuilder
    private var mainContentView: some View {
        switch coordinator.currentScreen {
        case .splash:
            SplashView()
                .onAppear { Logger.info("SplashView appeared") }
                .transition(.opacity)
        case .login:
            LoginView(viewModel: DependencyInjector.shared.resolve(AuthViewModel.self))
                .onAppear { Logger.info("LoginView appeared") }
                .transition(.slide)
        case .main:
            MainTabView()
                .onAppear { Logger.info("MainTabView appeared") }
                .transition(.slide)
        }
    }
}

struct NotificationOverlayView: View {
    @ObservedObject var notificationService: NotificationService
    
    var body: some View {
        ZStack {
            if let notification = notificationService.currentNotification {
                VStack {
                    Spacer()
                    NotificationBannerView(
                        notification: notification,
                        onDismiss: notificationService.dismissCurrentNotification
                    )
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(), value: true)
                .zIndex(999)
            }
        }
    }
}

struct NotificationBannerView: View {
    let notification: NotificationMessage
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            NotificationIcon(type: notification.type)
            NotificationContent(notification: notification)
            DismissButton(action: onDismiss)
        }
        .padding()
        .background(notification.type.color)
        .cornerRadius(12)
        .shadow(
            color: .black.opacity(0.2),
            radius: 5,
            x: 0,
            y: 2
        )
        .padding(.horizontal)
        .padding(.bottom, 12)
    }
}

private struct NotificationIcon: View {
    let type: NotificationType
    
    var body: some View {
        Image(systemName: type.icon)
            .font(.system(size: 20))
            .foregroundColor(.white)
    }
}

private struct NotificationContent: View {
    let notification: NotificationMessage
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(notification.title)
                .font(.headline)
                .foregroundColor(.white)
            
            Text(notification.message)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.leading)
        }
    }
}

private struct DismissButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 24, height: 24)
        }
        .accessibilityLabel("Dismiss notification")
    }
}

