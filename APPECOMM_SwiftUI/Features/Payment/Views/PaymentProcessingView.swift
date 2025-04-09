//
//  PaymentProcessingView.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 9/4/25.
//

import SwiftUI

struct PaymentProcessingView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            ProcessingAnimation()
                .frame(width: 200, height: 200)
            
            Text("Processing Your Payment")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Please wait while we process your payment...")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
        }
        .padding()
        .navigationBarBackButtonHidden(true)
    }
}

struct ProcessingAnimation: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Outer circle
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 10)
                .frame(width: 150, height: 150)
            
            // Animated arc
            Circle()
                .trim(from: 0, to: 0.8)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [.blue, .purple]),
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .frame(width: 150, height: 150)
                .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
                .animation(
                    Animation.linear(duration: 1)
                        .repeatForever(autoreverses: false),
                    value: isAnimating
                )
                .onAppear {
                    isAnimating = true
                }
            
            // Credit card icon
            Image(systemName: "creditcard.fill")
                .font(.system(size: 40))
                .foregroundColor(.blue)
        }
    }
}
