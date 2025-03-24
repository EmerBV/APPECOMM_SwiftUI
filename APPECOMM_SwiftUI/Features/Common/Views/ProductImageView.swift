import SwiftUI

struct ProductImageView: View {
    let size: CGFloat
    
    var body: some View {
        AsyncImage(url: URL(string: "https://via.placeholder.com/\(Int(size))")) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            ProgressView()
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
} 