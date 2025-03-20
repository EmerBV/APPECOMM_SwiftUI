import SwiftUI

struct ConnectSection: View {
    @State private var showNewsletterSignup = false
    
    var body: some View {
        VStack(spacing: 32) {
            // Título
            Text("CONNECT WITH US")
                .font(.title2)
                .fontWeight(.bold)
            
            // Iconos de redes sociales
            HStack(spacing: 20) {
                SocialButton(icon: "facebook", url: "https://facebook.com")
                SocialButton(icon: "twitter", url: "https://twitter.com")
                SocialButton(icon: "youtube", url: "https://youtube.com")
                SocialButton(icon: "instagram", url: "https://instagram.com")
                SocialButton(icon: "pinterest", url: "https://pinterest.com")
                SocialButton(icon: "tiktok", url: "https://tiktok.com")
                SocialButton(icon: "discord", url: "https://discord.com")
            }
            
            // Newsletter signup
            VStack(spacing: 16) {
                Text("Want $20 Off? Sign up for our Newsletter.")
                    .font(.headline)
                
                Text("Sign up for SMS alerts and be the first to know!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Button(action: {
                    showNewsletterSignup.toggle()
                }) {
                    HStack {
                        Image(systemName: "envelope.fill")
                        Image(systemName: "message.fill")
                        Text("GET IN THE LOOP!")
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
                .padding(.horizontal)
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
            Image(icon) // Asegúrate de tener estas imágenes en tus assets
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
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