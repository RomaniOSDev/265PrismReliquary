import SwiftUI
import UIKit

struct CookModeView: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    let recipe: Recipe
    @State private var stepIndex = 0
    @State private var stepTimerMinutes = 5
    @State private var showTimerSheet = false
    @State private var noteDraft = ""
    @State private var showDone = false

    private var personalization: RecipePersonalization? {
        store.personalization(for: recipe.id)
    }

    private var steps: [String] { recipe.steps }

    var body: some View {
        ZStack {
            AppBackgroundView()

            VStack(spacing: 20) {
                progressHeader

                Spacer(minLength: 0)

                SurfaceCard(padding: 22, cornerRadius: 24) {
                    VStack(spacing: 16) {
                        Text("Step \(stepIndex + 1) of \(max(steps.count, 1))")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color("AppAccent"))

                        Text(currentStepText)
                            .font(.title.bold())
                            .foregroundStyle(Color("AppTextPrimary"))
                            .multilineTextAlignment(.center)
                            .minimumScaleFactor(0.7)

                        if let note = personalization?.stepNotes[String(stepIndex)], !note.isEmpty {
                            Text("Note: \(note)")
                                .font(.body)
                                .foregroundStyle(Color("AppTextSecondary"))
                                .multilineTextAlignment(.center)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 20)

                Spacer(minLength: 0)

                controls
            }
            .padding(.bottom, 24)

            SuccessCheckOverlay(isVisible: showDone)
        }
        .navigationTitle(recipe.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") {
                    FeedbackService.lightTap()
                    dismiss()
                }
                .foregroundStyle(Color("AppTextSecondary"))
            }
        }
        .sheet(isPresented: $showTimerSheet) {
            stepTimerSheet
        }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
            noteDraft = personalization?.stepNotes[String(stepIndex)] ?? ""
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .onChange(of: stepIndex) { _ in
            noteDraft = personalization?.stepNotes[String(stepIndex)] ?? ""
        }
        .onChange(of: scenePhase) { phase in
            UIApplication.shared.isIdleTimerDisabled = (phase == .active)
        }
    }

    private var currentStepText: String {
        guard steps.indices.contains(stepIndex) else { return "No steps yet." }
        return steps[stepIndex]
    }

    private var progressHeader: some View {
        GeometryReader { geo in
            let progress = steps.isEmpty ? 0 : CGFloat(stepIndex + 1) / CGFloat(steps.count)
            Capsule()
                .fill(Color("AppSurface"))
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(Color("AppAccent"))
                        .frame(width: max(12, geo.size.width * progress))
                }
        }
        .frame(height: 10)
        .padding(.horizontal, 24)
        .padding(.top, 12)
    }

    private var controls: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button {
                    FeedbackService.lightTap()
                    showTimerSheet = true
                } label: {
                    Label("Step Timer", systemImage: "timer")
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color("AppSurface"))
                        .foregroundStyle(Color("AppTextPrimary"))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }

                Button {
                    FeedbackService.lightTap()
                    store.updateStepNote(recipeId: recipe.id, stepIndex: stepIndex, note: noteDraft)
                    FeedbackService.mediumTap()
                } label: {
                    Label("Save Note", systemImage: "note.text")
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color("AppSurface"))
                        .foregroundStyle(Color("AppTextPrimary"))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
            .padding(.horizontal, 20)

            TextField("Add a note for this step", text: $noteDraft, axis: .vertical)
                .lineLimit(2...3)
                .padding(12)
                .background(Color("AppSurface"))
                .foregroundStyle(Color("AppTextPrimary"))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding(.horizontal, 20)

            HStack(spacing: 12) {
                Button {
                    FeedbackService.lightTap()
                    withAnimation(.easeInOut(duration: 0.3)) {
                        stepIndex = max(0, stepIndex - 1)
                    }
                } label: {
                    Text("Back")
                        .font(.headline)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color("AppSurface"))
                        .foregroundStyle(Color("AppTextPrimary"))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .disabled(stepIndex == 0)
                .opacity(stepIndex == 0 ? 0.4 : 1)

                Button {
                    FeedbackService.lightTap()
                    if stepIndex >= steps.count - 1 {
                        finishCooking()
                    } else {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            stepIndex += 1
                        }
                    }
                } label: {
                    Text(stepIndex >= steps.count - 1 ? "Finish" : "Next Step")
                        .font(.headline)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color("AppPrimary"))
                        .foregroundStyle(Color("AppTextPrimary"))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private var stepTimerSheet: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()
                Form {
                    Section {
                        Picker("Minutes", selection: $stepTimerMinutes) {
                            ForEach(Array(stride(from: 1, through: 90, by: 1)), id: \.self) { value in
                                Text("\(value) min").tag(value)
                            }
                        }
                        .tint(Color("AppAccent"))
                    }
                    .listRowBackground(Color("AppSurface"))
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Step Timer")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showTimerSheet = false }
                        .foregroundStyle(Color("AppTextSecondary"))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Start") {
                        store.addTimer(name: "\(recipe.name) · Step \(stepIndex + 1)", minutes: stepTimerMinutes)
                        FeedbackService.completeTick()
                        showTimerSheet = false
                    }
                    .foregroundStyle(Color("AppAccent"))
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func finishCooking() {
        store.finishCookMode(recipe: recipe)
        showDone = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            showDone = false
            dismiss()
        }
    }
}
