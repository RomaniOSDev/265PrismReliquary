import SwiftUI

struct Feature2View: View {
    @EnvironmentObject private var store: AppDataStore
    @StateObject private var viewModel = Feature2ViewModel()
    @Binding var tabBarHiddenCount: Int

    var body: some View {
        let _ = tabBarHiddenCount
        ZStack {
            if store.groceryItems.isEmpty {
                ScrollView {
                    EmptyStateCard(
                        symbol: "cart.fill",
                        title: "No items yet",
                        message: "Start your list! Add items, staples, or build from your meal plan."
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .tabBarClearance(140)
                }
                .clearScrollBackground()
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        SurfaceCard {
                            VStack(alignment: .leading, spacing: 10) {
                                SectionHeaderView(
                                    title: "Smart list",
                                    subtitle: "\(store.groceryItems.filter { !$0.completed }.count) left · \(store.groceryItems.filter(\.completed).count) done"
                                )
                                HStack(spacing: 8) {
                                    miniAction("Merge", "arrow.triangle.merge") {
                                        store.mergeDuplicateGroceries()
                                        FeedbackService.mediumTap()
                                        viewModel.withSuccessPublic()
                                    }
                                    miniAction("Staples", "basket") {
                                        store.addWeeklyStaples()
                                        viewModel.withSuccessPublic()
                                    }
                                    ShareLink(item: store.groceryShareText()) {
                                        Label("Export", systemImage: "square.and.arrow.up")
                                            .font(.caption.weight(.bold))
                                            .foregroundStyle(Color("AppTextPrimary"))
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 10)
                                            .background(Color("AppPrimary").opacity(0.35))
                                            .clipShape(Capsule())
                                    }
                                    .simultaneousGesture(TapGesture().onEnded { FeedbackService.lightTap() })
                                }
                            }
                        }

                        ForEach(viewModel.categories, id: \.self) { category in
                            let items = viewModel.items(in: category)
                            if !items.isEmpty {
                                VStack(alignment: .leading, spacing: 10) {
                                    Button {
                                        FeedbackService.lightTap()
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            store.toggleCategoryCollapsed(category)
                                        }
                                    } label: {
                                        HStack {
                                            Text(category)
                                                .font(.headline)
                                                .foregroundStyle(Color("AppTextPrimary"))
                                            Text("\(items.count)")
                                                .font(.caption.weight(.bold))
                                                .foregroundStyle(Color("AppTextPrimary"))
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(Color("AppPrimary").opacity(0.35))
                                                .clipShape(Capsule())
                                            Spacer()
                                            Image(systemName: store.collapsedCategories.contains(category) ? "chevron.right" : "chevron.down")
                                                .foregroundStyle(Color("AppAccent"))
                                        }
                                        .frame(minHeight: 44)
                                    }
                                    .buttonStyle(.plain)

                                    if !store.collapsedCategories.contains(category) {
                                        ForEach(items) { item in
                                            GroceryItemCell(
                                                item: item,
                                                isPulsing: viewModel.pulseItemId == item.id,
                                                onToggle: { viewModel.toggleItem(item.id) }
                                            )
                                            .contextMenu {
                                                Button {
                                                    viewModel.toggleItem(item.id)
                                                } label: {
                                                    Label(item.completed ? "Mark Incomplete" : "Mark Complete", systemImage: "checkmark")
                                                }
                                                Button(role: .destructive) {
                                                    store.deleteGroceryItem(id: item.id)
                                                } label: {
                                                    Label("Delete", systemImage: "trash")
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .tabBarClearance(150)
                }
                .clearScrollBackground()
            }

            VStack {
                Spacer()
                HStack(spacing: 12) {
                    AppPrimaryButton(title: "Complete", symbol: "checkmark.circle", filled: false) {
                        viewModel.completeList()
                    }
                    .disabled(store.groceryItems.isEmpty)
                    .opacity(store.groceryItems.isEmpty ? 0.5 : 1)

                    AppPrimaryButton(title: "Add Item", symbol: "plus") {
                        viewModel.newItemName = ""
                        viewModel.nameError = false
                        viewModel.showAddSheet = true
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }

            SuccessCheckOverlay(isVisible: viewModel.showSuccess)
        }
        .sheet(isPresented: $viewModel.showAddSheet) {
            addItemSheet
        }
    }

    private func miniAction(_ title: String, _ symbol: String, action: @escaping () -> Void) -> some View {
        Button {
            FeedbackService.lightTap()
            action()
        } label: {
            Label(title, systemImage: symbol)
                .font(.caption.weight(.bold))
                .foregroundStyle(Color("AppTextPrimary"))
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color("AppBackground").opacity(0.35))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var addItemSheet: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()
                Form {
                    Section {
                        TextField("Item name", text: $viewModel.newItemName)
                            .foregroundStyle(Color("AppTextPrimary"))
                            .modifier(ShakeEffect(animatableData: viewModel.shakeTrigger))
                        if viewModel.nameError {
                            Text("Enter an item name.")
                                .font(.caption)
                                .foregroundStyle(Color.red)
                        }
                        Picker("Category", selection: $viewModel.newItemCategory) {
                            ForEach(viewModel.categories, id: \.self) { category in
                                Text(category).tag(category)
                            }
                        }
                        .tint(Color("AppAccent"))
                    }
                    .listRowBackground(Color("AppSurface"))
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Add Item")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.showAddSheet = false
                    }
                    .foregroundStyle(Color("AppTextSecondary"))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { viewModel.addItem() }
                        .foregroundStyle(Color("AppAccent"))
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
