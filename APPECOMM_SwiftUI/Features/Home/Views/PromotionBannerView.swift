import SwiftUI

struct PromotionBannerView: View {
    @State private var currentIndex = 0
    
    private let promotions = [
        Promotion(
            id: "1",
            title: "summer_sale".localized,
            subtitle: "summer_sale_subtitle".localized,
            imageUrl: "https://example.com/summer-sale.jpg",
            actionTitle: "shop_now".localized,
            actionUrl: "https://example.com/summer-sale"
        ),
        Promotion(
            id: "2",
            title: "new_collection".localized,
            subtitle: "new_collection_subtitle".localized,
            imageUrl: "https://example.com/new-arrivals.jpg",
            actionTitle: "view_collection".localized,
            actionUrl: "https://example.com/new-arrivals"
        ),
        Promotion(
            id: "3",
            title: "special_offer".localized,
            subtitle: "special_offer_subtitle".localized,
            imageUrl: "https://example.com/special-offer.jpg",
            actionTitle: "learn_more".localized,
            actionUrl: "https://example.com/special-offer"
        )
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentIndex) {
                ForEach(Array(promotions.enumerated()), id: \.element.id) { index, promotion in
                    PromotionCard(promotion: promotion)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .frame(height: 200)
            
            // Indicadores de página personalizados
            HStack(spacing: 8) {
                ForEach(0..<promotions.count, id: \.self) { index in
                    Circle()
                        .fill(currentIndex == index ? Color.blue : Color.gray.opacity(0.5))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.top, 8)
        }
        .padding(.horizontal)
    }
}

private struct PromotionCard: View {
    let promotion: Promotion
    
    var body: some View {
        ZStack(alignment: .leading) {
            // Imagen de fondo
            if let imageUrl = promotion.imageUrl,
               let url = URL(string: imageUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        Color.gray.opacity(0.3)
                    @unknown default:
                        Color.gray
                    }
                }
            } else {
                Color.gray.opacity(0.3)
            }
            
            // Gradiente oscuro para mejorar la legibilidad
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0.7),
                    Color.black.opacity(0.3)
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
            
            // Contenido
            VStack(alignment: .leading, spacing: 8) {
                Text(promotion.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(promotion.subtitle)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
                
                if let actionUrl = promotion.actionUrl,
                   let url = URL(string: actionUrl) {
                    Link(destination: url) {
                        Text(promotion.actionTitle)
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .cornerRadius(20)
                    }
                }
            }
            .padding()
        }
        .cornerRadius(12)
    }
}

struct Promotion: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let imageUrl: String?
    let actionTitle: String
    let actionUrl: String?
} 