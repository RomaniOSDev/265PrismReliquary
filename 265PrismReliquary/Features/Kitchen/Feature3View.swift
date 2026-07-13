import SwiftUI
import Combine

struct Feature3View: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var viewModel = Feature3ViewModel()
    @Binding var tabBarHiddenCount: Int

    var body: some View {
        let _ = tabBarHiddenCount
        ZStack {
            if store.cookTimers.isEmpty {
                ScrollView {
                    EmptyStateCard(
                        symbol: "hourglass",
                        title: "No active timers. Tap + to start one!",
                        message: "Start by adding your first timer!"
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .tabBarClearance(140)
                }
                .clearScrollBackground()
            } else {
                TimelineView(.periodic(from: .now, by: scenePhase == .active ? 1 : 3600)) { timeline in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            SectionHeaderView(
                                title: "Active & recent",
                                subtitle: "\(store.cookTimers.filter { !$0.isCompleted && $0.isRunning }.count) running"
                            )
                            ForEach(store.cookTimers) { timer in
                                TimerCardCell(
                                    timer: timer,
                                    now: timeline.date,
                                    onToggle: {
                                        if timer.isRunning {
                                            store.pauseTimer(id: timer.id)
                                        } else {
                                            store.resumeTimer(id: timer.id)
                                        }
                                    },
                                    onEdit: { viewModel.openEdit(timer) }
                                )
                                .contextMenu {
                                    Button { viewModel.openEdit(timer) } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    if timer.isRunning {
                                        Button {
                                            store.pauseTimer(id: timer.id)
                                        } label: {
                                            Label("Pause", systemImage: "pause.fill")
                                        }
                                    } else if !timer.isCompleted {
                                        Button {
                                            store.resumeTimer(id: timer.id)
                                        } label: {
                                            Label("Resume", systemImage: "play.fill")
                                        }
                                    }
                                    Button(role: .destructive) {
                                        store.deleteTimer(id: timer.id)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .tabBarClearance(140)
                    }
                    .clearScrollBackground()
                }
            }

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        FeedbackService.lightTap()
                        viewModel.openNew()
                    } label: {
                        Image(systemName: "plus")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(Color("AppTextPrimary"))
                            .frame(width: 58, height: 58)
                            .background(
                                Circle()
                                    .fill(Color("AppPrimary"))
                                    .overlay(Circle().stroke(Color("AppAccent").opacity(0.4), lineWidth: 2))
                            )
                    }
                    .padding(.trailing, 22)
                    .padding(.bottom, 100)
                }
            }

            SuccessCheckOverlay(isVisible: viewModel.showSuccess)
        }
        .sheet(isPresented: $viewModel.showEditor) {
            timerEditor
        }
        .onAppear {
            store.syncTimers(at: Date(), isActive: scenePhase == .active)
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { date in
            guard scenePhase == .active else { return }
            store.syncTimers(at: date, isActive: true)
        }
        .onChange(of: scenePhase) { newPhase in
            store.syncTimers(at: Date(), isActive: newPhase == .active)
        }
    }

    private var timerEditor: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()
                Form {
                    Section {
                        TextField("Dish name", text: $viewModel.dishName)
                            .foregroundStyle(Color("AppTextPrimary"))
                            .modifier(ShakeEffect(animatableData: viewModel.shakeTrigger))
                        if viewModel.nameError {
                            Text("Enter a dish name.")
                                .font(.caption)
                                .foregroundStyle(Color.red)
                        }
                        Picker("Duration (minutes)", selection: $viewModel.durationMinutes) {
                            ForEach(Array(stride(from: 1, through: 180, by: 1)), id: \.self) { minute in
                                Text("\(minute) min").tag(minute)
                            }
                        }
                        .tint(Color("AppAccent"))
                    }
                    .listRowBackground(Color("AppSurface"))
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(viewModel.editingTimer == nil ? "New Timer" : "Edit Timer")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { viewModel.showEditor = false }
                        .foregroundStyle(Color("AppTextSecondary"))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { viewModel.save() }
                        .foregroundStyle(Color("AppAccent"))
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
