import Foundation
import Combine

final class Feature1ViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var selectedMealTypes: Set<String> = []
    @Published var selectedDietary: Set<String> = []
    @Published var showFilters = false
    @Published var pulseRecipeId: String?

    private let store: AppDataStore

    init(store: AppDataStore = .shared) {
        self.store = store
        selectedDietary = Set(store.preferredDietaryFilters.isEmpty ? store.dietProfile : store.preferredDietaryFilters)
    }

    var filteredRecipes: [Recipe] {
        let diet = selectedDietary.isEmpty ? Set(store.dietProfile) : selectedDietary
        let pantryKeys = store.pantryKeys()

        return store.allRecipes.filter { recipe in
            let matchesSearch = searchText.isEmpty
                || recipe.name.localizedCaseInsensitiveContains(searchText)
                || recipe.summary.localizedCaseInsensitiveContains(searchText)
            let matchesMeal = selectedMealTypes.isEmpty || selectedMealTypes.contains(recipe.mealType)
            let matchesDiet = diet.isEmpty || diet.allSatisfy { recipe.dietaryTags.contains($0) }
            let matchesPantry: Bool = {
                guard store.usePantryFilter, !pantryKeys.isEmpty else { return true }
                return RecipeLibrary.pantryMatchRatio(recipe: recipe, pantryKeys: pantryKeys) >= 0.5
            }()
            return matchesSearch && matchesMeal && matchesDiet && matchesPantry
        }
        .sorted { lhs, rhs in
            guard store.usePantryFilter else { return lhs.name < rhs.name }
            let l = RecipeLibrary.pantryMatchRatio(recipe: lhs, pantryKeys: pantryKeys)
            let r = RecipeLibrary.pantryMatchRatio(recipe: rhs, pantryKeys: pantryKeys)
            if l == r { return lhs.name < rhs.name }
            return l > r
        }
    }

    var storeUsePantry: Bool { store.usePantryFilter }

    func setPantryFilter(_ value: Bool) {
        store.usePantryFilter = value
        FeedbackService.lightTap()
    }

    func applyFilters() {
        store.preferredDietaryFilters = Array(selectedDietary).sorted()
        store.dietProfile = store.preferredDietaryFilters
        showFilters = false
    }

    func clearFilters() {
        selectedMealTypes.removeAll()
        selectedDietary.removeAll()
        store.preferredDietaryFilters = []
        store.dietProfile = []
        store.usePantryFilter = false
    }

    func toggleFavourite(id: String) {
        let added = store.toggleFavourite(id: id)
        if added {
            FeedbackService.favoriteTick()
            pulseRecipeId = id
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
                self?.pulseRecipeId = nil
            }
        } else {
            FeedbackService.lightTap()
        }
    }
}
