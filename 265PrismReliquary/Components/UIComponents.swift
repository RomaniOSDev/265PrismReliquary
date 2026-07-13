import SwiftUI

// MARK: - Surfaces

struct SurfaceCard<Content: View>: View {
    var padding: CGFloat = 14
    var cornerRadius: CGFloat = 18
    var depth: DepthStyle = .raised
    var gloss: Bool = true
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardChrome(cornerRadius: cornerRadius, depth: depth, gloss: gloss)
    }
}

struct SectionHeaderView: View {
    let title: String
    var subtitle: String? = nil
    var trailing: AnyView? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title3.bold())
                    .foregroundStyle(Color("AppTextPrimary"))
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(Color("AppTextSecondary"))
                }
            }
            Spacer(minLength: 8)
            if let trailing {
                trailing
            }
        }
    }
}

struct EmptyStateCard: View {
    let symbol: String
    let title: String
    let message: String

    var body: some View {
        SurfaceCard(depth: .floating) {
            VStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color("AppAccent").opacity(0.45),
                                    Color("AppPrimary").opacity(0.18)
                                ],
                                center: .center,
                                startRadius: 4,
                                endRadius: 46
                            )
                        )
                        .frame(width: 84, height: 84)
                        .softShadow(.raised)
                    Image(systemName: symbol)
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundStyle(Color("AppAccent"))
                }
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color("AppTextPrimary"))
                    .multilineTextAlignment(.center)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(Color("AppTextSecondary"))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
        }
    }
}

struct TagChip: View {
    let text: String
    var emphasized: Bool = false

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color("AppTextPrimary"))
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: emphasized
                                ? [Color("AppAccent").opacity(0.55), Color("AppPrimary").opacity(0.35)]
                                : [Color("AppPrimary").opacity(0.40), Color("AppSurface").opacity(0.55)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color("AppAccent").opacity(emphasized ? 0.35 : 0.18), lineWidth: 1)
                    )
            )
    }
}

struct MetricTile: View {
    let title: String
    let value: String
    var symbol: String? = nil
    var inset: Bool = false

    var body: some View {
        SurfaceCard(padding: 12, cornerRadius: 16, depth: inset ? .flat : .raised, gloss: !inset) {
            VStack(alignment: .leading, spacing: 10) {
                if let symbol {
                    ZStack {
                        Circle()
                            .fill(Color("AppPrimary").opacity(0.28))
                            .frame(width: 28, height: 28)
                        Image(systemName: symbol)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color("AppAccent"))
                    }
                }
                Text(value)
                    .font(.title2.bold())
                    .foregroundStyle(Color("AppTextPrimary"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(Color("AppTextSecondary"))
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
            }
        }
    }
}

struct AppPrimaryButton: View {
    let title: String
    var symbol: String? = nil
    var isDestructive: Bool = false
    var filled: Bool = true
    let action: () -> Void

    var body: some View {
        Button {
            FeedbackService.lightTap()
            action()
        } label: {
            HStack(spacing: 8) {
                if let symbol {
                    Image(systemName: symbol)
                }
                Text(title)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .font(.headline)
            .foregroundStyle(isDestructive ? Color.red : Color("AppTextPrimary"))
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(buttonFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(
                                isDestructive
                                    ? Color.red.opacity(0.4)
                                    : Color("AppAccent").opacity(0.35),
                                lineWidth: 1
                            )
                    )
            )
            .softShadow(filled && !isDestructive ? .raised : .flat)
        }
        .buttonStyle(ScalePressStyle())
        .frame(minHeight: 44)
    }

    private var buttonFill: LinearGradient {
        if isDestructive {
            return LinearGradient(
                colors: [Color.red.opacity(0.22), Color.red.opacity(0.12)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        if filled {
            return LinearGradient(
                colors: [Color("AppAccent").opacity(0.95), Color("AppPrimary")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        return LinearGradient(
            colors: [Color("AppSurface"), Color("AppPrimary").opacity(0.25)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct ScalePressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct IconActionButton: View {
    let symbol: String
    var tint: Color = Color("AppAccent")
    let action: () -> Void

    var body: some View {
        Button {
            FeedbackService.lightTap()
            action()
        } label: {
            Image(systemName: symbol)
                .font(.body.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color("AppSurface"),
                                    Color("AppPrimary").opacity(0.35)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(Circle().stroke(Color("AppAccent").opacity(0.25), lineWidth: 1))
                )
                .softShadow(.raised)
        }
        .buttonStyle(ScalePressStyle())
    }
}

// MARK: - Recipe Cell

struct RecipeCardCell: View {
    let recipe: Recipe
    var isFavourite: Bool
    var isPulsing: Bool = false
    var pantryMatch: Double? = nil
    var timesCooked: Int = 0

    var body: some View {
        SurfaceCard(padding: 12, cornerRadius: 20) {
            HStack(alignment: .top, spacing: 14) {
                recipeThumb
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top) {
                        Text(recipe.name)
                            .font(.headline)
                            .foregroundStyle(Color("AppTextPrimary"))
                            .lineLimit(2)
                            .minimumScaleFactor(0.75)
                        Spacer(minLength: 4)
                        if isFavourite {
                            Image(systemName: "heart.fill")
                                .foregroundStyle(Color("AppAccent"))
                                .font(.caption)
                        }
                    }
                    Text(recipe.summary)
                        .font(.caption)
                        .foregroundStyle(Color("AppTextSecondary"))
                        .lineLimit(2)
                    HStack(spacing: 8) {
                        Label("\(recipe.cookTimeMinutes) min", systemImage: "clock.fill")
                        Text(recipe.mealType)
                        if recipe.isCustom {
                            Text("Mine")
                        }
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color("AppPrimary"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                    HStack(spacing: 6) {
                        if let pantryMatch, pantryMatch > 0 {
                            TagChip(text: "\(Int(pantryMatch * 100))% pantry", emphasized: true)
                        }
                        if timesCooked > 0 {
                            TagChip(text: "Cooked \(timesCooked)×")
                        }
                        if let first = recipe.dietaryTags.first {
                            TagChip(text: first)
                        }
                    }
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(isPulsing ? Color("AppAccent").opacity(0.25) : Color.clear)
        )
        .animation(.easeInOut(duration: 0.35), value: isPulsing)
    }

    private var recipeThumb: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color("AppPrimary").opacity(0.5), Color("AppSurface")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            AsyncImage(url: URL(string: recipe.imageURL)) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                default:
                    Image(systemName: "fork.knife")
                        .foregroundStyle(Color("AppTextPrimary"))
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color("AppAccent").opacity(0.3), lineWidth: 1)
        }
        .frame(width: 86, height: 86)
        .softShadow(.raised)
    }
}

// MARK: - Grocery Cell

struct GroceryItemCell: View {
    let item: GroceryItem
    var isPulsing: Bool = false
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            SurfaceCard(padding: 12, cornerRadius: 16) {
                HStack(spacing: 12) {
                    Image(systemName: item.completed ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundStyle(item.completed ? Color("AppAccent") : Color("AppTextSecondary"))
                        .frame(width: 44, height: 44)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.displayName)
                            .font(.headline)
                            .foregroundStyle(Color("AppTextPrimary"))
                            .strikethrough(item.completed)
                            .lineLimit(2)
                            .minimumScaleFactor(0.75)
                        HStack(spacing: 8) {
                            Text(item.category)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color("AppPrimary"))
                            if !item.sourceRecipeIds.isEmpty {
                                Text("From \(item.sourceRecipeIds.count) recipe\(item.sourceRecipeIds.count == 1 ? "" : "s")")
                                    .font(.caption)
                                    .foregroundStyle(Color("AppTextSecondary"))
                            }
                        }
                    }
                    Spacer(minLength: 0)
                    if !item.quantityLabel.isEmpty || !item.unitLabel.isEmpty {
                        VStack(spacing: 2) {
                            Text(item.quantityLabel.isEmpty ? "—" : item.quantityLabel)
                                .font(.headline.monospacedDigit())
                            Text(item.unitLabel.isEmpty ? "qty" : item.unitLabel)
                                .font(.caption2)
                        }
                        .foregroundStyle(Color("AppTextPrimary"))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(Color("AppPrimary").opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isPulsing ? Color("AppAccent") : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.35), value: isPulsing)
    }
}

// MARK: - Timer Cell

struct TimerCardCell: View {
    let timer: CookTimerItem
    let now: Date
    let onToggle: () -> Void
    let onEdit: () -> Void

    private var remaining: Int { timer.liveRemaining(at: now) }
    private var progress: CGFloat {
        guard timer.durationSeconds > 0 else { return 0 }
        return 1 - CGFloat(remaining) / CGFloat(timer.durationSeconds)
    }

    var body: some View {
        SurfaceCard(padding: 14, cornerRadius: 20) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [Color("AppPrimary").opacity(0.25), Color("AppSurface")],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 8
                        )
                    Circle()
                        .trim(from: 0, to: timer.isCompleted ? 1 : progress)
                        .stroke(
                            AngularGradient(
                                colors: [Color("AppAccent"), Color("AppPrimary"), Color("AppAccent")],
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                    Text(timer.isCompleted ? "OK" : format(remaining))
                        .font(.caption.bold().monospacedDigit())
                        .foregroundStyle(Color("AppTextPrimary"))
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                }
                .frame(width: 64, height: 64)
                .softShadow(.raised)

                VStack(alignment: .leading, spacing: 6) {
                    Text(timer.name)
                        .font(.headline)
                        .foregroundStyle(Color("AppTextPrimary"))
                        .lineLimit(2)
                        .minimumScaleFactor(0.75)
                    Text(statusText)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color("AppPrimary"))
                    Text(format(remaining))
                        .font(.title3.monospacedDigit().weight(.bold))
                        .foregroundStyle(timer.isCompleted ? Color("AppAccent") : Color("AppTextPrimary"))
                }
                Spacer(minLength: 0)
                VStack(spacing: 8) {
                    if !timer.isCompleted {
                        IconActionButton(symbol: timer.isRunning ? "pause.fill" : "play.fill", action: onToggle)
                    }
                    IconActionButton(symbol: "pencil", tint: Color("AppPrimary"), action: onEdit)
                }
            }
        }
    }

    private var statusText: String {
        if timer.isCompleted { return "Completed" }
        return timer.isRunning ? "Running" : "Paused"
    }

    private func format(_ seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}

// MARK: - Meal Plan Cell

struct MealPlanDishCell: View {
    let recipe: Recipe
    let isCooked: Bool
    let onCooked: () -> Void
    let onRemove: () -> Void

    var body: some View {
        SurfaceCard(padding: 12, cornerRadius: 16, depth: .flat, gloss: false) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color("AppPrimary").opacity(0.45), Color("AppSurface")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Image(systemName: isCooked ? "checkmark.seal.fill" : "fork.knife")
                        .foregroundStyle(isCooked ? Color("AppAccent") : Color("AppTextPrimary"))
                }
                .frame(width: 52, height: 52)

                VStack(alignment: .leading, spacing: 4) {
                    Text(recipe.name)
                        .font(.headline)
                        .foregroundStyle(Color("AppTextPrimary"))
                        .lineLimit(2)
                        .minimumScaleFactor(0.75)
                    Text("\(recipe.cookTimeMinutes) min · \(recipe.mealType)")
                        .font(.caption)
                        .foregroundStyle(Color("AppTextSecondary"))
                }
                Spacer(minLength: 0)
                if isCooked {
                    TagChip(text: "Cooked", emphasized: true)
                } else {
                    Button {
                        FeedbackService.lightTap()
                        onCooked()
                    } label: {
                        Text("Cooked")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color("AppTextPrimary"))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(Color("AppPrimary"))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
                IconActionButton(symbol: "trash", tint: Color.red.opacity(0.9), action: onRemove)
            }
        }
    }
}

// MARK: - Settings / Stats rows

struct SettingsRowCell: View {
    let title: String
    let symbol: String
    var destructive: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            SurfaceCard(padding: 14, cornerRadius: 16) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(destructive ? Color.red.opacity(0.18) : Color("AppPrimary").opacity(0.28))
                        Image(systemName: symbol)
                            .foregroundStyle(destructive ? Color.red : Color("AppAccent"))
                    }
                    .frame(width: 40, height: 40)
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(destructive ? Color.red : Color("AppTextPrimary"))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(Color("AppTextSecondary"))
                }
            }
        }
        .buttonStyle(.plain)
    }
}

struct InsightRowCell: View {
    let title: String
    let value: String
    var symbol: String = "circle.fill"

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.caption)
                .foregroundStyle(Color("AppAccent"))
                .frame(width: 22)
            Text(title)
                .foregroundStyle(Color("AppTextSecondary"))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .foregroundStyle(Color("AppTextPrimary"))
        }
        .font(.subheadline)
        .padding(.vertical, 4)
    }
}

struct AchievementCardCell: View {
    let achievement: AchievementDefinition
    let unlocked: Bool

    var body: some View {
        SurfaceCard(padding: 12, cornerRadius: 18) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(unlocked ? Color("AppPrimary") : Color("AppBackground").opacity(0.4))
                        .frame(width: 58, height: 58)
                    Image(systemName: achievement.symbolName)
                        .font(.title2)
                        .foregroundStyle(unlocked ? Color("AppTextPrimary") : Color("AppTextSecondary").opacity(0.55))
                }
                Text(achievement.title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color("AppTextPrimary"))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                Text(achievement.detail)
                    .font(.caption2)
                    .foregroundStyle(Color("AppTextSecondary"))
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .minimumScaleFactor(0.7)
                Text(unlocked ? "Unlocked" : "Locked")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(unlocked ? Color("AppAccent") : Color("AppTextSecondary"))
            }
            .frame(maxWidth: .infinity, minHeight: 160)
        }
        .opacity(unlocked ? 1 : 0.78)
    }
}

struct PantryItemCell: View {
    let item: PantryItem
    let onRemove: () -> Void

    var body: some View {
        SurfaceCard(padding: 12, cornerRadius: 14, depth: .flat, gloss: false) {
            HStack {
                Image(systemName: "leaf.fill")
                    .foregroundStyle(Color("AppAccent"))
                Text(item.name)
                    .foregroundStyle(Color("AppTextPrimary"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer()
                IconActionButton(symbol: "xmark", tint: Color("AppTextSecondary"), action: onRemove)
            }
        }
    }
}
