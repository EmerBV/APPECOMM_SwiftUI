import SwiftUI

struct WhyShopSection: View {
    var body: some View {
        VStack(spacing: 24) {
            // Título principal
            VStack(spacing: 16) {
                Text("why_shop_title".localized)
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("why_shop_subtitle".localized)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            // Grid de beneficios
            VStack(spacing: 16) {
                HStack(spacing: 16) {
                    BenefitCard(
                        icon: "gift",
                        title: "rewards_title".localized,
                        description: "rewards_description".localized
                    )
                    
                    BenefitCard(
                        icon: "list.clipboard.fill",
                        title: "rsvp_title".localized,
                        description: "rsvp_description".localized
                    )
                }
                
                HStack(spacing: 16) {
                    BenefitCard(
                        icon: "creditcard",
                        title: "payment_title".localized,
                        description: "payment_description".localized
                    )
                    
                    BenefitCard(
                        icon: "ticket",
                        title: "contests_title".localized,
                        description: "contests_description".localized
                    )
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 24)
    }
}

private struct BenefitCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(alignment: .center, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(.blue)
            
            Text(title)
                .font(.caption)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 160) // Altura fija para todas las tarjetas
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
} 