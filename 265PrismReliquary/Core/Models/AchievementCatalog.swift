import Foundation

enum AchievementCatalog {
    static let all: [AchievementDefinition] = [
        AchievementDefinition(
            id: "first_glance",
            title: "First Glance",
            detail: "Viewed your first recipe.",
            symbolName: "eye.fill"
        ),
        AchievementDefinition(
            id: "recipe_explorer",
            title: "Recipe Explorer",
            detail: "Viewed ten different recipes.",
            symbolName: "book.fill"
        ),
        AchievementDefinition(
            id: "favorites_fan",
            title: "Favorites Fan",
            detail: "Added five recipes to favorites.",
            symbolName: "heart.fill"
        ),
        AchievementDefinition(
            id: "list_completer",
            title: "List Completer",
            detail: "Completed your first grocery list.",
            symbolName: "checklist"
        ),
        AchievementDefinition(
            id: "power_user",
            title: "Power User",
            detail: "Reached 50 items.",
            symbolName: "bolt.fill"
        ),
        AchievementDefinition(
            id: "active_user",
            title: "Active User",
            detail: "Completed 10 sessions.",
            symbolName: "flame.fill"
        ),
        AchievementDefinition(
            id: "dedicated_user",
            title: "Dedicated User",
            detail: "Completed 50 sessions.",
            symbolName: "star.fill"
        ),
        AchievementDefinition(
            id: "three_day_streak",
            title: "Three-Day Streak",
            detail: "Used the app 3 days in a row.",
            symbolName: "calendar"
        )
    ]

    static func isUnlocked(_ id: String, store: AppDataStore) -> Bool {
        switch id {
        case "first_glance":
            return store.recipesViewed >= 1
        case "recipe_explorer":
            return store.recipesViewed >= 10
        case "favorites_fan":
            return store.favouritesAdded >= 5
        case "list_completer":
            return store.listsCompleted >= 1
        case "power_user":
            return store.recipesViewed >= 50
        case "active_user":
            return store.listsCompleted >= 10
        case "dedicated_user":
            return store.listsCompleted >= 50
        case "three_day_streak":
            return store.streakDays >= 3
        default:
            return false
        }
    }
}
