import SwiftUI

struct Feature1View: View {
    @EnvironmentObject private var store: AppDataStore
    @StateObject private var viewModel = Feature1ViewModel()
    @Binding var tabBarHiddenCount: Int

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()

                VStack(spacing: 0) {
                    searchField
                        .padding(.horizontal, 20)
                        .padding(.top, 10)

                    quickActions
                        .padding(.horizontal, 20)
                        .padding(.top, 12)

                    if viewModel.filteredRecipes.isEmpty {
                        ScrollView {
                            EmptyStateCard(
                                symbol: "book.fill",
                                title: "Start exploring delicious recipes!",
                                message: "No recipes yet! Start by adding your first favourite."
                            )
                            .padding(.horizontal, 20)
                            .padding(.top, 28)
                            .tabBarClearance(120)
                        }
                        .clearScrollBackground()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                SectionHeaderView(
                                    title: "Browse",
                                    subtitle: "\(viewModel.filteredRecipes.count) recipes · tap a card for cook flow"
                                )
                                .padding(.horizontal, 4)

                                ForEach(viewModel.filteredRecipes) { recipe in
                                    NavigationLink {
                                        RecipeDetailView(recipe: recipe)
                                            .onAppear { tabBarHiddenCount += 1 }
                                            .onDisappear { tabBarHiddenCount = max(0, tabBarHiddenCount - 1) }
                                    } label: {
                                        RecipeCardCell(
                                            recipe: recipe,
                                            isFavourite: store.isFavourite(recipe.id),
                                            isPulsing: viewModel.pulseRecipeId == recipe.id,
                                            pantryMatch: store.usePantryFilter
                                                ? RecipeLibrary.pantryMatchRatio(recipe: recipe, pantryKeys: store.pantryKeys())
                                                : nil,
                                            timesCooked: store.timesCooked(recipeId: recipe.id)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                    .contextMenu {
                                        Button {
                                            viewModel.toggleFavourite(id: recipe.id)
                                        } label: {
                                            Label(
                                                store.isFavourite(recipe.id) ? "Remove Favourite" : "Add Favourite",
                                                systemImage: store.isFavourite(recipe.id) ? "heart.slash" : "heart.fill"
                                            )
                                        }
                                        Button {
                                            _ = store.addIngredients(from: recipe)
                                            FeedbackService.success()
                                        } label: {
                                            Label("Add Ingredients", systemImage: "cart.badge.plus")
                                        }
                                        Button {
                                            store.startTimer(for: recipe)
                                        } label: {
                                            Label("Start Timer", systemImage: "timer")
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 14)
                            .tabBarClearance(130)
                        }
                        .clearScrollBackground()
                    }

                    AppPrimaryButton(title: "Filter Recipes", symbol: "line.3.horizontal.decrease.circle") {
                        viewModel.showFilters = true
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("Recipes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color("AppBackground"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink {
                        PantryDietView()
                            .onAppear { tabBarHiddenCount += 1 }
                            .onDisappear { tabBarHiddenCount = max(0, tabBarHiddenCount - 1) }
                    } label: {
                        Image(systemName: "refrigerator")
                            .foregroundStyle(Color("AppAccent"))
                            .frame(width: 44, height: 44)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        MyRecipesView()
                            .onAppear { tabBarHiddenCount += 1 }
                            .onDisappear { tabBarHiddenCount = max(0, tabBarHiddenCount - 1) }
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .foregroundStyle(Color("AppAccent"))
                            .frame(width: 44, height: 44)
                    }
                }
            }
            .sheet(isPresented: $viewModel.showFilters) {
                FilterRecipesSheet(viewModel: viewModel)
            }
        }
        .transparentScreenChrome()
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color("AppTextSecondary"))
            TextField("Search recipes, meals, tags", text: $viewModel.searchText)
                .foregroundStyle(Color("AppTextPrimary"))
                .tint(Color("AppAccent"))
            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.searchText = ""
                    FeedbackService.lightTap()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color("AppTextSecondary"))
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color("AppSurface"), Color("AppPrimary").opacity(0.22)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color("AppAccent").opacity(0.28), lineWidth: 1)
                )
        )
        .softShadow(.raised)
    }

    private var quickActions: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                TagChip(text: store.usePantryFilter ? "Pantry on" : "Pantry off", emphasized: store.usePantryFilter)
                if !store.dietProfile.isEmpty {
                    TagChip(text: "Diet \(store.dietProfile.count)", emphasized: true)
                }
                TagChip(text: "\(store.favouriteRecipes.count) favourites")
                TagChip(text: "\(store.customRecipes.count) mine")
            }
        }
    }
}

struct FilterRecipesSheet: View {
    @ObservedObject var viewModel: Feature1ViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()
                ScrollView {
                    VStack(spacing: 16) {
                        SurfaceCard {
                            VStack(alignment: .leading, spacing: 12) {
                                SectionHeaderView(title: "Meal type", subtitle: "Pick one or more")
                                ForEach(RecipeCatalog.mealTypes, id: \.self) { type in
                                    Toggle(isOn: Binding(
                                        get: { viewModel.selectedMealTypes.contains(type) },
                                        set: { isOn in
                                            FeedbackService.lightTap()
                                            if isOn { viewModel.selectedMealTypes.insert(type) }
                                            else { viewModel.selectedMealTypes.remove(type) }
                                        }
                                    )) {
                                        Text(type).foregroundStyle(Color("AppTextPrimary"))
                                    }
                                    .tint(Color("AppAccent"))
                                }
                            }
                        }

                        SurfaceCard {
                            VStack(alignment: .leading, spacing: 12) {
                                SectionHeaderView(title: "Dietary", subtitle: "Hard preferences")
                                ForEach(RecipeCatalog.dietaryOptions, id: \.self) { tag in
                                    Toggle(isOn: Binding(
                                        get: { viewModel.selectedDietary.contains(tag) },
                                        set: { isOn in
                                            FeedbackService.lightTap()
                                            if isOn { viewModel.selectedDietary.insert(tag) }
                                            else { viewModel.selectedDietary.remove(tag) }
                                        }
                                    )) {
                                        Text(tag).foregroundStyle(Color("AppTextPrimary"))
                                    }
                                    .tint(Color("AppAccent"))
                                }
                            }
                        }

                        Toggle(isOn: Binding(
                            get: { viewModel.storeUsePantry },
                            set: { viewModel.setPantryFilter($0) }
                        )) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Use pantry filter").foregroundStyle(Color("AppTextPrimary"))
                                Text("Only show recipes you can mostly cook").font(.caption).foregroundStyle(Color("AppTextSecondary"))
                            }
                        }
                        .tint(Color("AppAccent"))
                        .padding(14)
                        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color("AppSurface")))
                    }
                    .padding(20)
                }
                .clearScrollBackground()
            }
            .navigationTitle("Filter Recipes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Clear") {
                        FeedbackService.lightTap()
                        viewModel.clearFilters()
                    }
                    .foregroundStyle(Color("AppTextSecondary"))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        FeedbackService.mediumTap()
                        viewModel.applyFilters()
                        dismiss()
                    }
                    .foregroundStyle(Color("AppAccent"))
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
