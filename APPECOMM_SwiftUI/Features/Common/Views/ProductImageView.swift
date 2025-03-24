import SwiftUI
import Kingfisher

struct ProductImageView: View {
    let size: CGFloat
    let imageUrl: String?
    let baseURL: String
    
    var body: some View {
        if let imageUrl = imageUrl {
            let fullImageURL = "\(baseURL)\(imageUrl)"
            if let url = URL(string: fullImageURL) {
                KFImage(url)
                    .placeholder {
                        ProgressView()
                    }
                    .onFailure { error in
                        Logger.error("Error al cargar imagen: \(error.localizedDescription)")
                    }
                    .fade(duration: 0.3)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipped()
                    
            } else {
                Image(systemName: "photo")
                    .font(.largeTitle)
                    .foregroundColor(.gray)
                    .frame(width: size, height: size)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(8)
            }
        } else {
            Image(systemName: "photo")
                .font(.largeTitle)
                .foregroundColor(.gray)
                .frame(width: size, height: size)
                .background(Color.gray.opacity(0.3))
                .cornerRadius(8)
        }
    }
} 
