import Foundation
import Combine

final class Feature2ViewModel: ObservableObject {
    @Published var showAddSheet = false
    @Published var newItemName = ""
    @Published var newItemCategory = "Produce"
    @Published var nameError = false
    @Published var shakeTrigger: CGFloat = 0
    @Published var showSuccess = false
    @Published var pulseItemId: String?

    private let store: AppDataStore

    init(store: AppDataStore = .shared) {
        self.store = store
    }

    var categories: [String] {
        var set = store.defaultCategories
        for item in store.groceryItems where !set.contains(item.category) {
            set.append(item.category)
        }
        return set
    }

    func items(in category: String) -> [GroceryItem] {
        store.groceryItems
            .filter { $0.category == category }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    func addItem() {
        let trimmed = newItemName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            FeedbackService.warning()
            nameError = true
            shakeTrigger += 1
            return
        }
        store.addGroceryItem(name: trimmed, category: newItemCategory)
        FeedbackService.completeTick()
        withSuccess()
        newItemName = ""
        nameError = false
        showAddSheet = false
    }

    func toggleItem(_ id: String) {
        store.toggleGroceryCompletion(id: id)
        FeedbackService.completeTick()
        pulseItemId = id
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            self?.pulseItemId = nil
        }
    }

    func completeList() {
        guard !store.groceryItems.isEmpty else {
            FeedbackService.warning()
            return
        }
        store.completeGroceryList()
        FeedbackService.success()
        withSuccess()
    }

    private func withSuccess() {
        showSuccess = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.showSuccess = false
        }
    }

    func withSuccessPublic() {
        withSuccess()
    }
}
