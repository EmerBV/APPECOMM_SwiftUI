import SwiftUI
import Kingfisher

struct CategoryItemView: View {
    let category: Category
    private var baseURL: String {
        AppConfig.shared.imageBaseUrl
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 12) {
            Group {
                if let imageUrl = category.imageDownloadUrl,
                   let url = URL(string: baseURL + imageUrl) {
                    KFImage(url)
                        .placeholder {
                            Image(systemName: "photo")
                                .font(.system(size: 30))
                                .foregroundColor(.gray)
                        }
                        .onFailure { error in
                            Logger.error("Error al cargar imagen de categoría: \(error.localizedDescription)")
                        }
                        .fade(duration: 0.3)
                        .resizable()
                        .scaledToFit()
                        .padding(16)
                } else if let uiImage = UIImage(named: category.name.lowercased().replacingOccurrences(of: " ", with: "_")) {
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
            
            Text(category.name)
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
