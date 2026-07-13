import Foundation

enum IngredientSmart {
    private static let unitWords: Set<String> = [
        "cup", "cups", "tbsp", "tsp", "tablespoon", "tablespoons", "teaspoon", "teaspoons",
        "oz", "ounce", "ounces", "lb", "lbs", "g", "kg", "ml", "l", "clove", "cloves",
        "slice", "slices", "piece", "pieces", "can", "cans", "bunch", "pinches", "pinch"
    ]

    static func parse(_ raw: String) -> (quantity: String, unit: String, name: String, key: String) {
        let cleaned = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = cleaned.split(separator: " ").map(String.init)
        guard !parts.isEmpty else {
            return ("", "", cleaned, normalize(cleaned))
        }

        var index = 0
        var quantity = ""
        var unit = ""

        if let first = parts.first, looksLikeQuantity(first) {
            quantity = first
            index = 1
            if parts.count > 1, unitWords.contains(parts[1].lowercased().trimmingCharacters(in: .punctuationCharacters)) {
                unit = parts[1].trimmingCharacters(in: .punctuationCharacters)
                index = 2
            }
        }

        let nameParts = Array(parts.dropFirst(index))
        let name = nameParts.isEmpty ? cleaned : nameParts.joined(separator: " ")
        return (quantity, unit, name, normalize(name))
    }

    static func normalize(_ text: String) -> String {
        text
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty && !unitWords.contains($0) && Int($0) == nil }
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func guessCategory(for name: String) -> String {
        let key = normalize(name)
        let produce = ["tomato", "onion", "garlic", "spinach", "lettuce", "carrot", "pepper", "cucumber", "avocado", "berry", "lemon", "lime", "apple", "banana", "herb", "basil", "parsley", "zucchini", "mushroom", "broccoli"]
        let dairy = ["milk", "cheese", "yogurt", "butter", "cream", "feta", "parmesan", "egg"]
        let bakery = ["bread", "tortilla", "baguette", "bun", "flour", "oat", "pasta", "noodle", "rice", "couscous"]
        if produce.contains(where: { key.contains($0) }) { return "Produce" }
        if dairy.contains(where: { key.contains($0) }) { return "Dairy" }
        if bakery.contains(where: { key.contains($0) }) { return "Bakery" }
        return "Other"
    }

    static func mergeQuantity(existing: String, incoming: String) -> String {
        let a = parseNumber(existing)
        let b = parseNumber(incoming)
        if let a, let b {
            let sum = a + b
            if sum.rounded() == sum { return String(Int(sum)) }
            return String(format: "%.1f", sum)
        }
        if existing.isEmpty { return incoming }
        if incoming.isEmpty { return existing }
        return existing
    }

    static func displayLine(quantity: String, unit: String, name: String) -> String {
        let qty = [quantity, unit].filter { !$0.isEmpty }.joined(separator: " ")
        if qty.isEmpty { return name }
        return "\(qty) \(name)"
    }

    private static func looksLikeQuantity(_ value: String) -> Bool {
        parseNumber(value) != nil
    }

    private static func parseNumber(_ value: String) -> Double? {
        let trimmed = value.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { return nil }
        if let direct = Double(trimmed) { return direct }
        if trimmed.contains("/") {
            let bits = trimmed.split(separator: "/")
            if bits.count == 2, let n = Double(bits[0]), let d = Double(bits[1]), d != 0 {
                return n / d
            }
        }
        return nil
    }
}

enum RecipeLibrary {
    static func allRecipes(custom: [Recipe]) -> [Recipe] {
        RecipeCatalog.all + custom
    }

    static func recipe(id: String, custom: [Recipe]) -> Recipe? {
        allRecipes(custom: custom).first { $0.id == id }
    }

    static func pantryMatchRatio(recipe: Recipe, pantryKeys: Set<String>) -> Double {
        guard !recipe.ingredients.isEmpty, !pantryKeys.isEmpty else { return 0 }
        let matches = recipe.ingredients.filter { ingredient in
            let key = IngredientSmart.normalize(ingredient)
            return pantryKeys.contains { key.contains($0) || $0.contains(key) }
        }.count
        return Double(matches) / Double(recipe.ingredients.count)
    }
}
