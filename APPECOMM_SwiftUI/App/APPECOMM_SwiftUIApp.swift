//
//  APPECOMM_SwiftUIApp.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 18/3/25.
//

import SwiftUI
import Combine
import UserNotifications
import Stripe

@main
struct APPECOMM_SwiftUIApp: App {
    @StateObject private var appState = AppState()
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        // La inicialización de Stripe se maneja automáticamente a través del PaymentViewModel
        // cuando se obtiene la configuración del servidor
        
        // Initialize core app dependencies
        configureDependencies()
        configureAppearance()
        
#if DEBUG
        Logger.info("App initialized in debug mode [Version: \(Bundle.main.fullVersion)]")
        Logger.debug("Debug logging enabled")
#else
        Logger.info("App initialized in production mode [Version: \(Bundle.main.fullVersion)]")
        Logger.configure(level: .info) // Restrict logging in production
#endif
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .onAppear {
                    registerForPushNotifications()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    appState.refreshData()
                }
        }
    }
    
    private func configureDependencies() {
        // Initialize app configuration
        _ = AppConfig.shared
        
        // Setup dependency injection
        _ = DependencyInjector.shared
    }
    
    private func configureAppearance() {
        configureNavigationBar()
        configureTabBar()
    }
    
    private func configureNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemBackground
        appearance.titleTextAttributes = [.foregroundColor: UIColor.label]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
    
    private func configureTabBar() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemBackground
        
        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
    
    private func registerForPushNotifications() {
        Task {
            do {
                try await NotificationManager.shared.requestAuthorization()
                await NotificationManager.shared.registerForRemoteNotifications()
            } catch {
                Logger.error("Failed to register for notifications: \(error)")
            }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        NotificationManager.shared.handleNotificationRegistration(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        NotificationManager.shared.handleNotificationRegistration(application, didFailToRegisterForRemoteNotificationsWithError: error)
    }
    
    // MARK: - Deep Linking
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        DeepLinkManager.shared.handleDeepLink(url)
        return true
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        if let url = userActivity.webpageURL {
            DeepLinkManager.shared.handleDeepLink(url)
            return true
        }
        return false
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Configura Stripe con tu clave publicable
        StripeAPI.defaultPublishableKey = "pk_test_51R7MBXQeIvmhXc8UtJmUCUVT6zcjB1Wuvc29fzk1dPww2CbsyrrHRJ8Pqa5aSn9OXPoDMUWMEbZH49baYhN7mijG003fghp0ei" // Usa una clave de prueba de Stripe
        
        return true
    }
}
