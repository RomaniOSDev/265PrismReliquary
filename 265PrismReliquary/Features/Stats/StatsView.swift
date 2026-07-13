import SwiftUI

struct StatsView: View {
    @EnvironmentObject private var store: AppDataStore

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()
                ScrollView {
                    VStack(spacing: 18) {
                        SectionHeaderView(title: "Overview", subtitle: "Real kitchen activity, not scores")

                        LazyVGrid(columns: columns, spacing: 12) {
                            MetricTile(title: "Recipes viewed", value: "\(store.recipesViewed)", symbol: "eye.fill")
                            MetricTile(title: "Meals planned", value: "\(store.mealPlanCount)", symbol: "calendar")
                            MetricTile(title: "Times cooked", value: "\(store.cookingHistory.count)", symbol: "flame.fill")
                            MetricTile(title: "Streak days", value: "\(store.streakDays)", symbol: "bolt.fill")
                            MetricTile(title: "Lists done", value: "\(store.listsCompleted)", symbol: "checklist")
                            MetricTile(title: "Minutes timed", value: "\(store.totalMinutesUsed)", symbol: "timer")
                        }

                        SurfaceCard {
                            VStack(alignment: .leading, spacing: 10) {
                                SectionHeaderView(title: "Cooking history", subtitle: "Most prepared dishes")
                                if store.cookingHistory.isEmpty {
                                    Text("Finish Cook Mode or mark a planned meal as cooked.")
                                        .font(.caption)
                                        .foregroundStyle(Color("AppTextSecondary"))
                                } else {
                                    ForEach(store.topCookedRecipes(), id: \.name) { item in
                                        InsightRowCell(title: item.name, value: "\(item.count)×", symbol: "fork.knife")
                                    }
                                    if let latest = store.cookingHistory.first {
                                        TagChip(text: "Last: \(latest.recipeName)", emphasized: true)
                                    }
                                }
                            }
                        }

                        SurfaceCard {
                            VStack(alignment: .leading, spacing: 10) {
                                SectionHeaderView(title: "Frequent groceries", subtitle: "What you shop for most")
                                let frequent = store.frequentGroceryNames()
                                if frequent.isEmpty {
                                    Text("Build a grocery list from recipes or meal plan.")
                                        .font(.caption)
                                        .foregroundStyle(Color("AppTextSecondary"))
                                } else {
                                    ForEach(frequent, id: \.name) { item in
                                        InsightRowCell(title: item.name, value: "\(item.count)", symbol: "cart.fill")
                                    }
                                }
                            }
                        }

                        SectionHeaderView(title: "Achievements", subtitle: "Decorative unlocks from real actions")

                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(AchievementCatalog.all) { achievement in
                                AchievementCardCell(
                                    achievement: achievement,
                                    unlocked: AchievementCatalog.isUnlocked(achievement.id, store: store)
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .tabBarClearance()
                }
                .clearScrollBackground()
            }
            .navigationTitle("Kitchen Insights")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color("AppBackground"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .transparentScreenChrome()
    }
}
