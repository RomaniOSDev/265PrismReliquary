import Foundation
import Combine

final class AppDataStore: ObservableObject {
    static let shared = AppDataStore()

    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private enum Keys {
        static let hasSeenOnboarding = "hasSeenOnboarding"
        static let totalSessionsCompleted = "totalSessionsCompleted"
        static let totalMinutesUsed = "totalMinutesUsed"
        static let streakDays = "streakDays"
        static let lastActivityDate = "lastActivityDate"
        static let achievementsUnlocked = "achievementsUnlocked"
        static let favouriteRecipes = "favouriteRecipes"
        static let lastVisitedRecipeId = "lastVisitedRecipeId"
        static let preferredDietaryFilters = "preferredDietaryFilters"
        static let viewedRecipeIds = "viewedRecipeIds"
        static let favouritesAdded = "favouritesAdded"
        static let listsCompleted = "listsCompleted"
        static let groceryItems = "groceryItems"
        static let defaultCategories = "defaultCategories"
        static let cookTimers = "cookTimers"
        static let lastUsedTimerName = "lastUsedTimerName"
        static let defaultTimerDurationMin = "defaultTimerDurationMin"
        static let collapsedCategories = "collapsedCategories"
        static let mealPlan = "mealPlan"
        static let customRecipes = "customRecipes"
        static let recipePersonalizations = "recipePersonalizations"
        static let cookingHistory = "cookingHistory"
        static let pantryItems = "pantryItems"
        static let weeklyStaples = "weeklyStaples"
        static let usePantryFilter = "usePantryFilter"
        static let dietProfile = "dietProfile"
    }

    static let defaultStaples = [
        "Eggs", "Milk", "Bread", "Butter", "Olive oil", "Salt", "Black pepper", "Rice", "Pasta", "Garlic"
    ]

    @Published var hasSeenOnboarding: Bool { didSet { defaults.set(hasSeenOnboarding, forKey: Keys.hasSeenOnboarding) } }
    @Published var totalSessionsCompleted: Int { didSet { defaults.set(totalSessionsCompleted, forKey: Keys.totalSessionsCompleted) } }
    @Published var totalMinutesUsed: Int { didSet { defaults.set(totalMinutesUsed, forKey: Keys.totalMinutesUsed) } }
    @Published var streakDays: Int { didSet { defaults.set(streakDays, forKey: Keys.streakDays) } }
    @Published var lastActivityDate: Date? {
        didSet {
            if let lastActivityDate {
                defaults.set(lastActivityDate.timeIntervalSince1970, forKey: Keys.lastActivityDate)
            } else {
                defaults.removeObject(forKey: Keys.lastActivityDate)
            }
        }
    }
    @Published var achievementsUnlocked: [String: Date] { didSet { saveCodable(achievementsUnlocked, key: Keys.achievementsUnlocked) } }
    @Published var favouriteRecipes: [String] { didSet { defaults.set(favouriteRecipes, forKey: Keys.favouriteRecipes) } }
    @Published var lastVisitedRecipeId: String { didSet { defaults.set(lastVisitedRecipeId, forKey: Keys.lastVisitedRecipeId) } }
    @Published var preferredDietaryFilters: [String] { didSet { defaults.set(preferredDietaryFilters, forKey: Keys.preferredDietaryFilters) } }
    @Published var viewedRecipeIds: [String] { didSet { defaults.set(viewedRecipeIds, forKey: Keys.viewedRecipeIds) } }
    @Published var favouritesAdded: Int { didSet { defaults.set(favouritesAdded, forKey: Keys.favouritesAdded) } }
    @Published var listsCompleted: Int { didSet { defaults.set(listsCompleted, forKey: Keys.listsCompleted) } }
    @Published var groceryItems: [GroceryItem] { didSet { saveCodable(groceryItems, key: Keys.groceryItems) } }
    @Published var defaultCategories: [String] { didSet { defaults.set(defaultCategories, forKey: Keys.defaultCategories) } }
    @Published var cookTimers: [CookTimerItem] { didSet { saveCodable(cookTimers, key: Keys.cookTimers) } }
    @Published var lastUsedTimerName: String { didSet { defaults.set(lastUsedTimerName, forKey: Keys.lastUsedTimerName) } }
    @Published var defaultTimerDurationMin: Int { didSet { defaults.set(defaultTimerDurationMin, forKey: Keys.defaultTimerDurationMin) } }
    @Published var collapsedCategories: [String] { didSet { defaults.set(collapsedCategories, forKey: Keys.collapsedCategories) } }
    @Published var mealPlan: [MealPlanEntry] { didSet { saveCodable(mealPlan, key: Keys.mealPlan) } }
    @Published var customRecipes: [Recipe] { didSet { saveCodable(customRecipes, key: Keys.customRecipes) } }
    @Published var recipePersonalizations: [RecipePersonalization] { didSet { saveCodable(recipePersonalizations, key: Keys.recipePersonalizations) } }
    @Published var cookingHistory: [CookingHistoryEntry] { didSet { saveCodable(cookingHistory, key: Keys.cookingHistory) } }
    @Published var pantryItems: [PantryItem] { didSet { saveCodable(pantryItems, key: Keys.pantryItems) } }
    @Published var weeklyStaples: [String] { didSet { defaults.set(weeklyStaples, forKey: Keys.weeklyStaples) } }
    @Published var usePantryFilter: Bool { didSet { defaults.set(usePantryFilter, forKey: Keys.usePantryFilter) } }
    @Published var dietProfile: [String] { didSet { defaults.set(dietProfile, forKey: Keys.dietProfile) } }
    @Published var pendingAchievementIds: [String] = []
    @Published var preferredKitchenSegment: Int = 0

    var recipesViewed: Int { viewedRecipeIds.count }
    var allRecipes: [Recipe] { RecipeLibrary.allRecipes(custom: customRecipes) }
    var mealPlanCount: Int { mealPlan.count }

    private init() {
        let decoder = JSONDecoder()
        func loadCodableLocal<T: Decodable>(_ type: T.Type, key: String) -> T? {
            guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
            return try? decoder.decode(type, from: data)
        }

        hasSeenOnboarding = defaults.bool(forKey: Keys.hasSeenOnboarding)
        totalSessionsCompleted = defaults.integer(forKey: Keys.totalSessionsCompleted)
        totalMinutesUsed = defaults.integer(forKey: Keys.totalMinutesUsed)
        streakDays = defaults.integer(forKey: Keys.streakDays)
        let activityValue = defaults.double(forKey: Keys.lastActivityDate)
        lastActivityDate = activityValue > 0 ? Date(timeIntervalSince1970: activityValue) : nil
        achievementsUnlocked = loadCodableLocal([String: Date].self, key: Keys.achievementsUnlocked) ?? [:]
        favouriteRecipes = defaults.stringArray(forKey: Keys.favouriteRecipes) ?? []
        lastVisitedRecipeId = defaults.string(forKey: Keys.lastVisitedRecipeId) ?? ""
        preferredDietaryFilters = defaults.stringArray(forKey: Keys.preferredDietaryFilters) ?? []
        viewedRecipeIds = defaults.stringArray(forKey: Keys.viewedRecipeIds) ?? []
        favouritesAdded = defaults.integer(forKey: Keys.favouritesAdded)
        listsCompleted = defaults.integer(forKey: Keys.listsCompleted)
        groceryItems = loadCodableLocal([GroceryItem].self, key: Keys.groceryItems) ?? []
        var categories = defaults.stringArray(forKey: Keys.defaultCategories) ?? ["Produce", "Dairy", "Bakery", "Other"]
        if !categories.contains("Other") { categories.append("Other") }
        defaultCategories = categories
        cookTimers = loadCodableLocal([CookTimerItem].self, key: Keys.cookTimers) ?? []
        lastUsedTimerName = defaults.string(forKey: Keys.lastUsedTimerName) ?? ""
        let duration = defaults.integer(forKey: Keys.defaultTimerDurationMin)
        defaultTimerDurationMin = duration > 0 ? duration : 30
        collapsedCategories = defaults.stringArray(forKey: Keys.collapsedCategories) ?? []
        mealPlan = loadCodableLocal([MealPlanEntry].self, key: Keys.mealPlan) ?? []
        customRecipes = loadCodableLocal([Recipe].self, key: Keys.customRecipes) ?? []
        recipePersonalizations = loadCodableLocal([RecipePersonalization].self, key: Keys.recipePersonalizations) ?? []
        cookingHistory = loadCodableLocal([CookingHistoryEntry].self, key: Keys.cookingHistory) ?? []
        pantryItems = loadCodableLocal([PantryItem].self, key: Keys.pantryItems) ?? []
        weeklyStaples = defaults.stringArray(forKey: Keys.weeklyStaples) ?? Self.defaultStaples
        usePantryFilter = defaults.bool(forKey: Keys.usePantryFilter)
        dietProfile = defaults.stringArray(forKey: Keys.dietProfile) ?? []
        evaluateAchievements()
    }

    func recipe(by id: String) -> Recipe? {
        RecipeLibrary.recipe(id: id, custom: customRecipes)
    }

    func markOnboardingSeen() {
        hasSeenOnboarding = true
        recordActivity()
    }

    func recordRecipeView(id: String) {
        lastVisitedRecipeId = id
        if !viewedRecipeIds.contains(id) {
            viewedRecipeIds.append(id)
        }
        recordActivity()
        evaluateAchievements()
    }

    func toggleFavourite(id: String) -> Bool {
        if let index = favouriteRecipes.firstIndex(of: id) {
            favouriteRecipes.remove(at: index)
            recordActivity()
            return false
        }
        favouriteRecipes.append(id)
        favouritesAdded += 1
        recordActivity()
        evaluateAchievements()
        return true
    }

    func isFavourite(_ id: String) -> Bool {
        favouriteRecipes.contains(id)
    }

    // MARK: - Grocery

    func addGroceryItem(name: String, category: String, sourceRecipeId: String? = nil) {
        let parsed = IngredientSmart.parse(name)
        upsertGrocery(
            displayName: parsed.name,
            quantity: parsed.quantity,
            unit: parsed.unit,
            category: category.isEmpty ? IngredientSmart.guessCategory(for: parsed.name) : category,
            sourceRecipeId: sourceRecipeId
        )
        recordActivity()
    }

    @discardableResult
    func addIngredients(from recipe: Recipe) -> Int {
        let personalization = personalization(for: recipe.id)
        var count = 0
        for ingredient in recipe.ingredients {
            let substituted = personalization?.substitutions[ingredient] ?? ingredient
            addGroceryItem(
                name: substituted,
                category: IngredientSmart.guessCategory(for: substituted),
                sourceRecipeId: recipe.id
            )
            count += 1
        }
        mergeDuplicateGroceries()
        recordActivity()
        return count
    }

    func mergeDuplicateGroceries() {
        var buckets: [String: GroceryItem] = [:]
        var orderCounter = 0
        for item in groceryItems.sorted(by: { $0.sortOrder < $1.sortOrder }) {
            let key = item.normalizedKey.isEmpty ? IngredientSmart.normalize(item.name) : item.normalizedKey
            if var existing = buckets[key] {
                existing.quantityLabel = IngredientSmart.mergeQuantity(existing: existing.quantityLabel, incoming: item.quantityLabel)
                if existing.unitLabel.isEmpty { existing.unitLabel = item.unitLabel }
                existing.sourceRecipeIds = Array(Set(existing.sourceRecipeIds + item.sourceRecipeIds))
                existing.completed = existing.completed && item.completed
                existing.name = IngredientSmart.displayLine(quantity: "", unit: "", name: existing.name.isEmpty ? item.name : existing.name)
                let baseName = IngredientSmart.parse(existing.name).name.isEmpty ? item.name : IngredientSmart.parse(existing.name).name
                existing.name = baseName
                buckets[key] = existing
            } else {
                var copy = item
                copy.normalizedKey = key
                copy.sortOrder = orderCounter
                buckets[key] = copy
                orderCounter += 1
            }
        }
        groceryItems = buckets.values.sorted { $0.sortOrder < $1.sortOrder }
        recordActivity()
    }

    func addWeeklyStaples() {
        for staple in weeklyStaples {
            addGroceryItem(name: staple, category: IngredientSmart.guessCategory(for: staple))
        }
        mergeDuplicateGroceries()
        FeedbackService.mediumTap()
        recordActivity()
    }

    func groceryShareText() -> String {
        var lines = ["Grocery List"]
        for category in categoriesInUse() {
            let items = groceryItems.filter { $0.category == category }.sorted { $0.sortOrder < $1.sortOrder }
            guard !items.isEmpty else { continue }
            lines.append("")
            lines.append(category.uppercased())
            for item in items {
                let mark = item.completed ? "[x]" : "[ ]"
                lines.append("\(mark) \(item.displayName)")
            }
        }
        return lines.joined(separator: "\n")
    }

    func categoriesInUse() -> [String] {
        var set = defaultCategories
        for item in groceryItems where !set.contains(item.category) {
            set.append(item.category)
        }
        return set.filter { category in groceryItems.contains { $0.category == category } }
    }

    func toggleGroceryCompletion(id: String) {
        guard let index = groceryItems.firstIndex(where: { $0.id == id }) else { return }
        groceryItems[index].completed.toggle()
        recordActivity()
        if groceryItems[index].completed {
            totalSessionsCompleted += 1
        }
        evaluateAchievements()
    }

    func deleteGroceryItem(id: String) {
        groceryItems.removeAll { $0.id == id }
        recordActivity()
    }

    func moveGroceryItems(category: String, from source: IndexSet, to destination: Int) {
        var items = groceryItems
            .filter { $0.category == category }
            .sorted { $0.sortOrder < $1.sortOrder }
        var moved: [GroceryItem] = []
        for index in source.sorted().reversed() where items.indices.contains(index) {
            moved.insert(items.remove(at: index), at: 0)
        }
        var dest = destination
        for index in source where index < destination { dest -= 1 }
        dest = max(0, min(dest, items.count))
        items.insert(contentsOf: moved, at: dest)
        for (index, item) in items.enumerated() {
            if let globalIndex = groceryItems.firstIndex(where: { $0.id == item.id }) {
                groceryItems[globalIndex].sortOrder = index
            }
        }
        recordActivity()
    }

    func completeGroceryList() {
        guard !groceryItems.isEmpty else { return }
        for index in groceryItems.indices {
            groceryItems[index].completed = true
        }
        listsCompleted += 1
        totalSessionsCompleted += 1
        recordActivity()
        evaluateAchievements()
    }

    func toggleCategoryCollapsed(_ category: String) {
        if let index = collapsedCategories.firstIndex(of: category) {
            collapsedCategories.remove(at: index)
        } else {
            collapsedCategories.append(category)
        }
    }

    private func upsertGrocery(
        displayName: String,
        quantity: String,
        unit: String,
        category: String,
        sourceRecipeId: String?
    ) {
        let key = IngredientSmart.normalize(displayName)
        if let index = groceryItems.firstIndex(where: { $0.normalizedKey == key && !$0.completed }) {
            groceryItems[index].quantityLabel = IngredientSmart.mergeQuantity(
                existing: groceryItems[index].quantityLabel,
                incoming: quantity
            )
            if groceryItems[index].unitLabel.isEmpty {
                groceryItems[index].unitLabel = unit
            }
            if let sourceRecipeId, !groceryItems[index].sourceRecipeIds.contains(sourceRecipeId) {
                groceryItems[index].sourceRecipeIds.append(sourceRecipeId)
            }
            return
        }
        let order = groceryItems.filter { $0.category == category }.count
        var sources: [String] = []
        if let sourceRecipeId { sources = [sourceRecipeId] }
        groceryItems.append(
            GroceryItem(
                id: UUID().uuidString,
                name: displayName,
                category: category,
                completed: false,
                sortOrder: order,
                normalizedKey: key,
                quantityLabel: quantity,
                unitLabel: unit,
                sourceRecipeIds: sources
            )
        )
        if !defaultCategories.contains(category) {
            defaultCategories.append(category)
        }
    }

    // MARK: - Timers

    func addTimer(name: String, minutes: Int) {
        let seconds = max(1, minutes) * 60
        let timer = CookTimerItem(
            id: UUID().uuidString,
            name: name,
            durationSeconds: seconds,
            remainingSeconds: seconds,
            startDate: Date(),
            isRunning: true,
            isCompleted: false
        )
        cookTimers.insert(timer, at: 0)
        lastUsedTimerName = name
        defaultTimerDurationMin = minutes
        recordActivity()
    }

    func startTimer(for recipe: Recipe) {
        addTimer(name: recipe.name, minutes: max(1, recipe.cookTimeMinutes))
        FeedbackService.completeTick()
    }

    func pauseTimer(id: String) {
        guard let index = cookTimers.firstIndex(where: { $0.id == id }) else { return }
        var timer = cookTimers[index]
        if timer.isRunning {
            timer.remainingSeconds = timer.liveRemaining(at: Date())
            timer.isRunning = false
            timer.startDate = nil
        }
        cookTimers[index] = timer
        recordActivity()
    }

    func resumeTimer(id: String) {
        guard let index = cookTimers.firstIndex(where: { $0.id == id }) else { return }
        var timer = cookTimers[index]
        guard !timer.isCompleted, timer.remainingSeconds > 0 else { return }
        timer.isRunning = true
        timer.startDate = Date()
        cookTimers[index] = timer
        recordActivity()
    }

    func deleteTimer(id: String) {
        cookTimers.removeAll { $0.id == id }
        recordActivity()
    }

    func updateTimer(id: String, name: String, minutes: Int) {
        guard let index = cookTimers.firstIndex(where: { $0.id == id }) else { return }
        let seconds = max(1, minutes) * 60
        cookTimers[index].name = name
        cookTimers[index].durationSeconds = seconds
        cookTimers[index].remainingSeconds = seconds
        cookTimers[index].startDate = Date()
        cookTimers[index].isRunning = true
        cookTimers[index].isCompleted = false
        lastUsedTimerName = name
        defaultTimerDurationMin = minutes
        recordActivity()
    }

    func syncTimers(at date: Date, isActive: Bool) {
        guard isActive else {
            for index in cookTimers.indices where cookTimers[index].isRunning {
                cookTimers[index].remainingSeconds = cookTimers[index].liveRemaining(at: date)
                cookTimers[index].startDate = date
            }
            return
        }
        var didComplete = false
        for index in cookTimers.indices {
            guard cookTimers[index].isRunning else { continue }
            let remaining = cookTimers[index].liveRemaining(at: date)
            if remaining <= 0 {
                cookTimers[index].remainingSeconds = 0
                cookTimers[index].isRunning = false
                cookTimers[index].isCompleted = true
                cookTimers[index].startDate = nil
                totalMinutesUsed += max(1, cookTimers[index].durationSeconds / 60)
                totalSessionsCompleted += 1
                didComplete = true
            }
        }
        if didComplete {
            recordActivity()
            evaluateAchievements()
        }
    }

    // MARK: - Meal Plan

    func addToMealPlan(recipeId: String, dayIndex: Int) -> String? {
        if mealPlan.count >= 7 {
            return "Weekly plan supports up to 7 dishes."
        }
        if mealPlan.contains(where: { $0.dayIndex == dayIndex && $0.recipeId == recipeId }) {
            return "This dish is already planned for that day."
        }
        mealPlan.append(
            MealPlanEntry(
                id: UUID().uuidString,
                dayIndex: dayIndex,
                recipeId: recipeId,
                isCooked: false,
                cookedAt: nil
            )
        )
        recordActivity()
        return nil
    }

    func removeFromMealPlan(id: String) {
        mealPlan.removeAll { $0.id == id }
        recordActivity()
    }

    func markMealCooked(id: String) {
        guard let index = mealPlan.firstIndex(where: { $0.id == id }) else { return }
        mealPlan[index].isCooked = true
        mealPlan[index].cookedAt = Date()
        if let recipe = recipe(by: mealPlan[index].recipeId) {
            logCooking(recipe: recipe, durationMinutes: recipe.cookTimeMinutes)
        } else {
            totalSessionsCompleted += 1
            recordActivity()
            evaluateAchievements()
        }
        FeedbackService.success()
    }

    func buildGroceryFromMealPlan() {
        for entry in mealPlan {
            if let recipe = recipe(by: entry.recipeId) {
                addIngredients(from: recipe)
            }
        }
        mergeDuplicateGroceries()
        recordActivity()
    }

    // MARK: - Custom recipes & notes

    func saveCustomRecipe(_ recipe: Recipe) {
        let item = Recipe(
            id: recipe.id.isEmpty ? UUID().uuidString : recipe.id,
            name: recipe.name,
            summary: recipe.summary,
            cookTimeMinutes: recipe.cookTimeMinutes,
            mealType: recipe.mealType,
            dietaryTags: recipe.dietaryTags,
            ingredients: recipe.ingredients,
            steps: recipe.steps,
            imageURL: recipe.imageURL,
            isCustom: true
        )
        if let index = customRecipes.firstIndex(where: { $0.id == item.id }) {
            customRecipes[index] = item
        } else {
            customRecipes.append(item)
        }
        recordActivity()
    }

    func deleteCustomRecipe(id: String) {
        customRecipes.removeAll { $0.id == id }
        recordActivity()
    }

    func personalization(for recipeId: String) -> RecipePersonalization? {
        recipePersonalizations.first { $0.recipeId == recipeId }
    }

    func updateStepNote(recipeId: String, stepIndex: Int, note: String) {
        var entry = personalization(for: recipeId) ?? RecipePersonalization(recipeId: recipeId, stepNotes: [:], substitutions: [:])
        let key = String(stepIndex)
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            entry.stepNotes.removeValue(forKey: key)
        } else {
            entry.stepNotes[key] = trimmed
        }
        upsertPersonalization(entry)
    }

    func updateSubstitution(recipeId: String, original: String, substitute: String) {
        var entry = personalization(for: recipeId) ?? RecipePersonalization(recipeId: recipeId, stepNotes: [:], substitutions: [:])
        let trimmed = substitute.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            entry.substitutions.removeValue(forKey: original)
        } else {
            entry.substitutions[original] = trimmed
        }
        upsertPersonalization(entry)
    }

    private func upsertPersonalization(_ entry: RecipePersonalization) {
        if let index = recipePersonalizations.firstIndex(where: { $0.recipeId == entry.recipeId }) {
            recipePersonalizations[index] = entry
        } else {
            recipePersonalizations.append(entry)
        }
        recordActivity()
    }

    // MARK: - Cooking history

    func logCooking(recipe: Recipe, durationMinutes: Int) {
        cookingHistory.insert(
            CookingHistoryEntry(
                id: UUID().uuidString,
                recipeId: recipe.id,
                recipeName: recipe.name,
                cookedAt: Date(),
                durationMinutes: max(1, durationMinutes)
            ),
            at: 0
        )
        if cookingHistory.count > 200 {
            cookingHistory = Array(cookingHistory.prefix(200))
        }
        totalMinutesUsed += max(1, durationMinutes)
        totalSessionsCompleted += 1
        recordActivity()
        evaluateAchievements()
    }

    func finishCookMode(recipe: Recipe) {
        logCooking(recipe: recipe, durationMinutes: recipe.cookTimeMinutes)
        FeedbackService.success()
    }

    func timesCooked(recipeId: String) -> Int {
        cookingHistory.filter { $0.recipeId == recipeId }.count
    }

    func averageCookMinutes(recipeId: String) -> Int {
        let entries = cookingHistory.filter { $0.recipeId == recipeId }
        guard !entries.isEmpty else { return 0 }
        return entries.map(\.durationMinutes).reduce(0, +) / entries.count
    }

    func topCookedRecipes(limit: Int = 5) -> [(name: String, count: Int)] {
        var counts: [String: (name: String, count: Int)] = [:]
        for entry in cookingHistory {
            let current = counts[entry.recipeId] ?? (entry.recipeName, 0)
            counts[entry.recipeId] = (entry.recipeName, current.count + 1)
        }
        return counts.values.sorted { $0.count > $1.count }.prefix(limit).map { ($0.name, $0.count) }
    }

    func frequentGroceryNames(limit: Int = 5) -> [(name: String, count: Int)] {
        var counts: [String: Int] = [:]
        for item in groceryItems {
            counts[item.name, default: 0] += 1 + item.sourceRecipeIds.count
        }
        return counts.sorted { $0.value > $1.value }.prefix(limit).map { ($0.key, $0.value) }
    }

    // MARK: - Pantry & diet

    func addPantryItem(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let key = IngredientSmart.normalize(trimmed)
        guard !pantryItems.contains(where: { $0.normalizedKey == key }) else { return }
        pantryItems.append(PantryItem(id: UUID().uuidString, name: trimmed, normalizedKey: key))
        recordActivity()
    }

    func removePantryItem(id: String) {
        pantryItems.removeAll { $0.id == id }
        recordActivity()
    }

    func pantryKeys() -> Set<String> {
        Set(pantryItems.map(\.normalizedKey))
    }

    // MARK: - Activity / achievements / reset

    func recordActivity() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        if let last = lastActivityDate {
            let lastDay = calendar.startOfDay(for: last)
            let diff = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0
            if diff == 1 {
                streakDays += 1
            } else if diff > 1 {
                streakDays = 1
            }
        } else {
            streakDays = max(streakDays, 1)
        }
        lastActivityDate = Date()
        evaluateAchievements()
    }

    func evaluateAchievements() {
        var newlyUnlocked: [String] = []
        for achievement in AchievementCatalog.all {
            let unlocked = AchievementCatalog.isUnlocked(achievement.id, store: self)
            if unlocked && achievementsUnlocked[achievement.id] == nil {
                achievementsUnlocked[achievement.id] = Date()
                newlyUnlocked.append(achievement.id)
            }
        }
        if !newlyUnlocked.isEmpty {
            pendingAchievementIds.append(contentsOf: newlyUnlocked)
            NotificationCenter.default.post(name: .achievementUnlocked, object: newlyUnlocked)
        }
    }

    func consumeNextAchievementBanner() -> AchievementDefinition? {
        guard !pendingAchievementIds.isEmpty else { return nil }
        let id = pendingAchievementIds.removeFirst()
        return AchievementCatalog.all.first { $0.id == id }
    }

    func resetAllData() {
        let domain = Bundle.main.bundleIdentifier ?? ""
        defaults.removePersistentDomain(forName: domain)
        defaults.synchronize()

        hasSeenOnboarding = false
        totalSessionsCompleted = 0
        totalMinutesUsed = 0
        streakDays = 0
        lastActivityDate = nil
        achievementsUnlocked = [:]
        favouriteRecipes = []
        lastVisitedRecipeId = ""
        preferredDietaryFilters = []
        viewedRecipeIds = []
        favouritesAdded = 0
        listsCompleted = 0
        groceryItems = []
        defaultCategories = ["Produce", "Dairy", "Bakery", "Other"]
        cookTimers = []
        lastUsedTimerName = ""
        defaultTimerDurationMin = 30
        collapsedCategories = []
        mealPlan = []
        customRecipes = []
        recipePersonalizations = []
        cookingHistory = []
        pantryItems = []
        weeklyStaples = Self.defaultStaples
        usePantryFilter = false
        dietProfile = []
        pendingAchievementIds = []

        NotificationCenter.default.post(name: .dataReset, object: nil)
        objectWillChange.send()
    }

    private func saveCodable<T: Encodable>(_ value: T, key: String) {
        guard let data = try? encoder.encode(value) else { return }
        defaults.set(data, forKey: key)
    }
}
