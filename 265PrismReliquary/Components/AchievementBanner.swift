import SwiftUI

struct AchievementBannerHost: ViewModifier {
    @ObservedObject var store: AppDataStore
    @State private var current: AchievementDefinition?
    @State private var isVisible = false

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if let current, isVisible {
                    HStack(spacing: 12) {
                        Image(systemName: current.symbolName)
                            .foregroundStyle(Color("AppAccent"))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Achievement unlocked")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color("AppTextSecondary"))
                            Text(current.title)
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(Color("AppTextPrimary"))
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color("AppSurface"))
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .achievementUnlocked)) { _ in
                presentNextIfNeeded()
            }
            .onAppear {
                presentNextIfNeeded()
            }
    }

    private func presentNextIfNeeded() {
        guard current == nil else { return }
        guard let next = store.consumeNextAchievementBanner() else { return }
        FeedbackService.success()
        current = next
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            isVisible = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 0.3)) {
                isVisible = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                current = nil
                presentNextIfNeeded()
            }
        }
    }
}

struct SuccessCheckOverlay: View {
    let isVisible: Bool

    var body: some View {
        if isVisible {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(Color("AppAccent"))
                .transition(.scale.combined(with: .opacity))
        }
    }
}

extension View {
    func achievementBannerHost(store: AppDataStore) -> some View {
        modifier(AchievementBannerHost(store: store))
    }
}
