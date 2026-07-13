import SwiftUI
import StoreKit
import UIKit

struct SettingsView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var showResetAlert = false

    private var versionText: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        return "Version \(version ?? "1.0")"
    }

    private let metricColumns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()
                ScrollView {
                    VStack(spacing: 18) {
                        SurfaceCard {
                            VStack(alignment: .leading, spacing: 12) {
                                SectionHeaderView(title: "Your activity", subtitle: "Local counters only")
                                LazyVGrid(columns: metricColumns, spacing: 10) {
                                    MetricTile(
                                        title: "Entries",
                                        value: "\(store.groceryItems.count + store.favouriteRecipes.count + store.cookTimers.count)",
                                        symbol: "square.stack.3d.up.fill",
                                        inset: true
                                    )
                                    MetricTile(title: "Minutes", value: "\(store.totalMinutesUsed)", symbol: "clock.fill", inset: true)
                                    MetricTile(title: "Streak", value: "\(store.streakDays)d", symbol: "flame.fill", inset: true)
                                }
                                InsightRowCell(title: "Sessions completed", value: "\(store.totalSessionsCompleted)", symbol: "checkmark.circle")
                                InsightRowCell(title: "Custom recipes", value: "\(store.customRecipes.count)", symbol: "square.and.pencil")
                                InsightRowCell(title: "Pantry items", value: "\(store.pantryItems.count)", symbol: "refrigerator")
                            }
                        }

                        SettingsRowCell(title: "Rate Us", symbol: "star.fill") {
                            FeedbackService.lightTap()
                            rateApp()
                        }

                        SettingsRowCell(title: "Privacy Policy", symbol: "lock.shield") {
                            FeedbackService.lightTap()
                            openPrivacyPolicy()
                        }

                        SettingsRowCell(title: "Terms of Use", symbol: "doc.text") {
                            FeedbackService.lightTap()
                            openTermsOfUse()
                        }

                        SettingsRowCell(title: "Reset All Data", symbol: "trash", destructive: true) {
                            FeedbackService.lightTap()
                            showResetAlert = true
                        }

                        Text(versionText)
                            .font(.footnote)
                            .foregroundStyle(Color("AppTextSecondary"))
                            .frame(maxWidth: .infinity)
                            .padding(.top, 4)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .tabBarClearance()
                }
                .clearScrollBackground()
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color("AppBackground"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .alert("Reset All Data?", isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) { FeedbackService.lightTap() }
                Button("Reset", role: .destructive) {
                    FeedbackService.warning()
                    store.resetAllData()
                }
            } message: {
                Text("This permanently clears recipes favourites, grocery lists, timers, and progress on this device.")
            }
        }
        .transparentScreenChrome()
    }

    private func openPrivacyPolicy() {
        if let url = URL(string: AppLinks.privacyPolicy) {
            UIApplication.shared.open(url)
        }
    }

    private func openTermsOfUse() {
        if let url = URL(string: AppLinks.termsOfUse) {
            UIApplication.shared.open(url)
        }
    }

    private func rateApp() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }
}
