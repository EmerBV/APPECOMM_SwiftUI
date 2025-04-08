import SwiftUI

struct EmptyStateView: View {
    let hasFilters: Bool
    let onClearFilters: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            Text(hasFilters ? "No se encontraron productos" : "No hay productos disponibles")
                .font(.headline)
                .multilineTextAlignment(.center)
            
            if hasFilters {
                Button(action: onClearFilters) {
                    Text("Limpiar filtros")
                        .foregroundColor(.blue)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
} 