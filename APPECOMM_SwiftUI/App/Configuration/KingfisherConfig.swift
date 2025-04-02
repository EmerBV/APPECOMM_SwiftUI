import Foundation
import Kingfisher
import UIKit

struct KingfisherConfig {
    static func configure() {
        // Configuración global de Kingfisher
        let cache = ImageCache.default
        cache.memoryStorage.config.totalCostLimit = 300 * 1024 * 1024 // 300 MB
        cache.diskStorage.config.sizeLimit = 1000 * 1024 * 1024 // 1 GB
        
        // Configuración del descargador
        let downloader = ImageDownloader.default
        downloader.sessionConfiguration.timeoutIntervalForRequest = 30
        
        // Configuración del procesador de imágenes
        let processor = DefaultImageProcessor.default
        
        // Configuración global
        KingfisherManager.shared.defaultOptions = [
            .cacheOriginalImage,
            .scaleFactor(UIScreen.main.scale),
            .backgroundDecode,
            .keepCurrentImageWhileLoading
        ]
    }
} 