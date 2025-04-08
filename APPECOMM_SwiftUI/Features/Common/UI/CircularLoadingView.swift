//
//  CircularLoadingView.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 8/4/25.
//

import SwiftUI

struct CircularLoadingView: View {
    // Propiedades personalizables
    var logoImageName: String = "logo" // Nombre del logo en Assets
    var message: String? = nil
    var strokeColor: Color = .black
    var backgroundColor: Color = .white
    var showBackdrop: Bool = true
    var containerSize: CGFloat = 200
    var logoSize: CGFloat = 120
    
    // Estados para animaciones
    @State private var rotation: Double = 0
    @State private var trimEnd: CGFloat = 0
    @State private var logoOpacity: Double = 0
    
    var body: some View {
        ZStack {
            // Fondo oscuro si se solicita
            if showBackdrop {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                    .accessibilityHidden(true)
            }
            
            // Contenedor principal
            VStack(spacing: 20) {
                // Círculo con borde animado
                ZStack {
                    // Fondo del círculo
                    Circle()
                        .fill(backgroundColor)
                        .frame(width: containerSize, height: containerSize)
                    
                    // Logo centrado
                    if UIImage(named: logoImageName) != nil {
                        Image(logoImageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: logoSize, height: logoSize)
                            .opacity(logoOpacity)
                    } else {
                        // Logo placeholder si no se encuentra la imagen
                        Text("LOGO")
                            .font(.system(size: 24, weight: .bold))
                            .opacity(logoOpacity)
                    }
                    
                    // Borde animado - trazo completo de fondo
                    Circle()
                        .stroke(strokeColor.opacity(0.2), lineWidth: 6)
                        .frame(width: containerSize, height: containerSize)
                    
                    // Borde animado - trazo en movimiento
                    Circle()
                        .trim(from: 0, to: trimEnd)
                        .stroke(strokeColor, lineWidth: 6)
                        .frame(width: containerSize, height: containerSize)
                        .rotationEffect(Angle(degrees: rotation))
                }
                
                // Mensaje opcional
                if let message = message, !message.isEmpty {
                    Text(message)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(20)
        }
        .onAppear {
            startAnimations()
        }
    }
    
    private func startAnimations() {
        // Mostrar logo con fade in
        withAnimation(.easeIn(duration: 0.5)) {
            logoOpacity = 1.0
        }
        
        // Animar trazo circular
        withAnimation(Animation.linear(duration: 2).repeatForever(autoreverses: false)) {
            trimEnd = 0.75 // Trazo del 75% del círculo
            rotation = 360 // Rotación completa
        }
    }
}

// Versión alternativa con un "punteado" giratorio, estilo Apple
struct SpinningLoaderView: View {
    var logoImageName: String = "store-logo"
    var message: String? = nil
    var strokeColor: Color = .black
    var backgroundColor: Color = .white
    var showBackdrop: Bool = true
    var containerSize: CGFloat = 200
    var logoSize: CGFloat = 120
    
    @State private var rotation: Double = 0
    @State private var logoOpacity: Double = 0
    
    var body: some View {
        ZStack {
            if showBackdrop {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
            }
            
            VStack(spacing: 20) {
                ZStack {
                    // Fondo circular
                    Circle()
                        .fill(backgroundColor)
                        .frame(width: containerSize, height: containerSize)
                    
                    // Logo
                    if UIImage(named: logoImageName) != nil {
                        Image(logoImageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: logoSize, height: logoSize)
                            .opacity(logoOpacity)
                    } else {
                        Text("LOGO")
                            .font(.title)
                            .fontWeight(.bold)
                            .opacity(logoOpacity)
                    }
                    
                    // Arcos giratorios
                    ForEach(0..<8) { index in
                        Arc(
                            startAngle: .degrees(Double(index) * 45),
                            endAngle: .degrees(Double(index) * 45 + 30),
                            clockwise: true
                        )
                        .stroke(
                            strokeColor.opacity(Double(index) / 10 + 0.3),
                            lineWidth: 3
                        )
                        .frame(width: containerSize - 6, height: containerSize - 6)
                    }
                    .rotationEffect(Angle(degrees: rotation))
                }
                
                if let message = message, !message.isEmpty {
                    Text(message)
                        .font(.system(size: 16))
                        .foregroundColor(.primary)
                }
            }
            .padding(20)
        }
        .onAppear {
            withAnimation(.easeIn(duration: 0.5)) {
                logoOpacity = 1.0
            }
            
            withAnimation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}

// Forma de arco para la animación punteada
struct Arc: Shape {
    var startAngle: Angle
    var endAngle: Angle
    var clockwise: Bool
    
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        
        var path = Path()
        path.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: clockwise
        )
        
        return path
    }
}

// Extensión para ofrecer el componente como modificador
extension View {
    func circularLoading(
        isLoading: Bool,
        logoImageName: String = "logo",
        message: String? = nil,
        strokeColor: Color = .black,
        backgroundColor: Color = .white,
        showBackdrop: Bool = true,
        containerSize: CGFloat = 200,
        logoSize: CGFloat = 120
    ) -> some View {
        ZStack {
            self
            
            if isLoading {
                CircularLoadingView(
                    logoImageName: logoImageName,
                    message: message,
                    strokeColor: strokeColor,
                    backgroundColor: backgroundColor,
                    showBackdrop: showBackdrop,
                    containerSize: containerSize,
                    logoSize: logoSize
                )
            }
        }
    }
    
    func spinningLoading(
        isLoading: Bool,
        logoImageName: String = "store-logo",
        message: String? = nil,
        strokeColor: Color = .black,
        backgroundColor: Color = .white,
        showBackdrop: Bool = true,
        containerSize: CGFloat = 200,
        logoSize: CGFloat = 120
    ) -> some View {
        ZStack {
            self
            
            if isLoading {
                SpinningLoaderView(
                    logoImageName: logoImageName,
                    message: message,
                    strokeColor: strokeColor,
                    backgroundColor: backgroundColor,
                    showBackdrop: showBackdrop,
                    containerSize: containerSize,
                    logoSize: logoSize
                )
            }
        }
    }
}

// Vista de previsualización
struct CircularLoadingView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Versión con trazo circular
            CircularLoadingView(message: "Cargando...")
                .previewDisplayName("Trazo circular")
            
            // Versión con arcos giratorios
            SpinningLoaderView(message: "Cargando...")
                .previewDisplayName("Arcos giratorios")
            
            // Sin mensaje
            CircularLoadingView()
                .previewDisplayName("Sin mensaje")
            
            // Personalizado
            CircularLoadingView(
                message: "Procesando...",
                strokeColor: .blue,
                backgroundColor: .gray.opacity(0.1),
                showBackdrop: false,
                containerSize: 250,
                logoSize: 150
            )
            .previewDisplayName("Personalizado")
        }
    }
}
