//
//  CustomLoadingView.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 8/4/25.
//

import SwiftUI

struct CustomLoadingView: View {
    // Propiedades personalizables
    var message: String?
    var color: Color = .blue
    var secondaryColor: Color = .blue.opacity(0.3)
    var showBackdrop: Bool = true
    
    // Estado para animaciones
    @State private var isAnimating = false
    @State private var rotation: Double = 0
    @State private var scaleEffect: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // Fondo oscuro si se solicita
            if showBackdrop {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                    .accessibilityHidden(true)
            }
            
            VStack(spacing: 20) {
                // Indicador de carga personalizado
                ZStack {
                    // Círculo de fondo
                    Circle()
                        .stroke(secondaryColor, lineWidth: 6)
                        .frame(width: 60, height: 60)
                    
                    // Arco animado
                    Circle()
                        .trim(from: 0, to: 0.75)
                        .stroke(
                            color,
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .frame(width: 60, height: 60)
                        .rotationEffect(Angle(degrees: rotation))
                    
                    // Animación de pulso superpuesta
                    Circle()
                        .fill(color.opacity(0.1))
                        .frame(width: 80, height: 80)
                        .scaleEffect(scaleEffect)
                        .opacity(isAnimating ? 0.2 : 0.5)
                }
                
                // Mensaje de carga (solo si se proporciona)
                if let message = message, !message.isEmpty {
                    Text(message)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .accessibilityLabel(message)
                        .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
                }
            }
            .padding(32)
            
            /*
             .background(
             RoundedRectangle(cornerRadius: 16)
             .fill(Color(.systemBackground).opacity(0.8))
             .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
             .blur(radius: 0.5)
             )
             */
            
        }
        .onAppear {
            // Iniciar animaciones
            withAnimation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                rotation = 360
            }
            
            withAnimation(Animation.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                scaleEffect = 1.2
                isAnimating = true
            }
        }
        .ignoresSafeArea()
    }
}

// Extensión para presentar el loading como un modificador
extension View {
    func customLoading(
        isLoading: Bool,
        message: String? = nil,
        color: Color = .blue,
        secondaryColor: Color = .blue.opacity(0.3),
        showBackdrop: Bool = true
    ) -> some View {
        ZStack {
            self
            
            if isLoading {
                CustomLoadingView(
                    message: message,
                    color: color,
                    secondaryColor: secondaryColor,
                    showBackdrop: showBackdrop
                )
            }
        }
    }
}

// Dos variantes adicionales de animación de carga
struct DotsLoadingView: View {
    @State private var animation = false
    var color: Color = .blue
    var message: String?
    
    var body: some View {
        VStack(spacing: 24) {
            HStack(spacing: 12) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(color)
                        .frame(width: 16, height: 16)
                        .scaleEffect(animation ? 1.0 : 0.5)
                        .opacity(animation ? 1.0 : 0.3)
                        .animation(
                            Animation
                                .easeInOut(duration: 0.6)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.2),
                            value: animation
                        )
                }
            }
            
            if let message = message, !message.isEmpty {
                Text(message)
                    .font(.headline)
                    .foregroundColor(.white)
            }
        }
        .padding(30)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6).opacity(0.9))
                .shadow(radius: 8)
        )
        .onAppear {
            animation = true
        }
    }
}

struct PulseLoadingView: View {
    @State private var pulseAnimation1 = false
    @State private var pulseAnimation2 = false
    var color: Color = .blue
    var message: String?
    
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                // Primer pulso
                Circle()
                    .stroke(color.opacity(0.3), lineWidth: 6)
                    .frame(width: 70, height: 70)
                    .scaleEffect(pulseAnimation1 ? 1.5 : 1.0)
                    .opacity(pulseAnimation1 ? 0.0 : 0.6)
                
                // Segundo pulso
                Circle()
                    .stroke(color.opacity(0.6), lineWidth: 6)
                    .frame(width: 50, height: 50)
                    .scaleEffect(pulseAnimation2 ? 1.3 : 1.0)
                    .opacity(pulseAnimation2 ? 0.0 : 0.6)
                
                // Círculo central
                Circle()
                    .fill(color)
                    .frame(width: 30, height: 30)
            }
            
            if let message = message, !message.isEmpty {
                Text(message)
                    .font(.headline)
                    .foregroundColor(.white)
            }
        }
        .padding(30)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.7))
                .shadow(radius: 8)
        )
        .onAppear {
            // Animaciones continuas
            withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
                pulseAnimation1 = true
            }
            
            withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: false).delay(0.5)) {
                pulseAnimation2 = true
            }
        }
    }
}

// Preview para desarrollo
struct CustomLoadingView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Preview de pantalla completa con animación principal
            Color.white
                .overlay(
                    CustomLoadingView(message: "Loading data...")
                )
                .previewDisplayName("Custom Spinner")
            
            // Preview sin mensaje
            Color.white
                .overlay(
                    CustomLoadingView(color: .red)
                )
                .previewDisplayName("No Message")
            
            // Preview de animación alternativa con puntos
            Color.white
                .overlay(
                    DotsLoadingView(color: .purple, message: "Syncing...")
                )
                .previewDisplayName("Dots Animation")
            
            // Preview de animación alternativa con pulso
            Color.white
                .overlay(
                    PulseLoadingView(color: .orange, message: "Processing...")
                )
                .previewDisplayName("Pulse Animation")
            
            // Preview como modificador
            Text("Content behind loading")
                .font(.title)
                .customLoading(isLoading: true, message: "Please wait...", color: .green)
                .previewDisplayName("As Modifier")
            
            // Preview como modificador sin mensaje
            Text("Content with loading without text")
                .font(.title)
                .customLoading(isLoading: true, color: .blue)
                .previewDisplayName("Modifier No Message")
        }
    }
}
