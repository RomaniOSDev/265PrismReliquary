import SwiftUI

struct KitchenHubView: View {
    @EnvironmentObject private var store: AppDataStore
    @Binding var tabBarHiddenCount: Int
    @State private var segment = 0

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()

                VStack(spacing: 0) {
                    Picker("Section", selection: $segment) {
                        Text("Plan").tag(0)
                        Text("Groceries").tag(1)
                        Text("Timers").tag(2)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .onChange(of: segment) { newValue in
                        FeedbackService.lightTap()
                        store.preferredKitchenSegment = newValue
                    }

                    Group {
                        switch segment {
                        case 0:
                            MealPlanView(tabBarHiddenCount: $tabBarHiddenCount)
                        case 1:
                            Feature2View(tabBarHiddenCount: $tabBarHiddenCount)
                        default:
                            Feature3View(tabBarHiddenCount: $tabBarHiddenCount)
                        }
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color("AppBackground"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear {
                segment = store.preferredKitchenSegment
            }
        }
        .transparentScreenChrome()
    }

    private var title: String {
        switch segment {
        case 0: return "Meal Plan"
        case 1: return "My Groceries"
        default: return "Cooking Timers"
        }
    }
}
