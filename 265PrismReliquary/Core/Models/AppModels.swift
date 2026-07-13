import Foundation

struct Recipe: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let summary: String
    let cookTimeMinutes: Int
    let mealType: String
    let dietaryTags: [String]
    let ingredients: [String]
    let steps: [String]
    let imageURL: String
    var isCustom: Bool

    init(
        id: String,
        name: String,
        summary: String,
        cookTimeMinutes: Int,
        mealType: String,
        dietaryTags: [String],
        ingredients: [String],
        steps: [String],
        imageURL: String,
        isCustom: Bool = false
    ) {
        self.id = id
        self.name = name
        self.summary = summary
        self.cookTimeMinutes = cookTimeMinutes
        self.mealType = mealType
        self.dietaryTags = dietaryTags
        self.ingredients = ingredients
        self.steps = steps
        self.imageURL = imageURL
        self.isCustom = isCustom
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        summary = try c.decode(String.self, forKey: .summary)
        cookTimeMinutes = try c.decode(Int.self, forKey: .cookTimeMinutes)
        mealType = try c.decode(String.self, forKey: .mealType)
        dietaryTags = try c.decode([String].self, forKey: .dietaryTags)
        ingredients = try c.decode([String].self, forKey: .ingredients)
        steps = try c.decode([String].self, forKey: .steps)
        imageURL = try c.decode(String.self, forKey: .imageURL)
        isCustom = try c.decodeIfPresent(Bool.self, forKey: .isCustom) ?? false
    }
}

struct GroceryItem: Identifiable, Hashable, Codable {
    var id: String
    var name: String
    var category: String
    var completed: Bool
    var sortOrder: Int
    var normalizedKey: String
    var quantityLabel: String
    var unitLabel: String
    var sourceRecipeIds: [String]

    init(
        id: String,
        name: String,
        category: String,
        completed: Bool,
        sortOrder: Int,
        normalizedKey: String = "",
        quantityLabel: String = "",
        unitLabel: String = "",
        sourceRecipeIds: [String] = []
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.completed = completed
        self.sortOrder = sortOrder
        self.normalizedKey = normalizedKey.isEmpty ? IngredientSmart.normalize(name) : normalizedKey
        self.quantityLabel = quantityLabel
        self.unitLabel = unitLabel
        self.sourceRecipeIds = sourceRecipeIds
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        category = try c.decode(String.self, forKey: .category)
        completed = try c.decode(Bool.self, forKey: .completed)
        sortOrder = try c.decode(Int.self, forKey: .sortOrder)
        normalizedKey = try c.decodeIfPresent(String.self, forKey: .normalizedKey) ?? IngredientSmart.normalize(name)
        quantityLabel = try c.decodeIfPresent(String.self, forKey: .quantityLabel) ?? ""
        unitLabel = try c.decodeIfPresent(String.self, forKey: .unitLabel) ?? ""
        sourceRecipeIds = try c.decodeIfPresent([String].self, forKey: .sourceRecipeIds) ?? []
    }

    var displayName: String {
        let qty = [quantityLabel, unitLabel].filter { !$0.isEmpty }.joined(separator: " ")
        if qty.isEmpty { return name }
        return "\(qty) \(name)"
    }
}

struct CookTimerItem: Identifiable, Hashable, Codable {
    var id: String
    var name: String
    var durationSeconds: Int
    var remainingSeconds: Int
    var startDate: Date?
    var isRunning: Bool
    var isCompleted: Bool

    func liveRemaining(at date: Date) -> Int {
        guard isRunning, let startDate else { return remainingSeconds }
        let elapsed = Int(date.timeIntervalSince(startDate))
        return max(0, remainingSeconds - elapsed)
    }
}

struct MealPlanEntry: Identifiable, Hashable, Codable {
    var id: String
    var dayIndex: Int
    var recipeId: String
    var isCooked: Bool
    var cookedAt: Date?
}

struct RecipePersonalization: Identifiable, Hashable, Codable {
    var id: String { recipeId }
    var recipeId: String
    var stepNotes: [String: String]
    var substitutions: [String: String]
}

struct CookingHistoryEntry: Identifiable, Hashable, Codable {
    var id: String
    var recipeId: String
    var recipeName: String
    var cookedAt: Date
    var durationMinutes: Int
}

struct PantryItem: Identifiable, Hashable, Codable {
    var id: String
    var name: String
    var normalizedKey: String
}

struct AchievementDefinition: Identifiable {
    let id: String
    let title: String
    let detail: String
    let symbolName: String
}

enum WeekDay: Int, CaseIterable, Identifiable {
    case monday = 0, tuesday, wednesday, thursday, friday, saturday, sunday
    var id: Int { rawValue }
    var title: String {
        switch self {
        case .monday: return "Mon"
        case .tuesday: return "Tue"
        case .wednesday: return "Wed"
        case .thursday: return "Thu"
        case .friday: return "Fri"
        case .saturday: return "Sat"
        case .sunday: return "Sun"
        }
    }
    var fullTitle: String {
        switch self {
        case .monday: return "Monday"
        case .tuesday: return "Tuesday"
        case .wednesday: return "Wednesday"
        case .thursday: return "Thursday"
        case .friday: return "Friday"
        case .saturday: return "Saturday"
        case .sunday: return "Sunday"
        }
    }
}
