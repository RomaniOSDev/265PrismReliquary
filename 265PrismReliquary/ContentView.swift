import SwiftUI

struct ContentView: View {
    @StateObject private var store = AppDataStore.shared

    var body: some View {
        Group {
            if store.hasSeenOnboarding {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .environmentObject(store)
        .achievementBannerHost(store: store)
        .preferredColorScheme(.dark)
        .animation(.easeInOut(duration: 0.3), value: store.hasSeenOnboarding)
    }
}

#Preview {
    ContentView()
}
