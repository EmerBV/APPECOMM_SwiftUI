import SwiftUI

struct PromotionBannerView: View {
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(0..<3) { index in
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Special Offer")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("Up to 50% off")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Limited time only")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .frame(width: 280, height: 120)
                    .padding()
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .blue.opacity(0.8)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal)
        }
    }
} 