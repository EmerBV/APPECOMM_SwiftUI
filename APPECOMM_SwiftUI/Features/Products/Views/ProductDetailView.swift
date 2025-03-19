import SwiftUI

struct ProductDetailView: View {
    let product: Product
    let viewModel: ProductListViewModel
    
    @State private var selectedVariant: Variant?
    @State private var quantity: Int = 1
    @State private var showingImageViewer = false
    @State private var selectedImageIndex = 0
    
    // Computed properties
    private var effectivePrice: Decimal {
        if let variant = selectedVariant {
            return variant.price
        } else if let discounted = viewModel.discountedPrice(for: product) {
            return discounted
        } else {
            return product.price
        }
    }
    
    private var formattedEffectivePrice: String {
        if let variant = selectedVariant {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencySymbol = "$"
            return formatter.string(from: variant.price as NSDecimalNumber) ?? "$\(variant.price)"
        } else if let discounted = viewModel.formattedDiscountedPrice(for: product) {
            return discounted
        } else {
            return viewModel.formattedPrice(for: product)
        }
    }
    
    private var availableInventory: Int {
        if let variant = selectedVariant {
            return variant.inventory
        } else {
            return product.inventory
        }
    }
    
    private var isOutOfStock: Bool {
        return availableInventory <= 0
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Product Images
                ProductImageCarousel(
                    product: product,
                    showingImageViewer: $showingImageViewer,
                    selectedImageIndex: $selectedImageIndex
                )
                
                // Product Info Sections
                VStack(alignment: .leading, spacing: 16) {
                    // Header
                    ProductHeaderView(product: product)
                    
                    Divider()
                    
                    // Price & Variants
                    ProductPriceVariantView(
                        product: product,
                        viewModel: viewModel,
                        selectedVariant: $selectedVariant,
                        formattedEffectivePrice: formattedEffectivePrice,
                        quantity: $quantity,
                        availableInventory: availableInventory,
                        isOutOfStock: isOutOfStock
                    )
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    // Description
                    ProductDescriptionView(product: product)
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    // Details and Specifications
                    ProductDetailsView(product: product)
                    
                    Spacer(minLength: 30)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingImageViewer) {
            if let images = product.images, !images.isEmpty {
                ImageViewer(
                    images: images.map { $0.downloadUrl },
                    selectedIndex: selectedImageIndex
                )
            }
        }
    }
}

// MARK: - Product Image Carousel
struct ProductImageCarousel: View {
    let product: Product
    @Binding var showingImageViewer: Bool
    @Binding var selectedImageIndex: Int
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            if let images = product.images, !images.isEmpty {
                TabView {
                    ForEach(Array(images.enumerated()), id: \.element.id) { index, image in
                        AsyncImage(url: URL(string: image.downloadUrl)) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .onTapGesture {
                                        selectedImageIndex = index
                                        showingImageViewer = true
                                    }
                            case .failure:
                                Image(systemName: "photo")
                                    .font(.largeTitle)
                                    .foregroundColor(.gray)
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .padding(.bottom, 20)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                .frame(height: 300)
            } else {
                Image(systemName: "photo")
                    .font(.system(size: 64))
                    .foregroundColor(.gray)
                    .frame(height: 250)
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.1))
            }
            
            if product.discountPercentage > 0 {
                Text("-\(product.discountPercentage)%")
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(4)
                    .padding(16)
            }
        }
    }
}

// MARK: - Product Header View
struct ProductHeaderView: View {
    let product: Product
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(product.name)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(product.brand)
                .font(.headline)
                .foregroundColor(.secondary)
            
            HStack {
                StatusBadge(status: product.status)
                
                Spacer()
                
                HStack(spacing: 8) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    
                    // Ratings would normally come from API
                    // Using mock data for this example
                    Text("4.5")
                        .fontWeight(.semibold)
                    
                    Text("(120)")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal)
        .padding(.top)
    }
}

// MARK: - Product Price and Variant View
struct ProductPriceVariantView: View {
    let product: Product
    let viewModel: ProductListViewModel
    @Binding var selectedVariant: Variant?
    let formattedEffectivePrice: String
    @Binding var quantity: Int
    let availableInventory: Int
    let isOutOfStock: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Price
            HStack(alignment: .center) {
                if product.discountPercentage > 0 && selectedVariant == nil {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Original price:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(viewModel.formattedPrice(for: product))
                            .strikethrough()
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Discounted price:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(formattedEffectivePrice)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Price:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(formattedEffectivePrice)
                            .font(.title3)
                            .fontWeight(.bold)
                    }
                    
                    Spacer()
                    
                    if let variant = selectedVariant {
                        Text("Variant: \(variant.name)")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }
            }
            
            // Variants selector
            VariantsSelectionView(
                product: product,
                selectedVariant: $selectedVariant,
                quantity: $quantity
            )
            
            // Quantity selector
            QuantitySelectionView(
                quantity: $quantity,
                availableInventory: availableInventory
            )
            
            // Add to cart button
            Button(action: {
                // Action to add to cart
                // Would call repository method in a real app
            }) {
                HStack {
                    Image(systemName: "cart.badge.plus")
                    Text("Add to Cart")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(!isOutOfStock ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(isOutOfStock)
        }
        .padding(.horizontal)
    }
}

// MARK: - Variants Selection View
struct VariantsSelectionView: View {
    let product: Product
    @Binding var selectedVariant: Variant?
    @Binding var quantity: Int
    
    // Creamos el formatter como una propiedad privada
    private let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        return formatter
    }()
    
    // Función para obtener el precio formateado
    private func formattedPrice(_ price: Decimal) -> String {
        return currencyFormatter.string(from: price as NSDecimalNumber) ?? "$\(price)"
    }
    
    var body: some View {
        if let variants = product.variants, !variants.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Available Variants")
                    .font(.headline)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(variants) { variant in
                            Button(action: {
                                if selectedVariant?.id == variant.id {
                                    selectedVariant = nil
                                } else {
                                    selectedVariant = variant
                                    // Reset quantity when changing variant
                                    quantity = 1
                                }
                            }) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(variant.name)
                                        .font(.subheadline)
                                        .fontWeight(selectedVariant?.id == variant.id ? .bold : .regular)
                                    
                                    HStack {
                                        Text(formattedPrice(variant.price))
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                        
                                        Spacer()
                                        
                                        if variant.inventory <= 0 {
                                            Text("Out of Stock")
                                                .font(.caption)
                                                .foregroundColor(.red)
                                        } else if variant.inventory < 5 {
                                            Text("Low Stock")
                                                .font(.caption)
                                                .foregroundColor(.orange)
                                        }
                                    }
                                }
                                .padding(10)
                                .frame(width: 150)
                                .background(selectedVariant?.id == variant.id ? Color.blue.opacity(0.1) : Color(.systemGray6))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(selectedVariant?.id == variant.id ? Color.blue : Color.clear, lineWidth: 1)
                                )
                            }
                            .disabled(variant.inventory <= 0)
                            .opacity(variant.inventory <= 0 ? 0.6 : 1.0)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Quantity Selection View
struct QuantitySelectionView: View {
    @Binding var quantity: Int
    let availableInventory: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Quantity")
                .font(.headline)
            
            HStack {
                Button(action: {
                    if quantity > 1 {
                        quantity -= 1
                    }
                }) {
                    Image(systemName: "minus")
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(.systemGray5))
                        .cornerRadius(4)
                }
                .disabled(quantity <= 1)
                
                Text("\(quantity)")
                    .font(.headline)
                    .frame(width: 40, alignment: .center)
                
                Button(action: {
                    if quantity < availableInventory && quantity < 10 {
                        quantity += 1
                    }
                }) {
                    Image(systemName: "plus")
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(.systemGray5))
                        .cornerRadius(4)
                }
                .disabled(quantity >= availableInventory || quantity >= 10)
                
                Spacer()
                
                Text("\(availableInventory) available")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Product Description View
struct ProductDescriptionView: View {
    let product: Product
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Description")
                .font(.headline)
            
            Text(product.description ?? "No description available")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
    }
}

// MARK: - Product Details View
struct ProductDetailsView: View {
    let product: Product
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Product Details")
                .font(.headline)
            
            VStack(spacing: 12) {
                DetailRow(label: "Category", value: product.category.name)
                DetailRow(label: "Brand", value: product.brand)
                DetailRow(label: "Status", value: product.status == .inStock ? "In Stock" : "Out of Stock")
                DetailRow(label: "Pre-Order", value: product.preOrder ? "Yes" : "No")
                DetailRow(label: "Added", value: formattedDate(product.createdAt))
            }
        }
        .padding(.horizontal)
    }
    
    private func formattedDate(_ dateString: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        
        guard let date = inputFormatter.date(from: dateString) else {
            return dateString
        }
        
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "MMM d, yyyy"
        return outputFormatter.string(from: date)
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .leading)
            
            Text(value)
                .font(.subheadline)
            
            Spacer()
        }
    }
}

struct ImageViewer: View {
    let images: [String]
    let selectedIndex: Int
    @Environment(\.presentationMode) var presentationMode
    @State private var currentIndex: Int
    
    init(images: [String], selectedIndex: Int) {
        self.images = images
        self.selectedIndex = selectedIndex
        _currentIndex = State(initialValue: selectedIndex)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack {
                    HStack {
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Image(systemName: "xmark")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                        }
                        
                        Spacer()
                        
                        Text("\(currentIndex + 1) / \(images.count)")
                            .foregroundColor(.white)
                            .padding()
                    }
                    
                    TabView(selection: $currentIndex) {
                        ForEach(Array(images.enumerated()), id: \.offset) { index, imageUrl in
                            AsyncImage(url: URL(string: imageUrl)) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: geometry.size.width, height: geometry.size.height - 100)
                                        .gesture(
                                            MagnificationGesture()
                                                .onChanged { value in
                                                    // Zoom logic would go here in a real app
                                                }
                                        )
                                case .failure:
                                    Image(systemName: "photo")
                                        .font(.largeTitle)
                                        .foregroundColor(.gray)
                                @unknown default:
                                    EmptyView()
                                }
                            }
                            .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                }
            }
        }
    }
}
