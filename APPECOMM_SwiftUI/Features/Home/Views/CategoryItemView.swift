import SwiftUI

struct CategoryItemView: View {
    let name: String
    
    var body: some View {
        VStack(alignment: .center, spacing: 12) {
            Group {
                if let uiImage = UIImage(named: name.lowercased().replacingOccurrences(of: " ", with: "_")) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .padding(16)
                } else {
                    Image(systemName: "photo")
                        .font(.system(size: 30))
                        .foregroundColor(.gray)
                }
            }
            .frame(width: 100, height: 100)
            .background(Color.white)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            
            Text(name)
                .font(.system(size: 12, weight: .medium))
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(width: 100)
    }
}

struct CategoryPlaceholderView: View {
    var body: some View {
        VStack(alignment: .center, spacing: 12) {
            Circle()
                .fill(Color.gray.opacity(0.1))
                .frame(width: 100, height: 100)
                .overlay(
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
            
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.gray.opacity(0.1))
                .frame(width: 60, height: 12)
        }
        .frame(width: 100)
    }
} 