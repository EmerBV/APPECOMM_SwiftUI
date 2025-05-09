//
//  ProductListViewModel.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 18/3/25.
//

import Foundation
import Combine

class ProductListViewModel: ObservableObject {
    // Published properties
    @Published var products: [Product] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Filtrado y búsqueda
    @Published var filter = ProductFilter()
    @Published var isFilterSheetPresented = false
    @Published var temporaryFilter = ProductFilter()
    @Published var brands: [String] = []
    @Published var searchText = ""
    @Published var selectedCategory: String?
    
    // Estado del carrito
    @Published var isAddingToCart = false
    @Published var cartSuccessMessage: String?
    
    // Computed properties
    var hasActiveFilters: Bool {
        !searchText.isEmpty || selectedCategory != nil
    }
    
    var filteredProducts: [Product] {
        var result = products
        
        // Filtrar por categoría
        if let category = selectedCategory, !category.isEmpty {
            result = result.filter { $0.category.name == category }
        }
        
        // Filtrar por texto de búsqueda
        if !searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.brand.localizedCaseInsensitiveContains(searchText) ||
                $0.description?.localizedCaseInsensitiveContains(searchText) ?? false
            }
        }
        
        return result
    }
    
    var categories: [String] {
        let categoryNames = Set(products.map { $0.category.name })
        return Array(categoryNames).sorted()
    }
    
    // Dependencies
    private let productRepository: ProductRepositoryProtocol
    private let cartRepository: CartRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // Cache timeout
    private var lastProductLoadTime: Date?
    private let cacheTimeout: TimeInterval = 5 * 60 // 5 minutos
    
    init(
        productRepository: ProductRepositoryProtocol,
        cartRepository: CartRepositoryProtocol
    ) {
        self.productRepository = productRepository
        self.cartRepository = cartRepository
        
        // Intentar cargar productos desde caché al iniciar
        if let cachedProducts: [Product] = UserDefaults.standard.getObject(forKey: "cached_products") {
            self.products = cachedProducts
            Logger.info("Productos cargados desde caché: \(cachedProducts.count)")
        }
    }
    
    func clearFilters() {
        searchText = ""
        selectedCategory = nil
    }
    
    func dismissError() {
        errorMessage = nil
    }
    
    func loadProducts(forceRefresh: Bool = false) {
        // Evitar múltiples cargas simultáneas
        guard !isLoading else { return }
        
        // Verificar si tenemos productos en caché y si el tiempo de caché es válido
        if !forceRefresh,
           !products.isEmpty,
           let lastLoad = lastProductLoadTime,
           Date().timeIntervalSince(lastLoad) < cacheTimeout {
            Logger.info("Usando productos en caché")
            return
        }
        
        Logger.info("Cargando productos desde el servidor")
        isLoading = true
        errorMessage = nil
        
        productRepository.getAllProducts()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                
                if case .failure(let error) = completion {
                    Logger.error("Error al cargar productos: \(error)")
                    
                    if let networkError = error as? NetworkError {
                        switch networkError {
                        case .decodingError:
                            self?.errorMessage = "processing_error".localized
                        case .serverError:
                            self?.errorMessage = "server_error".localized
                        case .unauthorized:
                            self?.errorMessage = "unauthorized".localized
                        default:
                            self?.errorMessage = "unknown_error".localized
                        }
                    } else {
                        self?.errorMessage = "processing_error".localized
                    }
                } else {
                    Logger.info("Productos cargados correctamente")
                }
            } receiveValue: { [weak self] products in
                guard let self = self else { return }
                
                Logger.info("Recibidos \(products.count) productos")
                self.products = products
                self.lastProductLoadTime = Date()
                
                // Guardar en caché
                UserDefaults.standard.save(object: products, forKey: "cached_products")
            }
            .store(in: &cancellables)
    }
    
    func loadProductsByCategory(category: String) {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        productRepository.getProductsByCategory(category: category)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                
                if case .failure(let error) = completion {
                    Logger.error("Error al cargar productos por categoría: \(error)")
                    
                    if let networkError = error as? NetworkError {
                        switch networkError {
                        case .decodingError:
                            self?.errorMessage = "processing_error".localized
                        case .serverError:
                            self?.errorMessage = "server_error".localized
                        case .unauthorized:
                            self?.errorMessage = "unauthorized".localized
                        default:
                            self?.errorMessage = "unknown_error".localized
                        }
                    } else {
                        self?.errorMessage = "processing_error".localized
                    }
                }
            } receiveValue: { [weak self] products in
                self?.products = products
                self?.selectedCategory = category
                Logger.info("Cargados \(products.count) productos para categoría \(category)")
            }
            .store(in: &cancellables)
    }
    
    // Method to load products with filter
    func loadProductsWithFilter(forceRefresh: Bool = false) {
        // Prevent loading if already loading
        guard !isLoading else { return }
        
        // Use cached data if possible and not forcing refresh
        if !forceRefresh && !products.isEmpty && filter.hasActiveFilters == false {
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        // Create a filter DTO based on our filter model
        let filterDto = ProductFilterDto(
            sortBy: filter.sortBy?.rawValue,
            availability: filter.availability,
            category: filter.selectedCategory,
            minPrice: filter.minPrice,
            maxPrice: filter.maxPrice,
            brand: filter.selectedBrand,
            page: 0,
            size: 50 // You might want to adjust this or make it configurable
        )
        
        productRepository.getFilteredProducts(filterDto: filterDto)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                
                if case .failure(let error) = completion {
                    Logger.error("Error loading filtered products: \(error)")
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] products in
                self?.products = products
                Logger.info("Loaded \(products.count) filtered products")
            }
            .store(in: &cancellables)
    }
    
    // Method to apply filter and reload products
    func applyFilter() {
        filter = temporaryFilter
        loadProductsWithFilter(forceRefresh: true)
    }
    
    // Method to show the filter sheet
    func showFilterSheet() {
        // Copy current filter to temporary filter
        temporaryFilter = filter
        isFilterSheetPresented = true
    }
    
    // Method to reset filters
    func resetFilter() {
        temporaryFilter.reset()
    }
    
    // Method to load all available brands
    func loadBrands() {
        if !brands.isEmpty {
            return
        }
        
        // This would ideally come from an API endpoint
        // For now, let's extract unique brands from loaded products
        let uniqueBrands = Set(products.map { $0.brand })
        brands = Array(uniqueBrands).sorted()
    }
    
    func addToCart(productId: Int, quantity: Int, variantId: Int? = nil) {
        guard !isAddingToCart else { return }
        
        isAddingToCart = true
        errorMessage = nil
        
        cartRepository.addItemToCart(productId: productId, quantity: quantity, variantId: variantId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isAddingToCart = false
                
                if case .failure(let error) = completion {
                    Logger.error("Error al añadir producto al carrito: \(error)")
                    
                    if let networkError = error as? NetworkError {
                        switch networkError {
                        case .unauthorized:
                            self?.errorMessage = "unauthorized".localized
                        default:
                            self?.errorMessage = "processing_error".localized
                        }
                    } else {
                        self?.errorMessage = "processing_error".localized
                    }
                }
            } receiveValue: { [weak self] _ in
                Logger.info("Producto añadido al carrito correctamente")
                self?.cartSuccessMessage = "added_to_cart".localized
                
                // Ocultar mensaje de éxito después de 3 segundos
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self?.cartSuccessMessage = nil
                }
            }
            .store(in: &cancellables)
    }
    
    // Formateo de precios
    func formattedPrice(for product: Product) -> String {
        return product.price.toCurrentLocalePrice
    }
    
    func discountedPrice(for product: Product) -> Decimal? {
        // Aquí iría la lógica de descuento
        return nil
    }
    
    func formattedDiscountedPrice(for product: Product) -> String? {
        guard let discountedPrice = discountedPrice(for: product) else { return nil }
        
        return discountedPrice.toCurrentLocalePrice
    }
}

extension ProductListViewModel {
    func addToCartWithNotification(productId: Int, quantity: Int, variantId: Int? = nil) {
        guard !isAddingToCart else { return }
        
        isAddingToCart = true
        errorMessage = nil
        
        cartRepository.addItemToCart(productId: productId, quantity: quantity, variantId: variantId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isAddingToCart = false
                
                if case .failure(let error) = completion {
                    Logger.error("Error al añadir producto al carrito: \(error)")
                    
                    if let networkError = error as? NetworkError {
                        switch networkError {
                        case .unauthorized:
                            NotificationService.shared.showError(
                                title: "unauthorized".localized,
                                message: "unauthorized".localized
                            )
                        default:
                            NotificationService.shared.showError(
                                title: "error".localized,
                                message: "processing_error".localized
                            )
                        }
                    } else {
                        NotificationService.shared.showError(
                            title: "error".localized,
                            message: "processing_error".localized
                        )
                    }
                }
            } receiveValue: { [weak self] _ in
                Logger.info("Producto añadido al carrito correctamente")
                
                // Mostrar notificación usando el servicio
                NotificationService.shared.showSuccess(
                    title: "success".localized,
                    message: "added_to_cart".localized
                )
                
                // Mantener compatibilidad con versión antigua
                self?.cartSuccessMessage = "added_to_cart".localized
                
                // Ocultar mensaje de éxito después de 3 segundos
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self?.cartSuccessMessage = nil
                }
            }
            .store(in: &cancellables)
    }
    
    // Actualizar el método loadProducts para usar notificaciones
    func loadProductsWithNotification(forceRefresh: Bool = false) {
        // Evitar múltiples cargas simultáneas
        guard !isLoading else { return }
        
        // Verificar si tenemos productos en caché y si el tiempo de caché es válido
        if !forceRefresh,
           !products.isEmpty,
           let lastLoad = lastProductLoadTime,
           Date().timeIntervalSince(lastLoad) < cacheTimeout {
            Logger.info("Usando productos en caché")
            return
        }
        
        Logger.info("Cargando productos desde el servidor")
        isLoading = true
        errorMessage = nil
        
        productRepository.getAllProducts()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                
                if case .failure(let error) = completion {
                    Logger.error("Error al cargar productos: \(error)")
                    
                    if let networkError = error as? NetworkError {
                        switch networkError {
                        case .decodingError:
                            NotificationService.shared.showError(
                                title: "error".localized,
                                message: "processing_error".localized
                            )
                        case .serverError:
                            NotificationService.shared.showError(
                                title: "error".localized,
                                message: "server_error".localized
                            )
                        case .unauthorized:
                            NotificationService.shared.showError(
                                title: "unauthorized".localized,
                                message: "unauthorized".localized
                            )
                        default:
                            NotificationService.shared.showError(
                                title: "error".localized,
                                message: "unknown_error".localized
                            )
                        }
                    } else {
                        NotificationService.shared.showError(
                            title: "error".localized,
                            message: "processing_error".localized
                        )
                    }
                    
                    // Mantener el mensaje de error tradicional también
                    self?.errorMessage = error.localizedDescription
                } else {
                    Logger.info("Productos cargados correctamente")
                }
            } receiveValue: { [weak self] products in
                guard let self = self else { return }
                
                Logger.info("Recibidos \(products.count) productos")
                self.products = products
                self.lastProductLoadTime = Date()
                
                // Guardar en caché
                UserDefaults.standard.save(object: products, forKey: "cached_products")
                
                // Mostrar confirmación solo si fue un refresh forzado
                if forceRefresh {
                    NotificationService.shared.showSuccess(
                        title: "success".localized,
                        message: String(format: "products_updated".localized, products.count)
                    )
                }
            }
            .store(in: &cancellables)
    }
}
