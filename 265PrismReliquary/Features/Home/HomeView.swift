import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: AppDataStore
    @Binding var selectedTab: AppTab
    @Binding var tabBarHiddenCount: Int

    private var todayIndex: Int {
        let weekday = Calendar.current.component(.weekday, from: Date())
        // Convert Sunday=1...Saturday=7 to Mon=0...Sun=6
        return (weekday + 5) % 7
    }

    private var todaysMeals: [MealPlanEntry] {
        store.mealPlan.filter { $0.dayIndex == todayIndex }
    }

    private var groceryDone: Int {
        store.groceryItems.filter(\.completed).count
    }

    private var groceryTotal: Int {
        store.groceryItems.count
    }

    private var groceryProgress: CGFloat {
        guard groceryTotal > 0 else { return 0 }
        return CGFloat(groceryDone) / CGFloat(groceryTotal)
    }

    private var activeTimers: [CookTimerItem] {
        store.cookTimers.filter { !$0.isCompleted }.prefix(3).map { $0 }
    }

    private var featuredRecipes: [Recipe] {
        let favourites = store.allRecipes.filter { store.isFavourite($0.id) }
        if favourites.count >= 4 { return Array(favourites.prefix(6)) }
        return Array(store.allRecipes.prefix(6))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()

                ScrollView {
                    VStack(spacing: 18) {
                        heroWidget
                        quickActionsRow
                        todayMealWidget
                        HStack(spacing: 12) {
                            groceryWidget
                            timerWidget
                        }
                        streakInsightsWidget
                        featuredRecipesWidget
                        tipsWidget
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .tabBarClearance()
                }
                .clearScrollBackground()
            }
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color("AppBackground"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .transparentScreenChrome()
    }

    // MARK: - Hero

    private var heroWidget: some View {
        ZStack(alignment: .bottomLeading) {
            Image("HomeHeroKitchen")
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 190)
                .clipped()

            LinearGradient(
                colors: [
                    Color("AppBackground").opacity(0.05),
                    Color("AppBackground").opacity(0.92)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 8) {
                Text(greeting)
                    .font(.title2.bold())
                    .foregroundStyle(Color("AppTextPrimary"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(heroSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(Color("AppTextSecondary"))
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
                HStack(spacing: 8) {
                    TagChip(text: "\(store.streakDays) day streak", emphasized: true)
                    TagChip(text: "\(store.mealPlanCount) planned")
                    TagChip(text: "\(store.cookingHistory.count) cooked")
                }
            }
            .padding(16)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color("AppAccent").opacity(0.45), Color("AppPrimary").opacity(0.15)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .softShadow(.floating)
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Good morning" }
        if hour < 18 { return "Good afternoon" }
        return "Good evening"
    }

    private var heroSubtitle: String {
        if todaysMeals.isEmpty {
            return "Plan today’s meals and build a smart grocery list."
        }
        return "You have \(todaysMeals.count) dish\(todaysMeals.count == 1 ? "" : "es") planned for today."
    }

    // MARK: - Quick actions

    private var quickActionsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                quickChip("Recipes", "fork.knife") { selectedTab = .recipes }
                quickChip("Meal Plan", "calendar") {
                    store.preferredKitchenSegment = 0
                    selectedTab = .kitchen
                }
                quickChip("Groceries", "cart.fill") {
                    store.preferredKitchenSegment = 1
                    selectedTab = .kitchen
                }
                quickChip("Timers", "timer") {
                    store.preferredKitchenSegment = 2
                    selectedTab = .kitchen
                }
                quickChip("Insights", "chart.bar.fill") { selectedTab = .stats }
                NavigationLink {
                    PantryDietView()
                        .onAppear { tabBarHiddenCount += 1 }
                        .onDisappear { tabBarHiddenCount = max(0, tabBarHiddenCount - 1) }
                } label: {
                    Label("Pantry", systemImage: "refrigerator")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color("AppTextPrimary"))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color("AppSurface"))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color("AppAccent").opacity(0.25), lineWidth: 1))
                }
                .simultaneousGesture(TapGesture().onEnded { FeedbackService.lightTap() })
            }
            .padding(.vertical, 2)
        }
    }

    private func quickChip(_ title: String, _ symbol: String, action: @escaping () -> Void) -> some View {
        Button {
            FeedbackService.lightTap()
            action()
        } label: {
            Label(title, systemImage: symbol)
                .font(.caption.weight(.bold))
                .foregroundStyle(Color("AppTextPrimary"))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color("AppSurface"))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color("AppAccent").opacity(0.25), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Today meals

    private var todayMealWidget: some View {
        SurfaceCard(padding: 14, cornerRadius: 20) {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeaderView(
                    title: "Today’s plate",
                    subtitle: WeekDay(rawValue: todayIndex)?.fullTitle ?? "Today",
                    trailing: AnyView(
                        Button("Open plan") {
                            FeedbackService.lightTap()
                            selectedTab = .kitchen
                        }
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color("AppAccent"))
                    )
                )

                if todaysMeals.isEmpty {
                    HStack(spacing: 12) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.title2)
                            .foregroundStyle(Color("AppAccent"))
                            .frame(width: 48, height: 48)
                            .background(Circle().fill(Color("AppPrimary").opacity(0.25)))
                        VStack(alignment: .leading, spacing: 4) {
                            Text("No meals for today")
                                .font(.headline)
                                .foregroundStyle(Color("AppTextPrimary"))
                            Text("Add 3–7 dishes this week to stay organized.")
                                .font(.caption)
                                .foregroundStyle(Color("AppTextSecondary"))
                        }
                    }
                    AppPrimaryButton(title: "Plan This Week", symbol: "calendar") {
                        selectedTab = .kitchen
                    }
                } else {
                    ForEach(todaysMeals) { entry in
                        if let recipe = store.recipe(by: entry.recipeId) {
                            NavigationLink {
                                RecipeDetailView(recipe: recipe)
                                    .onAppear { tabBarHiddenCount += 1 }
                                    .onDisappear { tabBarHiddenCount = max(0, tabBarHiddenCount - 1) }
                            } label: {
                                HStack(spacing: 12) {
                                    recipeThumb(recipe)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(recipe.name)
                                            .font(.headline)
                                            .foregroundStyle(Color("AppTextPrimary"))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                                        Text("\(recipe.cookTimeMinutes) min · \(recipe.mealType)")
                                            .font(.caption)
                                            .foregroundStyle(Color("AppTextSecondary"))
                                    }
                                    Spacer()
                                    if entry.isCooked {
                                        TagChip(text: "Done", emphasized: true)
                                    } else {
                                        Button("Cooked") {
                                            store.markMealCooked(id: entry.id)
                                        }
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(Color("AppTextPrimary"))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 8)
                                        .background(Color("AppPrimary"))
                                        .clipShape(Capsule())
                                    }
                                }
                                .padding(10)
                                .background(Color("AppBackground").opacity(0.28))
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Grocery + Timer widgets

    private var groceryWidget: some View {
        Button {
            FeedbackService.lightTap()
            selectedTab = .kitchen
        } label: {
            SurfaceCard(padding: 12, cornerRadius: 20) {
                VStack(alignment: .leading, spacing: 10) {
                    Image("HomeWidgetGrocery")
                        .resizable()
                        .scaledToFill()
                        .frame(height: 88)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                    Text("Groceries")
                        .font(.headline)
                        .foregroundStyle(Color("AppTextPrimary"))

                    if groceryTotal == 0 {
                        Text("List is empty")
                            .font(.caption)
                            .foregroundStyle(Color("AppTextSecondary"))
                    } else {
                        ProgressView(value: groceryProgress)
                            .tint(Color("AppAccent"))
                        Text("\(groceryDone)/\(groceryTotal) checked")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color("AppPrimary"))
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var timerWidget: some View {
        Button {
            FeedbackService.lightTap()
            selectedTab = .kitchen
        } label: {
            SurfaceCard(padding: 12, cornerRadius: 20) {
                VStack(alignment: .leading, spacing: 10) {
                    Image("HomeWidgetTimer")
                        .resizable()
                        .scaledToFill()
                        .frame(height: 88)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                    Text("Timers")
                        .font(.headline)
                        .foregroundStyle(Color("AppTextPrimary"))

                    if activeTimers.isEmpty {
                        Text("No active timers")
                            .font(.caption)
                            .foregroundStyle(Color("AppTextSecondary"))
                    } else {
                        ForEach(activeTimers.prefix(2)) { timer in
                            HStack {
                                Circle()
                                    .fill(timer.isRunning ? Color("AppAccent") : Color("AppTextSecondary"))
                                    .frame(width: 8, height: 8)
                                Text(timer.name)
                                    .font(.caption)
                                    .foregroundStyle(Color("AppTextSecondary"))
                                    .lineLimit(1)
                            }
                        }
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Insights

    private var streakInsightsWidget: some View {
        SurfaceCard(padding: 14, cornerRadius: 20) {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeaderView(
                    title: "Kitchen pulse",
                    subtitle: "Live counters from your cooking",
                    trailing: AnyView(
                        Button("Stats") {
                            FeedbackService.lightTap()
                            selectedTab = .stats
                        }
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color("AppAccent"))
                    )
                )
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    MetricTile(title: "Streak", value: "\(store.streakDays)d", symbol: "flame.fill", inset: true)
                    MetricTile(title: "Minutes", value: "\(store.totalMinutesUsed)", symbol: "timer", inset: true)
                    MetricTile(title: "Pantry", value: "\(store.pantryItems.count)", symbol: "refrigerator", inset: true)
                }
            }
        }
    }

    // MARK: - Featured

    private var featuredRecipesWidget: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeaderView(
                title: "Featured for you",
                subtitle: store.favouriteRecipes.isEmpty ? "Popular picks to start" : "From your favourites",
                trailing: AnyView(
                    Button("See all") {
                        FeedbackService.lightTap()
                        selectedTab = .recipes
                    }
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color("AppAccent"))
                )
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(featuredRecipes) { recipe in
                        NavigationLink {
                            RecipeDetailView(recipe: recipe)
                                .onAppear { tabBarHiddenCount += 1 }
                                .onDisappear { tabBarHiddenCount = max(0, tabBarHiddenCount - 1) }
                        } label: {
                            featuredCard(recipe)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func featuredCard(_ recipe: Recipe) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                recipeThumb(recipe, size: 148)
                if store.isFavourite(recipe.id) {
                    Image(systemName: "heart.fill")
                        .font(.caption)
                        .foregroundStyle(Color("AppAccent"))
                        .padding(8)
                }
            }
            Text(recipe.name)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Color("AppTextPrimary"))
                .lineLimit(2)
                .minimumScaleFactor(0.75)
                .frame(width: 148, alignment: .leading)
            Text("\(recipe.cookTimeMinutes) min")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color("AppPrimary"))
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color("AppSurface"), Color("AppPrimary").opacity(0.28)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color("AppAccent").opacity(0.22), lineWidth: 1)
                )
        )
        .softShadow(.raised)
    }

    private var tipsWidget: some View {
        SurfaceCard(padding: 14, cornerRadius: 20) {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeaderView(title: "Quick tip", subtitle: "Make the most of your kitchen flow")
                Text(tipText)
                    .font(.subheadline)
                    .foregroundStyle(Color("AppTextSecondary"))
                HStack(spacing: 10) {
                    AppPrimaryButton(title: "Browse", symbol: "fork.knife", filled: false) {
                        selectedTab = .recipes
                    }
                    AppPrimaryButton(title: "Cook Mode", symbol: "list.number") {
                        if let first = todaysMeals.first, let recipe = store.recipe(by: first.recipeId) {
                            // Navigate via recipes tab + user opens cook mode; jump to recipes if no meal
                            selectedTab = .recipes
                            store.lastVisitedRecipeId = recipe.id
                        } else {
                            selectedTab = .recipes
                        }
                    }
                }
            }
        }
    }

    private var tipText: String {
        if store.pantryItems.isEmpty {
            return "Add pantry staples, then turn on pantry filter to see what you can cook now."
        }
        if store.mealPlan.isEmpty {
            return "Build a weekly meal plan, then generate one merged grocery list in a tap."
        }
        if groceryTotal == 0 {
            return "Your plan is ready — build groceries from the meal plan to shop faster."
        }
        return "Use Cook Mode for step-by-step cooking with timers that stay on screen."
    }

    private func recipeThumb(_ recipe: Recipe, size: CGFloat = 54) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color("AppPrimary").opacity(0.3))
            AsyncImage(url: URL(string: recipe.imageURL)) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                default:
                    Image(systemName: "fork.knife")
                        .foregroundStyle(Color("AppTextPrimary"))
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .frame(width: size, height: size)
    }
}
