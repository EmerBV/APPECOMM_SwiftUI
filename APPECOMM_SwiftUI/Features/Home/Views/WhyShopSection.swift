import SwiftUI

struct WhyShopSection: View {
    var body: some View {
        VStack(spacing: 24) {
            // Título principal
            VStack(spacing: 16) {
                Text("WHY SHOP WITH US?")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Shopping with us comes with unique perks not available anywhere else. Discover all the reasons to stay and play.")
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
                        title: "EARN REWARDS AND SHOP WITH POINTS",
                        description: "Get points with every purchase"
                    )
                    
                    BenefitCard(
                        icon: "list.clipboard.fill",
                        title: "RSVP & WAITLISTS",
                        description: "Never miss out on new releases"
                    )
                }
                
                HStack(spacing: 16) {
                    BenefitCard(
                        icon: "creditcard",
                        title: "FLEXIBLE PAYMENT OPTIONS",
                        description: "Choose how you want to pay"
                    )
                    
                    BenefitCard(
                        icon: "ticket",
                        title: "CONTESTS & GIVEAWAYS",
                        description: "Win exclusive prizes"
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