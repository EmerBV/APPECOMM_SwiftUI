//
//  ProfileView.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 19/3/25.
//

import SwiftUI

struct ProfileView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @State private var showingLogoutConfirmation = false
    @State private var showingAddressManager = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.isEditingProfile {
                    editProfileView
                } else if let user = viewModel.user {
                    profileView(user: user)
                } else {
                    Text("No user data available")
                        .foregroundColor(.secondary)
                }
                
                // Loading overlay
                /*
                 if viewModel.isLoading {
                 LoadingView()
                 }
                 */
                
                // Error message
                if let errorMessage = viewModel.errorMessage {
                    ErrorToast(message: errorMessage) {
                        viewModel.errorMessage = nil
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.isEditingProfile {
                        Button("cancel".localized) {
                            viewModel.cancelEditing()
                        }
                    } else {
                        Button("edit".localized) {
                            viewModel.isEditingProfile = true
                        }
                    }
                }
            }
            
            .circularLoading(
                isLoading: viewModel.isLoading,
                message: "loading".localized,
                strokeColor: .blue,
                backgroundColor: .gray.opacity(0.1),
                showBackdrop: true,
                containerSize: 80,
                logoSize: 50
            )
            
            .sheet(isPresented: $showingAddressManager) {
                if let userId = viewModel.user?.id {
                    ShippingAddressesManagerView(userId: userId)
                }
            }
        }
        .actionSheet(isPresented: $showingLogoutConfirmation) {
            ActionSheet(
                title: Text("logout".localized),
                message: Text("logout_confirmation".localized),
                buttons: [
                    .destructive(Text("logout".localized)) {
                        viewModel.logout()
                    },
                    .cancel()
                ]
            )
        }
        .onAppear {
            if viewModel.user != nil {
                viewModel.loadUserProfile()
            }
        }
    }
    
    private var editProfileView: some View {
        Form {
            Section(header: Text("personal_information".localized)) {
                CustomTextField(
                    title: "first_name".localized,
                    placeholder: "first_name_placeholder".localized,
                    type: .regular,
                    state: viewModel.firstNameState,
                    text: $viewModel.firstName,
                    onEditingChanged: { isEditing in
                        if !isEditing && !viewModel.firstName.isEmpty {
                            viewModel.validateFirstName()
                        }
                    }
                )
                .padding(.vertical, 8)
                
                CustomTextField(
                    title: "last_name".localized,
                    placeholder: "last_name_placeholder".localized,
                    type: .regular,
                    state: viewModel.lastNameState,
                    text: $viewModel.lastName,
                    onEditingChanged: { isEditing in
                        if !isEditing && !viewModel.lastName.isEmpty {
                            viewModel.validateLastName()
                        }
                    }
                )
                .padding(.vertical, 8)
            }
            
            Section {
                Button(action: {
                    viewModel.saveProfile()
                }) {
                    HStack {
                        if viewModel.isSavingProfile {
                            ProgressView()
                                .padding(.trailing, 8)
                        }
                        
                        Text("save_changes".localized)
                            .frame(maxWidth: .infinity)
                    }
                }
                .disabled(!viewModel.isFormValid || viewModel.isSavingProfile)
            }
        }
    }
    
    private func profileView(user: User) -> some View {
        List {
            // User Info
            Section(header: Text("personal_information".localized)) {
                VStack(spacing: 20) {
                    // Avatar
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)
                        .foregroundColor(.blue)
                        .padding(.bottom, 8)
                    
                    // Name and Email
                    VStack(spacing: 8) {
                        Text("hello_user".localized + " \(user.firstName)")
                            .font(.title3)
                            .fontWeight(.bold)
                        
                        Text(user.email)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }
            
            // Shipping Information
            Section {
                Button(action: {
                    showingAddressManager = true
                }) {
                    HStack {
                        Text("Manage Shipping Addresses")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                if let addresses = user.shippingDetails, !addresses.isEmpty {
                    ForEach(addresses.prefix(2), id: \.id) { address in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(address.fullName ?? "")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                
                                if address.isDefault ?? false {
                                    Text("Default")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.blue.opacity(0.2))
                                        .foregroundColor(.blue)
                                        .cornerRadius(4)
                                }
                                
                                Spacer()
                            }
                            
                            Text(address.address ?? "")
                                .font(.caption)
                            Text("\(address.city ?? ""), \(address.state ?? "") \(address.postalCode ?? "")")
                                .font(.caption)
                            Text(address.country ?? "")
                                .font(.caption)
                        }
                        .padding(.vertical, 4)
                    }
                    
                    if (user.shippingDetails?.count ?? 0) > 2 {
                        Text("+ \((user.shippingDetails?.count ?? 0) - 2) more addresses")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text("No shipping addresses")
                        .foregroundColor(.secondary)
                        .padding(.vertical, 8)
                }
            } header: {
                Text("shipping_information".localized)
            }
            
            // Orders
            Section(header: Text("my_orders".localized)) {
                if let orders = user.orders, !orders.isEmpty {
                    NavigationLink(destination: OrdersListView(viewModel: DependencyInjector.shared.resolve(OrdersViewModel.self))) {
                        Label("Mis Pedidos", systemImage: "list.bullet.clipboard")
                    }
                } else {
                    Text("no_orders".localized)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 8)
                }
            }
            
            // Actions
            Section {
                NavigationLink(destination: Text("my_wishlist".localized)) {
                    Label("my_wishlist".localized, systemImage: "heart")
                }
                
                NavigationLink(destination: Text("payment_methods".localized)) {
                    Label("payment_methods".localized, systemImage: "creditcard")
                }
                
                NavigationLink(destination: Text("notifications".localized)) {
                    Label("notifications".localized, systemImage: "bell")
                }
                
                NavigationLink(destination: LanguageSettingsView()) {
                    Label("language".localized, systemImage: "globe")
                }
                
                NavigationLink(destination: Text("help_support".localized)) {
                    Label("help_support".localized, systemImage: "questionmark.circle")
                }
                
                Button(action: {
                    showingLogoutConfirmation = true
                }) {
                    HStack {
                        Label("logout".localized, systemImage: "arrow.right.square")
                            .foregroundColor(.red)
                        
                        Spacer()
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
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
