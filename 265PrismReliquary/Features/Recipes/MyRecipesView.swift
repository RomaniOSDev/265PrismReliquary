import SwiftUI

struct MyRecipesView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var showEditor = false
    @State private var editing: Recipe?

    var body: some View {
        ZStack {
            AppBackgroundView()
            if store.customRecipes.isEmpty {
                ScrollView {
                    EmptyStateCard(
                        symbol: "square.and.pencil",
                        title: "No personal recipes yet",
                        message: "Save your own dishes with ingredients and steps."
                    )
                    .padding(20)
                }
                .clearScrollBackground()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        SectionHeaderView(
                            title: "Yours",
                            subtitle: "\(store.customRecipes.count) personal recipes"
                        )
                        ForEach(store.customRecipes) { recipe in
                            NavigationLink {
                                RecipeDetailView(recipe: recipe)
                            } label: {
                                RecipeCardCell(
                                    recipe: recipe,
                                    isFavourite: store.isFavourite(recipe.id),
                                    timesCooked: store.timesCooked(recipeId: recipe.id)
                                )
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button {
                                    editing = recipe
                                    showEditor = true
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                Button(role: .destructive) {
                                    store.deleteCustomRecipe(id: recipe.id)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .padding(20)
                }
                .clearScrollBackground()
            }
        }
        .navigationTitle("My Recipes")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    FeedbackService.lightTap()
                    editing = nil
                    showEditor = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(Color("AppAccent"))
                        .frame(width: 44, height: 44)
                }
            }
        }
        .sheet(isPresented: $showEditor) {
            RecipeEditorView(existing: editing)
                .environmentObject(store)
        }
    }
}

struct RecipeEditorView: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.dismiss) private var dismiss
    let existing: Recipe?

    @State private var name = ""
    @State private var summary = ""
    @State private var mealType = "Dinner"
    @State private var minutes = 30
    @State private var ingredientsText = ""
    @State private var stepsText = ""
    @State private var selectedTags: Set<String> = []
    @State private var shake: CGFloat = 0
    @State private var nameError = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()
                Form {
                    Section("Basics") {
                        TextField("Name", text: $name)
                            .foregroundStyle(Color("AppTextPrimary"))
                            .modifier(ShakeEffect(animatableData: shake))
                        if nameError {
                            Text("Enter a recipe name.")
                                .font(.caption)
                                .foregroundStyle(Color.red)
                        }
                        TextField("Short description", text: $summary, axis: .vertical)
                            .foregroundStyle(Color("AppTextPrimary"))
                        Picker("Meal type", selection: $mealType) {
                            ForEach(RecipeCatalog.mealTypes, id: \.self) { Text($0).tag($0) }
                        }
                        .tint(Color("AppAccent"))
                        Stepper("Cook time: \(minutes) min", value: $minutes, in: 1...240)
                            .foregroundStyle(Color("AppTextPrimary"))
                    }
                    .listRowBackground(Color("AppSurface"))

                    Section("Dietary tags") {
                        ForEach(RecipeCatalog.dietaryOptions, id: \.self) { tag in
                            Toggle(tag, isOn: Binding(
                                get: { selectedTags.contains(tag) },
                                set: { isOn in
                                    if isOn { selectedTags.insert(tag) } else { selectedTags.remove(tag) }
                                }
                            ))
                            .tint(Color("AppAccent"))
                            .foregroundStyle(Color("AppTextPrimary"))
                        }
                    }
                    .listRowBackground(Color("AppSurface"))

                    Section("Ingredients (one per line)") {
                        TextField("Eggs\nMilk\n...", text: $ingredientsText, axis: .vertical)
                            .foregroundStyle(Color("AppTextPrimary"))
                            .lineLimit(4...10)
                    }
                    .listRowBackground(Color("AppSurface"))

                    Section("Steps (one per line)") {
                        TextField("Step one\nStep two\n...", text: $stepsText, axis: .vertical)
                            .foregroundStyle(Color("AppTextPrimary"))
                            .lineLimit(4...12)
                    }
                    .listRowBackground(Color("AppSurface"))
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(existing == nil ? "New Recipe" : "Edit Recipe")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color("AppTextSecondary"))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .foregroundStyle(Color("AppAccent"))
                }
            }
            .onAppear { preload() }
        }
        .preferredColorScheme(.dark)
    }

    private func preload() {
        guard let existing else { return }
        name = existing.name
        summary = existing.summary
        mealType = existing.mealType
        minutes = existing.cookTimeMinutes
        ingredientsText = existing.ingredients.joined(separator: "\n")
        stepsText = existing.steps.joined(separator: "\n")
        selectedTags = Set(existing.dietaryTags)
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            FeedbackService.warning()
            nameError = true
            shake += 1
            return
        }
        let ingredients = ingredientsText
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let steps = stepsText
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let recipe = Recipe(
            id: existing?.id ?? UUID().uuidString,
            name: trimmed,
            summary: summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? "Personal recipe"
                : summary.trimmingCharacters(in: .whitespacesAndNewlines),
            cookTimeMinutes: minutes,
            mealType: mealType,
            dietaryTags: Array(selectedTags).sorted(),
            ingredients: ingredients.isEmpty ? ["Ingredients to taste"] : ingredients,
            steps: steps.isEmpty ? ["Prepare and cook."] : steps,
            imageURL: existing?.imageURL ?? "",
            isCustom: true
        )
        store.saveCustomRecipe(recipe)
        FeedbackService.success()
        dismiss()
    }
}
