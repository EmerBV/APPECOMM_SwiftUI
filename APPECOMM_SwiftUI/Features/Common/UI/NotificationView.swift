//
//  NotificationView.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 19/3/25.
//

import Foundation
import SwiftUI

enum NotificationType {
    case info
    case success
    case warning
    case error
    
    var color: Color {
        switch self {
        case .info: return Color.blue
        case .success: return Color.green
        case .warning: return Color.orange
        case .error: return Color.red
        }
    }
    
    var icon: String {
        switch self {
        case .info: return "info.circle.fill"
        case .success: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error: return "exclamationmark.circle.fill"
        }
    }
}

struct NotificationMessage: Identifiable {
    let id = UUID()
    let type: NotificationType
    let title: String
    let message: String
    let duration: TimeInterval
    let action: (() -> Void)?
    
    init(
        type: NotificationType,
        title: String,
        message: String,
        duration: TimeInterval = 3.0, action: (() -> Void)? = nil
    ) {
        self.type = type
        self.title = title
        self.message = message
        self.duration = duration
        self.action = action
    }
}

class NotificationService: ObservableObject {
    static let shared = NotificationService()
    
    @Published var currentNotification: NotificationMessage?
    private var notificationQueue: [NotificationMessage] = []
    private var isShowingNotification = false
    
    private init() {}
    
    func showNotification(_ notification: NotificationMessage) {
        // Añadir a la cola
        notificationQueue.append(notification)
        
        // Si no estamos mostrando una notificación, mostrar la siguiente
        if !isShowingNotification {
            showNextNotification()
        }
    }
    
    func showInfo(title: String, message: String, duration: TimeInterval = 3.0, action: (() -> Void)? = nil) {
        let notification = NotificationMessage(type: .info, title: title, message: message, duration: duration, action: action)
        showNotification(notification)
    }
    
    func showSuccess(title: String, message: String, duration: TimeInterval = 3.0, action: (() -> Void)? = nil) {
        let notification = NotificationMessage(type: .success, title: title, message: message, duration: duration, action: action)
        showNotification(notification)
    }
    
    func showWarning(title: String, message: String, duration: TimeInterval = 4.0, action: (() -> Void)? = nil) {
        let notification = NotificationMessage(type: .warning, title: title, message: message, duration: duration, action: action)
        showNotification(notification)
    }
    
    func showError(title: String, message: String, duration: TimeInterval = 5.0, action: (() -> Void)? = nil) {
        let notification = NotificationMessage(type: .error, title: title, message: message, duration: duration, action: action)
        showNotification(notification)
    }
    
    private func showNextNotification() {
        // Si no hay más notificaciones en la cola, terminar
        guard !notificationQueue.isEmpty else {
            isShowingNotification = false
            return
        }
        
        // Mostrar la siguiente notificación
        isShowingNotification = true
        let notification = notificationQueue.removeFirst()
        
        DispatchQueue.main.async {
            self.currentNotification = notification
            
            // Ocultar después del tiempo especificado
            DispatchQueue.main.asyncAfter(deadline: .now() + notification.duration) {
                self.currentNotification = nil
                
                // Esperar un poco entre notificaciones
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.showNextNotification()
                }
            }
        }
    }
    
    func dismissCurrentNotification() {
        currentNotification = nil
        
        // Esperar un poco antes de mostrar la siguiente
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.showNextNotification()
        }
    }
}

struct NotificationView: View {
    @ObservedObject private var notificationService = NotificationService.shared
    
    var body: some View {
        ZStack {
            if let notification = notificationService.currentNotification {
                VStack {
                    Spacer()
                    
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
                            
                            if let action = notification.action {
                                action()
                            }
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
                    .animation(.spring())
                }
                .zIndex(1000)
            }
        }
        .animation(.spring())
    }
}

