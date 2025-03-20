import Foundation

extension Bundle {
    var releaseVersion: String {
        return infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    var buildVersion: String {
        return infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    var fullVersion: String {
        return "\(releaseVersion) (\(buildVersion))"
    }
} 