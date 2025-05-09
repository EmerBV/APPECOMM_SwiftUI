//
//  ProductRepository.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 19/3/25.
//

import Foundation
import Combine

protocol ProductRepositoryProtocol {
    var productListState: CurrentValueSubject<ProductListState, Never> { get }
    var productDetailState: CurrentValueSubject<ProductDetailState, Never> { get }
    var featuredProductsState: CurrentValueSubject<ProductListState, Never> { get }
    
    func getAllProducts() -> AnyPublisher<[Product], Error>
    func getProductById(id: Int) -> AnyPublisher<Product, Error>
    func getProductsByCategory(category: String) -> AnyPublisher<[Product], Error>
    func getProductsByBrand(brand: String) -> AnyPublisher<[Product], Error>
    func getFeaturedProducts() -> AnyPublisher<[Product], Error>
    func getAllCategories() -> AnyPublisher<[Category], Error>
    func searchProducts(query: String, filters: [String: Any]?) -> AnyPublisher<[Product], Error>
    func getFilteredProducts(filterDto: ProductFilterDto) -> AnyPublisher<[Product], Error>
}

final class ProductRepository: ProductRepositoryProtocol {
    var productListState: CurrentValueSubject<ProductListState, Never> = CurrentValueSubject(.initial)
    var productDetailState: CurrentValueSubject<ProductDetailState, Never> = CurrentValueSubject(.initial)
    var featuredProductsState: CurrentValueSubject<ProductListState, Never> = CurrentValueSubject(.initial)
    
    private let productService: ProductServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(productService: ProductServiceProtocol) {
        self.productService = productService
    }
    
    func getAllProducts() -> AnyPublisher<[Product], Error> {
        Logger.info("ProductRepository: Getting all products")
        productListState.send(.loading)
        
        return productService.getAllProducts()
            .handleEvents(receiveOutput: { [weak self] products in
                Logger.info("ProductRepository: Received \(products.count) products")
                if products.isEmpty {
                    self?.productListState.send(.empty)
                } else {
                    self?.productListState.send(.loaded(products))
                }
            }, receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    Logger.error("ProductRepository: Failed to get products: \(error)")
                    self?.productListState.send(.error(error.localizedDescription))
                }
            })
            .mapError { $0 }
            .eraseToAnyPublisher()
    }
    
    func getProductById(id: Int) -> AnyPublisher<Product, Error> {
        Logger.info("ProductRepository: Getting product with ID: \(id)")
        productDetailState.send(.loading)
        
        return productService.getProductById(id: id)
            .handleEvents(receiveOutput: { [weak self] product in
                Logger.info("ProductRepository: Received product: \(product.name)")
                self?.productDetailState.send(.loaded(product))
            }, receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    Logger.error("ProductRepository: Failed to get product: \(error)")
                    self?.productDetailState.send(.error(error.localizedDescription))
                }
            })
            .mapError { $0 }
            .eraseToAnyPublisher()
    }
    
    func getProductsByCategory(category: String) -> AnyPublisher<[Product], Error> {
        Logger.info("ProductRepository: Getting products by category: \(category)")
        productListState.send(.loading)
        
        return productService.getProductsByCategory(category: category)
            .handleEvents(receiveOutput: { [weak self] products in
                Logger.info("ProductRepository: Received \(products.count) products for category: \(category)")
                if products.isEmpty {
                    self?.productListState.send(.empty)
                } else {
                    self?.productListState.send(.loaded(products))
                }
            }, receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    Logger.error("ProductRepository: Failed to get products by category: \(error)")
                    self?.productListState.send(.error(error.localizedDescription))
                }
            })
            .mapError { $0 }
            .eraseToAnyPublisher()
    }
    
    func getProductsByBrand(brand: String) -> AnyPublisher<[Product], Error> {
        Logger.info("ProductRepository: Getting products by brand: \(brand)")
        productListState.send(.loading)
        
        return productService.getProductsByBrand(brand: brand)
            .handleEvents(receiveOutput: { [weak self] products in
                Logger.info("ProductRepository: Received \(products.count) products for brand: \(brand)")
                if products.isEmpty {
                    self?.productListState.send(.empty)
                } else {
                    self?.productListState.send(.loaded(products))
                }
            }, receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    Logger.error("ProductRepository: Failed to get products by brand: \(error)")
                    self?.productListState.send(.error(error.localizedDescription))
                }
            })
            .mapError { $0 }
            .eraseToAnyPublisher()
    }
    
    func getFeaturedProducts() -> AnyPublisher<[Product], Error> {
        Logger.info("ProductRepository: Getting featured products")
        featuredProductsState.send(.loading)
        
        // Asumiendo que el servicio tiene un método para obtener productos destacados
        // Si no existe, se puede implementar como un filtro sobre getAllProducts
        return productService.getAllProducts()
            .map { products -> [Product] in
                // Filtrar productos destacados (por ejemplo, los más vendidos o con descuento)
                return products.filter { $0.discountPercentage > 0 }
                    .sorted(by: { $0.salesCount > $1.salesCount })
                    .prefix(6)
                    .map { $0 }
            }
            .handleEvents(receiveOutput: { [weak self] products in
                Logger.info("ProductRepository: Received \(products.count) featured products")
                if products.isEmpty {
                    self?.featuredProductsState.send(.empty)
                } else {
                    self?.featuredProductsState.send(.loaded(products))
                }
            }, receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    Logger.error("ProductRepository: Failed to get featured products: \(error)")
                    self?.featuredProductsState.send(.error(error.localizedDescription))
                }
            })
            .mapError { $0 }
            .eraseToAnyPublisher()
    }
    
    func getAllCategories() -> AnyPublisher<[Category], Error> {
        Logger.info("ProductRepository: Getting all categories")
        
        return productService.getAllCategories()
            .handleEvents(receiveOutput: { categories in
                Logger.info("ProductRepository: Received \(categories.count) categories")
            }, receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    Logger.error("ProductRepository: Failed to get categories: \(error)")
                }
            })
            .mapError { $0 }
            .eraseToAnyPublisher()
    }
    
    func searchProducts(query: String, filters: [String: Any]? = nil) -> AnyPublisher<[Product], Error> {
        Logger.info("ProductRepository: Searching products with query: \(query)")
        productListState.send(.loading)
        
        // Aquí adaptamos esto para usar el servicio existente
        // Si se necesita implementar búsqueda avanzada, se debería agregar un método específico en el servicio
        return productService.getAllProducts()
            .map { products -> [Product] in
                var filteredProducts = products
                
                // Filtrar por consulta de búsqueda
                if !query.isEmpty {
                    filteredProducts = filteredProducts.filter { product in
                        product.name.lowercased().contains(query.lowercased()) ||
                        product.brand.lowercased().contains(query.lowercased()) ||
                        (product.description ?? "").lowercased().contains(query.lowercased())
                    }
                }
                
                // Aplicar filtros adicionales si existen
                if let filters = filters {
                    if let categoryId = filters["categoryId"] as? Int {
                        filteredProducts = filteredProducts.filter { $0.category.id == categoryId }
                    }
                    
                    if let minPrice = filters["minPrice"] as? Decimal {
                        filteredProducts = filteredProducts.filter { $0.price >= minPrice }
                    }
                    
                    if let maxPrice = filters["maxPrice"] as? Decimal {
                        filteredProducts = filteredProducts.filter { $0.price <= maxPrice }
                    }
                    
                    if let brand = filters["brand"] as? String {
                        filteredProducts = filteredProducts.filter { $0.brand.lowercased() == brand.lowercased() }
                    }
                    
                    // Ordenar resultados
                    if let sort = filters["sort"] as? String {
                        switch sort {
                        case "price_asc":
                            filteredProducts.sort { $0.price < $1.price }
                        case "price_desc":
                            filteredProducts.sort { $0.price > $1.price }
                        case "name_asc":
                            filteredProducts.sort { $0.name < $1.name }
                        case "name_desc":
                            filteredProducts.sort { $0.name > $1.name }
                        default:
                            break
                        }
                    }
                }
                
                return filteredProducts
            }
            .handleEvents(receiveOutput: { [weak self] products in
                Logger.info("ProductRepository: Search returned \(products.count) products")
                if products.isEmpty {
                    self?.productListState.send(.empty)
                } else {
                    self?.productListState.send(.loaded(products))
                }
            }, receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    Logger.error("ProductRepository: Search failed: \(error)")
                    self?.productListState.send(.error(error.localizedDescription))
                }
            })
            .mapError { $0 }
            .eraseToAnyPublisher()
    }
    
    func getFilteredProducts(filterDto: ProductFilterDto) -> AnyPublisher<[Product], Error> {
        // This is a placeholder - you would implement this in your actual repository
        return getAllProducts()
            .map { products -> [Product] in
                var filteredProducts = products
                
                // Apply category filter
                if let category = filterDto.category {
                    filteredProducts = filteredProducts.filter { $0.category.name == category }
                }
                
                // Apply brand filter
                if let brand = filterDto.brand {
                    filteredProducts = filteredProducts.filter { $0.brand == brand }
                }
                
                // Apply price filters
                if let minPrice = filterDto.minPrice {
                    filteredProducts = filteredProducts.filter { $0.price >= minPrice }
                }
                
                if let maxPrice = filterDto.maxPrice {
                    filteredProducts = filteredProducts.filter { $0.price <= maxPrice }
                }
                
                // Apply availability filter
                if let status = filterDto.availability {
                    filteredProducts = filteredProducts.filter { $0.status == status }
                }
                
                // Apply sorting
                if let sortBy = filterDto.sortBy {
                    switch sortBy {
                    case "price_asc":
                        filteredProducts.sort { $0.price < $1.price }
                    case "price_desc":
                        filteredProducts.sort { $0.price > $1.price }
                    case "name_asc":
                        filteredProducts.sort { $0.name < $1.name }
                    case "name_desc":
                        filteredProducts.sort { $0.name > $1.name }
                    case "bestselling":
                        filteredProducts.sort { $0.salesCount > $1.salesCount }
                    case "mostwished":
                        filteredProducts.sort { $0.wishCount > $1.wishCount }
                    case "newest":
                        filteredProducts.sort { $0.createdAt > $1.createdAt }
                    case "discount":
                        filteredProducts.sort { $0.discountPercentage > $1.discountPercentage }
                    default:
                        break
                    }
                }
                
                return filteredProducts
            }
            .eraseToAnyPublisher()
    }
    
    func debugProductState() {
        Logger.debug("Current product list state: \(productListState.value)")
        Logger.debug("Current product detail state: \(productDetailState.value)")
        Logger.debug("Current featured products state: \(featuredProductsState.value)")
    }
}
