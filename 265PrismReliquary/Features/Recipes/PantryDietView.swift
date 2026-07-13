import SwiftUI

struct PantryDietView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var newItem = ""
    @State private var shake: CGFloat = 0
    @State private var showError = false

    var body: some View {
        ZStack {
            AppBackgroundView()
            ScrollView {
                VStack(spacing: 16) {
                    SurfaceCard {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeaderView(title: "Diet profile", subtitle: "Hard filters for browsing")
                            ForEach(RecipeCatalog.dietaryOptions, id: \.self) { tag in
                                Toggle(tag, isOn: Binding(
                                    get: { store.dietProfile.contains(tag) },
                                    set: { isOn in
                                        FeedbackService.lightTap()
                                        if isOn {
                                            if !store.dietProfile.contains(tag) { store.dietProfile.append(tag) }
                                        } else {
                                            store.dietProfile.removeAll { $0 == tag }
                                        }
                                        store.preferredDietaryFilters = store.dietProfile
                                        store.recordActivity()
                                    }
                                ))
                                .tint(Color("AppAccent"))
                                .foregroundStyle(Color("AppTextPrimary"))
                            }
                        }
                    }

                    SurfaceCard {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeaderView(title: "What I have", subtitle: "Pantry ingredients for smarter matching")
                            HStack(spacing: 10) {
                                TextField("Add ingredient", text: $newItem)
                                    .foregroundStyle(Color("AppTextPrimary"))
                                    .padding(12)
                                    .background(Color("AppBackground").opacity(0.35))
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    .modifier(ShakeEffect(animatableData: shake))
                                Button("Add") {
                                    let trimmed = newItem.trimmingCharacters(in: .whitespacesAndNewlines)
                                    guard !trimmed.isEmpty else {
                                        FeedbackService.warning()
                                        showError = true
                                        shake += 1
                                        return
                                    }
                                    store.addPantryItem(name: trimmed)
                                    FeedbackService.mediumTap()
                                    newItem = ""
                                    showError = false
                                }
                                .font(.headline)
                                .foregroundStyle(Color("AppTextPrimary"))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .background(Color("AppPrimary"))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            if showError {
                                Text("Enter an ingredient name.")
                                    .font(.caption)
                                    .foregroundStyle(Color.red)
                            }

                            if store.pantryItems.isEmpty {
                                Text("Add eggs, rice, chicken, and more.")
                                    .font(.caption)
                                    .foregroundStyle(Color("AppTextSecondary"))
                            } else {
                                ForEach(store.pantryItems) { item in
                                    PantryItemCell(item: item) {
                                        store.removePantryItem(id: item.id)
                                    }
                                }
                            }
                        }
                    }

                    SurfaceCard {
                        Toggle(isOn: $store.usePantryFilter) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Filter recipes by pantry")
                                    .foregroundStyle(Color("AppTextPrimary"))
                                Text("Show dishes you can mostly cook with what you have.")
                                    .font(.caption)
                                    .foregroundStyle(Color("AppTextSecondary"))
                            }
                        }
                        .tint(Color("AppAccent"))
                        .onChange(of: store.usePantryFilter) { _ in
                            FeedbackService.lightTap()
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 28)
            }
            .clearScrollBackground()
        }
        .navigationTitle("Pantry & Diet")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color("AppBackground"), for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}
