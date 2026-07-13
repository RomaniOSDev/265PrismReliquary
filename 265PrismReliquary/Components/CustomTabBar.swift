import SwiftUI

enum AppTab: Hashable {
    case home
    case recipes
    case kitchen
    case stats
    case settings
}

struct MainTabView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var selectedTab: AppTab = .home
    @State private var tabBarHiddenCount = 0

    private var showsTabBar: Bool { tabBarHiddenCount == 0 }

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case .home:
                    HomeView(selectedTab: $selectedTab, tabBarHiddenCount: $tabBarHiddenCount)
                case .recipes:
                    Feature1View(tabBarHiddenCount: $tabBarHiddenCount)
                case .kitchen:
                    KitchenHubView(tabBarHiddenCount: $tabBarHiddenCount)
                case .stats:
                    StatsView()
                case .settings:
                    SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if showsTabBar {
                CustomTabBar(selectedTab: $selectedTab)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showsTabBar)
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: AppTab
    @State private var pressedTab: AppTab?

    private let items: [(AppTab, String, String)] = [
        (.home, "house.fill", "Home"),
        (.recipes, "fork.knife", "Recipes"),
        (.kitchen, "cart.fill", "Kitchen"),
        (.stats, "chart.bar.fill", "Stats"),
        (.settings, "gearshape.fill", "Settings")
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items, id: \.0) { item in
                let isSelected = selectedTab == item.0
                Button {
                    FeedbackService.lightTap()
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        selectedTab = item.0
                    }
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: item.1)
                            .font(.system(size: 16, weight: .semibold))
                        Text(item.2)
                            .font(.system(size: 10, weight: .semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .foregroundStyle(isSelected ? Color("AppTextPrimary") : Color("AppTextSecondary"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(
                                isSelected
                                    ? LinearGradient(
                                        colors: [Color("AppAccent").opacity(0.95), Color("AppPrimary")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                    : LinearGradient(
                                        colors: [Color.clear, Color.clear],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                            )
                    )
                    .scaleEffect(pressedTab == item.0 ? 0.95 : 1)
                }
                .buttonStyle(.plain)
                .frame(minHeight: 44)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in pressedTab = item.0 }
                        .onEnded { _ in pressedTab = nil }
                )
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color("AppSurface").opacity(0.98),
                            Color("AppPrimary").opacity(0.28)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color("AppAccent").opacity(0.4),
                                    Color("AppPrimary").opacity(0.15)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .softShadow(.floating)
        .padding(.horizontal, 12)
        .padding(.bottom, 10)
    }
}
