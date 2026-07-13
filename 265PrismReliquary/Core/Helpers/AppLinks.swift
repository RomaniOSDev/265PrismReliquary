import Foundation

enum AppLinks {
    static let privacyPolicy = "https://prismreliquary265.site/privacy/345"
    static let termsOfUse = "https://prismreliquary265.site/terms/345"

    static var privacyPolicyURL: URL? {
        URL(string: privacyPolicy)
    }

    static var termsOfUseURL: URL? {
        URL(string: termsOfUse)
    }
}
