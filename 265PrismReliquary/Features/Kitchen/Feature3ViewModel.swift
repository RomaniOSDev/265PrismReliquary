import Foundation
import Combine
import SwiftUI

final class Feature3ViewModel: ObservableObject {
    @Published var showEditor = false
    @Published var editingTimer: CookTimerItem?
    @Published var dishName = ""
    @Published var durationMinutes = 30
    @Published var nameError = false
    @Published var shakeTrigger: CGFloat = 0
    @Published var showSuccess = false

    private let store: AppDataStore

    init(store: AppDataStore = .shared) {
        self.store = store
        durationMinutes = store.defaultTimerDurationMin
        if !store.lastUsedTimerName.isEmpty {
            dishName = store.lastUsedTimerName
        }
    }

    func openNew() {
        editingTimer = nil
        dishName = store.lastUsedTimerName
        durationMinutes = store.defaultTimerDurationMin
        nameError = false
        showEditor = true
    }

    func openEdit(_ timer: CookTimerItem) {
        editingTimer = timer
        dishName = timer.name
        durationMinutes = max(1, timer.durationSeconds / 60)
        nameError = false
        showEditor = true
    }

    func save() {
        let trimmed = dishName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            FeedbackService.warning()
            nameError = true
            shakeTrigger += 1
            return
        }
        if let editingTimer {
            store.updateTimer(id: editingTimer.id, name: trimmed, minutes: durationMinutes)
        } else {
            store.addTimer(name: trimmed, minutes: durationMinutes)
        }
        FeedbackService.completeTick()
        showSuccess = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.showSuccess = false
        }
        showEditor = false
    }
}
