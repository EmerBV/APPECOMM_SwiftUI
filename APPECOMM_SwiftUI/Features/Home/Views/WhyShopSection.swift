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
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 24) {
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
            .padding()
        }
        .padding(.vertical, 24)
    }
}

private struct BenefitCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(.blue)
            
            Text(title)
                .font(.caption)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
} 