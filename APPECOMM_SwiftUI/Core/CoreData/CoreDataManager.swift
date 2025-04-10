//
//  CoreDataManager.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 20/3/25.
//

import CoreData
import Foundation

class CoreDataManager {
    static let shared = CoreDataManager()
    
    private init() {}
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "APPECOMM_SwiftUI")
        container.loadPersistentStores { description, error in
            if let error = error {
                Logger.error("CoreDataManager: Core Data failed to load: \(error.localizedDescription)")
                fatalError("CoreDataManager: Core Data failed to load: \(error.localizedDescription)")
            }
        }
        return container
    }()
    
    var context: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                Logger.error("CoreDataManager: Error saving context: \(error)")
            }
        }
    }
    
    // MARK: - Product Methods
    
    func saveProduct(_ product: Product) {
        let entity = ProductEntity(context: context)
        entity.id = Int32(product.id)
        entity.name = product.name
        entity.price = NSDecimalNumber(decimal: product.price).doubleValue
        entity.productDescription = product.description
        entity.category = product.category.name
        entity.lastUpdated = Date()
        
        saveContext()
    }
    
    func fetchProducts() -> [Product] {
        let request: NSFetchRequest<ProductEntity> = ProductEntity.fetchRequest()
        
        do {
            let entities = try context.fetch(request)
            return entities.map { entity in
                Product(
                    id: Int(entity.id),
                    name: entity.name ?? "",
                    brand: "", // Valor por defecto
                    price: Decimal(entity.price),
                    inventory: 0, // Valor por defecto
                    description: entity.productDescription,
                    category: Category(
                        id: 0,
                        name: entity.category ?? "",
                        imageFileName: nil,
                        imageFileType: nil,
                        imageDownloadUrl: nil
                    ),
                    discountPercentage: 0, // Valor por defecto
                    status: .inStock, // Valor por defecto
                    salesCount: 0, // Valor por defecto
                    wishCount: 0, // Valor por defecto
                    preOrder: false, // Valor por defecto
                    createdAt: Date().description, // Valor por defecto
                    variants: nil, // Valor por defecto
                    images: nil // Valor por defecto
                )
            }
        } catch {
            Logger.error("CoreDataManager: Error fetching products: \(error)")
            return []
        }
    }
    
    // MARK: - User Methods
    
    func saveUser(_ user: User) {
        let entity = UserEntity(context: context)
        entity.id = Int32(user.id)
        entity.email = user.email
        entity.firstName = user.firstName
        entity.lastName = user.lastName
        entity.lastLogin = Date()
        
        saveContext()
    }
    
    func fetchUser() -> User? {
        let request: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        
        do {
            let entities = try context.fetch(request)
            guard let entity = entities.first else { return nil }
            
            return User(
                id: Int(entity.id),
                firstName: entity.firstName ?? "",
                lastName: entity.lastName ?? "",
                email: entity.email ?? "",
                shippingDetails: nil,
                cart: nil,
                orders: nil
            )
        } catch {
            Logger.error("CoreDataManager: Error fetching user: \(error)")
            return nil
        }
    }
}
