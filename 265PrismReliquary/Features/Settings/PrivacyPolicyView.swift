import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss

    private var policyText: String {
        if let url = Bundle.main.url(forResource: "privacy_policy", withExtension: "md"),
           let content = try? String(contentsOf: url, encoding: .utf8) {
            return content
        }
        return """
        # Privacy Policy
        This app does NOT collect, store, or transmit any personal data.
        • No user accounts, no logins.
        • No analytics, no tracking, no advertising SDKs.
        • All your data (settings, saved items, progress) is stored locally on your device using UserDefaults and never leaves it.
        • The app does not request access to your camera, microphone, location, contacts, photos, motion sensors, or HealthKit.
        • The app does not use cookies or third-party services.
        • The app does not use cross-app tracking (App Tracking Transparency dialog is therefore not shown).
        If you have any questions, contact support@example.com.
        """
    }

    private var markdownBody: AttributedString {
        (try? AttributedString(
            markdown: policyText,
            options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        )) ?? AttributedString(policyText)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()
                ScrollView {
                    Text(markdownBody)
                        .foregroundStyle(Color("AppTextPrimary"))
                        .tint(Color("AppPrimary"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 28)
                }
                .clearScrollBackground()
            }
            .navigationTitle("Privacy Policy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color("AppBackground"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        FeedbackService.lightTap()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color("AppTextSecondary"))
                            .frame(width: 44, height: 44)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
