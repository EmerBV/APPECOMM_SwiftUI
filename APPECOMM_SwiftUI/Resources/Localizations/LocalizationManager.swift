import Foundation

enum Language: String {
    case english = "en"
    case spanish = "es"
    
    var displayName: String {
        switch self {
        case .english:
            return "English"
        case .spanish:
            return "Español"
        }
    }
}

class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    
    @Published var currentLanguage: Language {
        didSet {
            UserDefaults.standard.set([currentLanguage.rawValue], forKey: "AppleLanguages")
            UserDefaults.standard.synchronize()
            NotificationCenter.default.post(name: NSNotification.Name("LanguageChanged"), object: nil)
        }
    }
    
    private init() {
        if let languageCode = UserDefaults.standard.array(forKey: "AppleLanguages")?.first as? String,
           let language = Language(rawValue: languageCode) {
            currentLanguage = language
        } else {
            currentLanguage = .english
        }
    }
    
    func localizedString(for key: String) -> String {
        let path = Bundle.main.path(forResource: currentLanguage.rawValue, ofType: "lproj")
        let bundle = Bundle(path: path ?? "") ?? Bundle.main
        return NSLocalizedString(key, tableName: nil, bundle: bundle, value: key, comment: "")
    }
    
}

