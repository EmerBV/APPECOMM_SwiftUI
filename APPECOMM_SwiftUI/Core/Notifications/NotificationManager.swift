import Foundation
import UIKit
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {}
    
    func requestAuthorization() async throws {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        try await UNUserNotificationCenter.current().requestAuthorization(options: options)
    }
    
    func registerForRemoteNotifications() async {
        await MainActor.run {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
    
    func handleNotificationRegistration(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        Logger.info("Device Token: \(token)")
        
        // Aquí puedes enviar el token a tu servidor
    }
    
    func handleNotificationRegistration(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        Logger.error("Failed to register for notifications: \(error)")
    }
} 
