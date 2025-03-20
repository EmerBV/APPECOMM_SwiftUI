import SwiftUI

struct CategoryItemView: View {
    let name: String
    
    var body: some View {
        VStack {
            Circle()
                .fill(Color.blue.opacity(0.1))
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: "tag.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                )
            
            Text(name)
                .font(.caption)
                .foregroundColor(.primary)
                .lineLimit(1)
        }
        .frame(width: 80)
    }
}

struct CategoryPlaceholderView: View {
    var body: some View {
        VStack {
            Circle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 60, height: 60)
                .overlay(
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                )
            
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 60, height: 12)
                .cornerRadius(6)
        }
        .frame(width: 80)
    }
} 