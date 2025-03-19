//
//  ProductDetailView.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 18/3/25.
//

import SwiftUI

struct ProductDetailView: View {
    let product: Product
    let viewModel: ProductViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Imagen del producto si está disponible
                if let images = product.images, !images.isEmpty, let imageUrl = URL(string: images[0].downloadUrl) {
                    AsyncImage(url: imageUrl) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(height: 200)
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 300)
                        case .failure:
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .frame(height: 200)
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    Image(systemName: "photo")
                        .font(.largeTitle)
                        .frame(height: 200)
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.1))
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    // Cabecera de producto
                    Text(product.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(product.brand)
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    // Precio y descuento
                    HStack {
                        if product.discountPercentage > 0, let discountedPrice = viewModel.formattedDiscountedPrice(for: product) {
                            VStack(alignment: .leading) {
                                Text("Precio original:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text(viewModel.formattedPrice(for: product))
                                    .strikethrough()
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing) {
                                Text("Precio con descuento:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text(discountedPrice)
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                            }
                        } else {
                            Text("Precio:")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text(viewModel.formattedPrice(for: product))
                                .font(.title3)
                                .fontWeight(.bold)
                        }
                    }
                    .padding(.vertical, 8)
                    
                    // Estado e inventario
                    HStack {
                        StatusBadgeView(status: product.status)
                        
                        Spacer()
                        
                        Text("Inventario: \(product.inventory) unidades")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                    
                    // Descripción
                    Text("Descripción")
                        .font(.headline)
                    
                    Text(product.description ?? "Sin descripción disponible")
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    // Categoría
                    HStack {
                        Text("Categoría:")
                            .font(.headline)
                        
                        Text(product.category.name)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 8)
                    
                    // Variantes si existen
                    if let variants = product.variants, !variants.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Variantes disponibles")
                                .font(.headline)
                                .padding(.top, 8)
                            
                            ForEach(variants) { variant in
                                HStack {
                                    Text(variant.name)
                                        .font(.body)
                                    
                                    Spacer()
                                    
                                    Text("$\(variant.price)")
                                        .font(.body)
                                        .foregroundColor(.blue)
                                    
                                    Text("(\(variant.inventory) disp.)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    
                    // Información adicional
                    HStack {
                        VStack {
                            Text("\(product.salesCount)")
                                .font(.headline)
                            Text("Ventas")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        
                        VStack {
                            Text("\(product.wishCount)")
                                .font(.headline)
                            Text("Deseos")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        
                        VStack {
                            Text(product.preOrder ? "Sí" : "No")
                                .font(.headline)
                            Text("Pre-orden")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.vertical, 16)
                    
                    // Fecha de creación
                    Text("Agregado el \(formattedDate(product.createdAt))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func formattedDate(_ dateString: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        
        guard let date = inputFormatter.date(from: dateString) else {
            return dateString
        }
        
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "dd/MM/yyyy"
        return outputFormatter.string(from: date)
    }
}
