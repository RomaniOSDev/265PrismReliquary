import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var page = 0
    @State private var animateIllustration = false

    private let pages: [(headline: String, detail: String, kind: OnboardingArtKind)] = [
        (
            "Simplify Cooking",
            "Discover how this app can streamline your meal preparation process.",
            .simplify
        ),
        (
            "Explore Recipes",
            "Tap into a diverse library of recipes tailored to your preferences.",
            .explore
        ),
        (
            "Get Started",
            "Begin by browsing recipes and selecting meals for your week.",
            .start
        )
    ]

    var body: some View {
        ZStack {
            AppBackgroundView()

            VStack(spacing: 0) {
                topProgress
                    .padding(.horizontal, 24)
                    .padding(.top, 16)

                TabView(selection: $page) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        pageContent(index)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: page)

                bottomChrome
            }
        }
        .onAppear { triggerIllustration() }
        .onChange(of: page) { _ in triggerIllustration() }
    }

    private var topProgress: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Step \(page + 1) of \(pages.count)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color("AppTextSecondary"))
                Spacer()
                TagChip(text: page == pages.count - 1 ? "Ready" : "Setup", emphasized: page == pages.count - 1)
            }

            GeometryReader { geo in
                let progress = CGFloat(page + 1) / CGFloat(pages.count)
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color("AppSurface").opacity(0.7))
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color("AppAccent"), Color("AppPrimary")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(18, geo.size.width * progress))
                        .softShadow(.raised)
                }
            }
            .frame(height: 8)
        }
    }

    private func pageContent(_ index: Int) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                SurfaceCard(padding: 22, cornerRadius: 28, depth: .floating, gloss: true) {
                    VStack(spacing: 22) {
                        OnboardingArtView(kind: pages[index].kind)
                            .frame(height: 180)
                            .scaleEffect(animateIllustration && page == index ? 1 : 0.86)
                            .opacity(animateIllustration && page == index ? 1 : 0.4)

                        Text(pages[index].headline)
                            .font(.largeTitle.bold())
                            .foregroundStyle(Color("AppTextPrimary"))
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.7)

                        Text(pages[index].detail)
                            .font(.body)
                            .foregroundStyle(Color("AppTextSecondary"))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 4)

                        featurePills(for: index)
                    }
                    .frame(maxWidth: .infinity)
                }

                if index == 0 {
                    tipRow(symbol: "timer", text: "Plan meals, shop smarter, cook with timers")
                } else if index == 1 {
                    tipRow(symbol: "heart.fill", text: "Save favourites and personalize ingredients")
                } else {
                    tipRow(symbol: "calendar", text: "Build a weekly plate in a few taps")
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 12)
        }
        .clearScrollBackground()
    }

    private func featurePills(for index: Int) -> some View {
        let labels: [String] = {
            switch index {
            case 0: return ["Meal plan", "Timers", "Lists"]
            case 1: return ["Browse", "Filters", "Cook mode"]
            default: return ["Pantry", "Insights", "Streaks"]
            }
        }()
        return HStack(spacing: 8) {
            ForEach(labels, id: \.self) { label in
                TagChip(text: label, emphasized: label == labels[1])
            }
        }
    }

    private func tipRow(symbol: String, text: String) -> some View {
        SurfaceCard(padding: 14, cornerRadius: 18, depth: .raised, gloss: false) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color("AppAccent").opacity(0.55), Color("AppPrimary").opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 42, height: 42)
                    Image(systemName: symbol)
                        .foregroundStyle(Color("AppTextPrimary"))
                }
                .softShadow(.raised)

                Text(text)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color("AppTextSecondary"))
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
                Spacer(minLength: 0)
            }
        }
    }

    private var bottomChrome: some View {
        VStack(spacing: 16) {
            HStack(spacing: 8) {
                ForEach(0..<pages.count, id: \.self) { index in
                    Capsule()
                        .fill(
                            index == page
                                ? LinearGradient(
                                    colors: [Color("AppAccent"), Color("AppPrimary")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                : LinearGradient(
                                    colors: [Color("AppPrimary").opacity(0.35), Color("AppSurface")],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                        )
                        .frame(width: index == page ? 24 : 8, height: 8)
                        .softShadow(index == page ? .raised : .flat)
                        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: page)
                }
            }

            AppPrimaryButton(
                title: page < pages.count - 1 ? "Next" : "Get Started",
                symbol: page < pages.count - 1 ? "arrow.right" : "checkmark.circle.fill"
            ) {
                if page < pages.count - 1 {
                    withAnimation(.easeInOut(duration: 0.3)) { page += 1 }
                    triggerIllustration()
                } else {
                    FeedbackService.mediumTap()
                    store.markOnboardingSeen()
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 28)
        .background(
            LinearGradient(
                colors: [
                    Color("AppBackground").opacity(0.0),
                    Color("AppBackground").opacity(0.92),
                    Color("AppSurface").opacity(0.95)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .bottom)
            .allowsHitTesting(false)
        )
    }

    private func triggerIllustration() {
        animateIllustration = false
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            animateIllustration = true
        }
    }
}

// MARK: - Art

private enum OnboardingArtKind {
    case simplify
    case explore
    case start
}

private struct OnboardingArtView: View {
    let kind: OnboardingArtKind

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color("AppAccent").opacity(0.28),
                            Color("AppAccent").opacity(0.0)
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 120
                    )
                )
                .frame(width: 220, height: 220)
                .allowsHitTesting(false)

            switch kind {
            case .simplify:
                simplifyArt
            case .explore:
                exploreArt
            case .start:
                startArt
            }
        }
    }

    private var simplifyArt: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color("AppPrimary"), Color("AppSurface")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 150, height: 110)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color("AppAccent").opacity(0.35), lineWidth: 1)
                )
                .softShadow(.floating)

            VStack(spacing: 8) {
                Capsule().fill(Color("AppAccent")).frame(width: 70, height: 8)
                Capsule().fill(Color("AppTextPrimary").opacity(0.7)).frame(width: 96, height: 6)
                Capsule().fill(Color("AppTextPrimary").opacity(0.45)).frame(width: 80, height: 6)
            }

            Image(systemName: "flame.fill")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Color("AppAccent"))
                .padding(12)
                .background(
                    Circle()
                        .fill(Color("AppBackground").opacity(0.35))
                        .overlay(Circle().stroke(Color("AppAccent").opacity(0.35), lineWidth: 1))
                )
                .softShadow(.raised)
                .offset(x: 70, y: -58)
        }
    }

    private var exploreArt: some View {
        HStack(spacing: 12) {
            ForEach(0..<3, id: \.self) { index in
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: index == 1
                                ? [Color("AppAccent"), Color("AppPrimary")]
                                : [Color("AppPrimary").opacity(0.85), Color("AppSurface")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 68, height: index == 1 ? 126 : 104)
                    .overlay(
                        Image(systemName: index == 1 ? "book.fill" : "leaf.fill")
                            .foregroundStyle(Color("AppTextPrimary"))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color("AppAccent").opacity(0.28), lineWidth: 1)
                    )
                    .softShadow(.raised)
                    .offset(y: index == 1 ? -10 : 0)
            }
        }
    }

    private var startArt: some View {
        ZStack {
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [Color("AppPrimary").opacity(0.35), Color("AppSurface")],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 10
                )
                .frame(width: 132, height: 132)

            Circle()
                .trim(from: 0, to: 0.78)
                .stroke(
                    AngularGradient(
                        colors: [Color("AppAccent"), Color("AppPrimary"), Color("AppAccent")],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .frame(width: 132, height: 132)
                .rotationEffect(.degrees(-90))
                .softShadow(.raised)

            Image(systemName: "checkmark")
                .font(.system(size: 44, weight: .bold))
                .foregroundStyle(Color("AppTextPrimary"))
                .padding(18)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color("AppAccent").opacity(0.7), Color("AppPrimary")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .softShadow(.floating)
        }
    }
}
