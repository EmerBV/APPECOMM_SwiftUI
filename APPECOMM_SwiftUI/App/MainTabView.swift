//
//  MainTabView.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 19/3/25.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @StateObject private var profileViewModel = DependencyInjector.shared.resolve(ProfileViewModel.self)
    
    init() {
        
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView(viewModel: DependencyInjector.shared.resolve(HomeViewModel.self))
            }
            .tabItem {
                Image(systemName: "house")
            }
            .tag(0)
            .onAppear {
                Logger.info("HomeView appeared")
            }
            
            NavigationStack {
                ProductListView(viewModel: DependencyInjector.shared.resolve(ProductListViewModel.self))
            }
            .tabItem {
                Image(systemName: "bag")
            }
            .tag(1)
            .onAppear {
                Logger.info("ProductListView appeared")
            }
            
            NavigationStack {
                CartView(viewModel: DependencyInjector.shared.resolve(CartViewModel.self))
            }
            .tabItem {
                Image(systemName: "cart")
            }
            .tag(2)
            .onAppear {
                Logger.info("CartView appeared")
            }
            
            NavigationStack {
                ProfileView(viewModel: profileViewModel)
            }
            .tabItem {
                if let firstName = profileViewModel.user?.firstName.first {
                    Image(systemName: "\(firstName.lowercased()).circle")
                } else {
                    Image(systemName: "person")
                }
            }
            .tag(3)
            .onAppear {
                Logger.info("ProfileView appeared")
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("NavigateToHomeTab"))) { _ in
            // Switch to home tab when notification is received
            selectedTab = 0
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("NavigateToCartTab"))) { _ in
            // Switch to cart tab when notification is received
            selectedTab = 2
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("NavigateToProfileTab"))) { _ in
            // Switch to profile tab when notification is received
            selectedTab = 3
        }
    }
}
