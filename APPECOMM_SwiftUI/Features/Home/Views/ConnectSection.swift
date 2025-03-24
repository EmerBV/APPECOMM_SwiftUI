import SwiftUI

struct ConnectSection: View {
    @State private var showNewsletterSignup = false
    
    private let socialNetworks = [
        ("facebook_icon", "https://facebook.com"),
        ("instagram_icon", "https://instagram.com"),
        ("x_twitter_icon", "https://twitter.com"),
        ("whatsapp_icon", "https://whatsapp.com")
    ]
    
    var body: some View {
        VStack(spacing: 32) {
            // Título
            Text("connect_with_us".localized)
                .font(.title2)
                .fontWeight(.bold)
            
            // Iconos de redes sociales
            HStack(spacing: 24) {
                ForEach(socialNetworks, id: \.0) { network, url in
                    SocialButton(icon: network, url: url)
                }
            }
            .padding(.horizontal)
            
            // Newsletter signup
            VStack(spacing: 16) {
                Text("newsletter_title".localized)
                    .font(.headline)
                
                Text("newsletter_subtitle".localized)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Button(action: {
                    showNewsletterSignup.toggle()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "envelope.fill")
                        Image(systemName: "message.fill")
                        Text("get_in_the_loop".localized)
                            .fontWeight(.bold)
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(8)
                }
                .padding(.horizontal)
            }
            
            // Footer links
            VStack(spacing: 16) {
                HStack(spacing: 16) {
                    Link("Privacy Policy", destination: URL(string: "https://example.com/privacy")!)
                    Text("|")
                    Link("Terms & Conditions", destination: URL(string: "https://example.com/terms")!)
                    Text("|")
                    Link("Accessibility Statement", destination: URL(string: "https://example.com/accessibility")!)
                }
                .font(.caption)
                .foregroundColor(.secondary)
                
                Text("Series content, product specifications, release dates and pricing are subject to change. All Rights Reserved.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)
        }
        .padding(.vertical, 32)
        .sheet(isPresented: $showNewsletterSignup) {
            NewsletterSignupView()
        }
    }
}

private struct SocialButton: View {
    let icon: String
    let url: String
    
    var body: some View {
        Link(destination: URL(string: url)!) {
            Image(icon)
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 32)
        }
    }
}

private struct NewsletterSignupView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var phoneNumber = ""
    @State private var acceptTerms = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Sign up for exclusive offers")) {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    TextField("Phone Number (optional)", text: $phoneNumber)
                        .keyboardType(.phonePad)
                    
                    Toggle("I accept the terms and conditions", isOn: $acceptTerms)
                }
                
                Button(action: {
                    // Aquí iría la lógica de registro
                    dismiss()
                }) {
                    Text("Sign Up")
                }
                .disabled(!acceptTerms || email.isEmpty)
            }
            .navigationTitle("Newsletter Signup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
} 
