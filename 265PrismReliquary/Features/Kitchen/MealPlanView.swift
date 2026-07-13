import SwiftUI

struct MealPlanView: View {
    @EnvironmentObject private var store: AppDataStore
    @Binding var tabBarHiddenCount: Int
    @State private var showPicker = false
    @State private var selectedDay = 0
    @State private var alertMessage: String?
    @State private var showSuccess = false

    var body: some View {
        let _ = tabBarHiddenCount
        ZStack {
            ScrollView {
                VStack(spacing: 16) {
                    SurfaceCard {
                        VStack(alignment: .leading, spacing: 10) {
                            SectionHeaderView(
                                title: "This week",
                                subtitle: "Plan 3–7 dishes, then build one grocery list"
                            )
                            HStack(spacing: 10) {
                                MetricTile(title: "Planned", value: "\(store.mealPlanCount)/7", symbol: "calendar", inset: true)
                                MetricTile(title: "Cooked", value: "\(store.mealPlan.filter(\.isCooked).count)", symbol: "checkmark.seal.fill", inset: true)
                            }
                        }
                    }

                    ForEach(WeekDay.allCases) { day in
                        dayCard(day)
                    }

                    AppPrimaryButton(title: "Build Grocery From Plan", symbol: "cart.badge.plus") {
                        store.buildGroceryFromMealPlan()
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            showSuccess = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { showSuccess = false }
                    }
                    .disabled(store.mealPlan.isEmpty)
                    .opacity(store.mealPlan.isEmpty ? 0.5 : 1)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .tabBarClearance(120)
            }
            .clearScrollBackground()

            SuccessCheckOverlay(isVisible: showSuccess)
        }
        .sheet(isPresented: $showPicker) {
            MealRecipePicker(dayIndex: selectedDay) { recipeId in
                if let error = store.addToMealPlan(recipeId: recipeId, dayIndex: selectedDay) {
                    FeedbackService.warning()
                    alertMessage = error
                } else {
                    FeedbackService.mediumTap()
                }
            }
            .environmentObject(store)
        }
        .alert("Meal Plan", isPresented: Binding(
            get: { alertMessage != nil },
            set: { if !$0 { alertMessage = nil } }
        )) {
            Button("OK", role: .cancel) { alertMessage = nil }
        } message: {
            Text(alertMessage ?? "")
        }
    }

    private func dayCard(_ day: WeekDay) -> some View {
        let entries = store.mealPlan.filter { $0.dayIndex == day.rawValue }
        return SurfaceCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(day.fullTitle)
                            .font(.headline)
                            .foregroundStyle(Color("AppTextPrimary"))
                        Text(entries.isEmpty ? "Open slot" : "\(entries.count) dish\(entries.count == 1 ? "" : "es")")
                            .font(.caption)
                            .foregroundStyle(Color("AppTextSecondary"))
                    }
                    Spacer()
                    IconActionButton(symbol: "plus") {
                        selectedDay = day.rawValue
                        showPicker = true
                    }
                }

                if entries.isEmpty {
                    Text("Tap + to add a recipe for \(day.title)")
                        .font(.caption)
                        .foregroundStyle(Color("AppTextSecondary"))
                        .padding(.vertical, 6)
                } else {
                    ForEach(entries) { entry in
                        if let recipe = store.recipe(by: entry.recipeId) {
                            MealPlanDishCell(
                                recipe: recipe,
                                isCooked: entry.isCooked,
                                onCooked: { store.markMealCooked(id: entry.id) },
                                onRemove: { store.removeFromMealPlan(id: entry.id) }
                            )
                        }
                    }
                }
            }
        }
    }
}

private struct MealRecipePicker: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.dismiss) private var dismiss
    let dayIndex: Int
    let onPick: (String) -> Void
    @State private var query = ""

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(filtered) { recipe in
                            Button {
                                onPick(recipe.id)
                                dismiss()
                            } label: {
                                RecipeCardCell(
                                    recipe: recipe,
                                    isFavourite: store.isFavourite(recipe.id),
                                    timesCooked: store.timesCooked(recipeId: recipe.id)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(20)
                }
                .clearScrollBackground()
            }
            .searchable(text: $query, prompt: "Search recipes")
            .navigationTitle("Add Dish")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(Color("AppTextSecondary"))
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var filtered: [Recipe] {
        let base = store.allRecipes
        guard !query.isEmpty else { return base }
        return base.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }
}
