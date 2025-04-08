//
//  ToastView.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 8/4/25.
//

import SwiftUI

struct ToastView: View {
    let message: String
    let type: ToastType
    let duration: Double
    let onDismiss: () -> Void
    
    @State private var isAnimating = false
    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0.8
    @State private var backgroundOpacity: Double = 0
    
    init(
        message: String,
        type: ToastType = .success,
        duration: Double = 2.0,
        onDismiss: @escaping () -> Void = {}
    ) {
        self.message = message
        self.type = type
        self.duration = duration
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        ZStack {
            // Background overlay siempre presente para oscurecer la pantalla
            Color.black
                .opacity(backgroundOpacity)
                .edgesIgnoringSafeArea(.all)
                .transition(.opacity)
            
            // Toast container - más cuadrado y compacto
            VStack(spacing: 8) {
                // Icon with animation
                ZStack {
                    Circle()
                        .fill(type.backgroundColor.opacity(0.2))
                        .frame(width: 80, height: 80)
                    
                    if type == .success {
                        CheckmarkView(isAnimating: $isAnimating)
                            .frame(width: 60, height: 60) // Check más grande
                    } else {
                        Image(systemName: type.iconName)
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(type.foregroundColor)
                    }
                }
                
                // Message
                Text(message)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(type.foregroundColor)
                    .padding(.horizontal, 4)
                    .padding(.bottom, 8)
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 16)
            .frame(width: 180, height: 180) // Tamaño fijo cuadrado
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(type.backgroundColor)
                    .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
            )
            .opacity(opacity)
            .scaleEffect(scale)
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                opacity = 1
                scale = 1
                isAnimating = true
                backgroundOpacity = 0.3 // Oscurecer el fondo al aparecer
            }
            
            // Auto dismiss after duration
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                dismiss()
            }
        }
    }
    
    private func dismiss() {
        withAnimation(.easeOut(duration: 0.2)) {
            opacity = 0
            scale = 0.8
            backgroundOpacity = 0 // Volver a la normalidad al desaparecer
        }
        
        // Execute onDismiss callback after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onDismiss()
        }
    }
}

// Checkmark animation view con trazo más grueso
struct CheckmarkView: View {
    @Binding var isAnimating: Bool
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.green)
            
            Path { path in
                path.move(to: CGPoint(x: 15, y: 30))
                path.addLine(to: CGPoint(x: 25, y: 40))
                path.addLine(to: CGPoint(x: 45, y: 20))
            }
            .trim(from: 0, to: isAnimating ? 1 : 0)
            .stroke(Color.white, style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round)) // Trazo más grueso
            .animation(.easeInOut(duration: 0.5).delay(0.2), value: isAnimating)
        }
    }
}

// Toast presentation modifier
struct ToastModifier: ViewModifier {
    @Binding var isPresented: Bool
    let message: String
    let type: ToastType
    let duration: Double
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if isPresented {
                ToastView(
                    message: message,
                    type: type,
                    duration: duration
                ) {
                    isPresented = false
                }
                .transition(.opacity)
                .zIndex(999)
            }
        }
    }
}

// Toast type with customization options
enum ToastType {
    case success
    case error
    case info
    case warning
    case fullscreen
    
    var iconName: String {
        switch self {
        case .success:
            return "checkmark.circle.fill"
        case .error:
            return "xmark.circle.fill"
        case .info:
            return "info.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .fullscreen:
            return "checkmark.circle.fill"
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .success, .fullscreen:
            return Color.white
        case .error:
            return Color.red.opacity(0.9)
        case .info:
            return Color.blue.opacity(0.9)
        case .warning:
            return Color.orange.opacity(0.9)
        }
    }
    
    var foregroundColor: Color {
        switch self {
        case .success, .fullscreen:
            return Color.green
        case .error, .info, .warning:
            return Color.white
        }
    }
}

// View extension for easier usage
extension View {
    func toast(
        isPresented: Binding<Bool>,
        message: String,
        type: ToastType = .success,
        duration: Double = 2.0
    ) -> some View {
        self.modifier(
            ToastModifier(
                isPresented: isPresented,
                message: message,
                type: type,
                duration: duration
            )
        )
    }
}

// Preview
#Preview {
    struct ToastDemoView: View {
        @State private var showToast = false
        
        var body: some View {
            VStack {
                Button("Show Success Toast") {
                    showToast = true
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .toast(isPresented: $showToast, message: "Product added to cart successfully!", type: .success)
        }
    }
    
    return ToastDemoView()
}
