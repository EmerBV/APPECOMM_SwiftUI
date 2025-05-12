import SwiftUI

struct LanguageSettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        List {
            Section(header: Text("language_settings".localized)) {
                ForEach([Language.english, .spanish], id: \.self) { language in
                    HStack {
                        Text(language.displayName)
                        Spacer()
                        if localizationManager.currentLanguage == language {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        localizationManager.currentLanguage = language
                    }
                }
            }
        }
        .navigationTitle("language".localized)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "chevron.left")
                    //.foregroundColor(.blue)
                }
            }
        }
    }
}
