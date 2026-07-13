import SwiftUI

struct RecipeDetailView: View {
    @EnvironmentObject private var store: AppDataStore
    let recipe: Recipe

    @State private var showSuccess = false
    @State private var pulse = false
    @State private var showCookMode = false
    @State private var editingIngredient: String?
    @State private var substituteDraft = ""
    @State private var statusMessage: String?

    private var personalization: RecipePersonalization? {
        store.personalization(for: recipe.id)
    }

    var body: some View {
        ZStack {
            AppBackgroundView()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    hero

                    SurfaceCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(recipe.name)
                                .font(.title.bold())
                                .foregroundStyle(Color("AppTextPrimary"))
                            HStack(spacing: 8) {
                                TagChip(text: "\(recipe.cookTimeMinutes) min", emphasized: true)
                                TagChip(text: recipe.mealType)
                                if recipe.isCustom { TagChip(text: "Mine") }
                            }
                            Text(recipe.summary)
                                .foregroundStyle(Color("AppTextSecondary"))
                            if !recipe.dietaryTags.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack {
                                        ForEach(recipe.dietaryTags, id: \.self) { tag in
                                            TagChip(text: tag)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        MetricTile(title: "Cooked", value: "\(store.timesCooked(recipeId: recipe.id))×", symbol: "flame.fill")
                        MetricTile(
                            title: "Avg time",
                            value: store.averageCookMinutes(recipeId: recipe.id) > 0
                                ? "\(store.averageCookMinutes(recipeId: recipe.id))m"
                                : "—",
                            symbol: "clock.fill"
                        )
                    }

                    if let statusMessage {
                        Text(statusMessage)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color("AppAccent"))
                    }

                    VStack(spacing: 10) {
                        AppPrimaryButton(title: "Add Ingredients to List", symbol: "cart.badge.plus") {
                            _ = store.addIngredients(from: recipe)
                            FeedbackService.success()
                            flash("Ingredients added to grocery list")
                        }
                        AppPrimaryButton(title: "Start Cook Timer", symbol: "timer", filled: false) {
                            store.startTimer(for: recipe)
                            flash("Cook timer started")
                        }
                        AppPrimaryButton(title: "Start Cook Mode", symbol: "list.number") {
                            showCookMode = true
                        }
                        NavigationLink {
                            MealDayQuickAdd(recipeId: recipe.id)
                        } label: {
                            HStack {
                                Image(systemName: "calendar.badge.plus")
                                Text("Add to Meal Plan")
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                            }
                            .font(.headline)
                            .foregroundStyle(Color("AppTextPrimary"))
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color("AppSurface"))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Color("AppAccent").opacity(0.2), lineWidth: 1)
                            )
                        }
                    }

                    SurfaceCard {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeaderView(title: "Ingredients", subtitle: "Tap swap to personalize")
                            ForEach(recipe.ingredients, id: \.self) { item in
                                ingredientRow(item)
                            }
                        }
                    }

                    SurfaceCard {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeaderView(title: "Steps", subtitle: "Notes appear in Cook Mode")
                            ForEach(Array(recipe.steps.enumerated()), id: \.offset) { index, step in
                                HStack(alignment: .top, spacing: 10) {
                                    Text("\(index + 1)")
                                        .font(.caption.bold())
                                        .foregroundStyle(Color("AppTextPrimary"))
                                        .frame(width: 24, height: 24)
                                        .background(Circle().fill(Color("AppPrimary")))
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(step)
                                            .foregroundStyle(Color("AppTextPrimary"))
                                        if let note = personalization?.stepNotes[String(index)], !note.isEmpty {
                                            Text("Note: \(note)")
                                                .font(.caption)
                                                .foregroundStyle(Color("AppAccent"))
                                        }
                                    }
                                }
                            }
                        }
                    }

                    AppPrimaryButton(
                        title: store.isFavourite(recipe.id) ? "Remove Favourite" : "Add to Favourites",
                        symbol: store.isFavourite(recipe.id) ? "heart.slash.fill" : "heart.fill",
                        filled: !pulse
                    ) {
                        let added = store.toggleFavourite(id: recipe.id)
                        if added {
                            FeedbackService.favoriteTick()
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                showSuccess = true
                                pulse = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { showSuccess = false }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { pulse = false }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 28)
            }
            .clearScrollBackground()

            SuccessCheckOverlay(isVisible: showSuccess)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color("AppBackground"), for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .fullScreenCover(isPresented: $showCookMode) {
            NavigationStack {
                CookModeView(recipe: recipe)
                    .environmentObject(store)
            }
        }
        .alert("Ingredient swap", isPresented: Binding(
            get: { editingIngredient != nil },
            set: { if !$0 { editingIngredient = nil } }
        )) {
            TextField("Substitute with", text: $substituteDraft)
            Button("Save") {
                if let editingIngredient {
                    store.updateSubstitution(recipeId: recipe.id, original: editingIngredient, substitute: substituteDraft)
                    FeedbackService.mediumTap()
                }
                editingIngredient = nil
            }
            Button("Clear", role: .destructive) {
                if let editingIngredient {
                    store.updateSubstitution(recipeId: recipe.id, original: editingIngredient, substitute: "")
                }
                editingIngredient = nil
            }
            Button("Cancel", role: .cancel) { editingIngredient = nil }
        } message: {
            Text(editingIngredient.map { "Replace \($0)" } ?? "")
        }
        .onAppear {
            store.recordRecipeView(id: recipe.id)
        }
    }

    private var hero: some View {
        ZStack(alignment: .bottomLeading) {
            AsyncImage(url: URL(string: recipe.imageURL)) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                default:
                    ZStack {
                        Color("AppSurface")
                        Image(systemName: "fork.knife")
                            .font(.largeTitle)
                            .foregroundStyle(Color("AppPrimary"))
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 230)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

            LinearGradient(
                colors: [.clear, Color("AppBackground").opacity(0.75)],
                startPoint: .top,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .frame(height: 230)
            .allowsHitTesting(false)
        }
    }

    private func ingredientRow(_ item: String) -> some View {
        let swap = personalization?.substitutions[item]
        return HStack(spacing: 10) {
            Circle()
                .fill(Color("AppAccent"))
                .frame(width: 7, height: 7)
            VStack(alignment: .leading, spacing: 2) {
                Text(item)
                    .foregroundStyle(Color("AppTextPrimary"))
                    .strikethrough(swap != nil)
                if let swap {
                    Text("→ \(swap)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color("AppAccent"))
                }
            }
            Spacer()
            IconActionButton(symbol: "arrow.left.arrow.right", tint: Color("AppPrimary")) {
                editingIngredient = item
                substituteDraft = swap ?? ""
            }
        }
        .padding(10)
        .background(Color("AppBackground").opacity(0.28))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func flash(_ message: String) {
        statusMessage = message
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { showSuccess = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            showSuccess = false
            statusMessage = nil
        }
    }
}

private struct MealDayQuickAdd: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.dismiss) private var dismiss
    let recipeId: String
    @State private var message: String?

    var body: some View {
        ZStack {
            AppBackgroundView()
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(WeekDay.allCases) { day in
                        Button {
                            if let error = store.addToMealPlan(recipeId: recipeId, dayIndex: day.rawValue) {
                                FeedbackService.warning()
                                message = error
                            } else {
                                FeedbackService.mediumTap()
                                dismiss()
                            }
                        } label: {
                            SurfaceCard {
                                HStack {
                                    Text(day.fullTitle)
                                        .font(.headline)
                                        .foregroundStyle(Color("AppTextPrimary"))
                                    Spacer()
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundStyle(Color("AppAccent"))
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(20)
            }
            .clearScrollBackground()
        }
        .navigationTitle("Choose Day")
        .alert("Meal Plan", isPresented: Binding(
            get: { message != nil },
            set: { if !$0 { message = nil } }
        )) {
            Button("OK", role: .cancel) { message = nil }
        } message: {
            Text(message ?? "")
        }
    }
}
