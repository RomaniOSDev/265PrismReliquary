import SwiftUI

/// Lightweight depth tokens — one shadow max per surface, no blur.
enum DepthStyle {
    case flat
    case raised
    case floating

    var shadowRadius: CGFloat {
        switch self {
        case .flat: return 0
        case .raised: return 10
        case .floating: return 16
        }
    }

    var shadowY: CGFloat {
        switch self {
        case .flat: return 0
        case .raised: return 6
        case .floating: return 10
        }
    }

    var shadowOpacity: Double {
        switch self {
        case .flat: return 0
        case .raised: return 0.22
        case .floating: return 0.28
        }
    }
}

struct SoftShadowModifier: ViewModifier {
    let style: DepthStyle

    func body(content: Content) -> some View {
        if style == .flat {
            content
        } else {
            content.shadow(
                color: Color.black.opacity(style.shadowOpacity),
                radius: style.shadowRadius,
                x: 0,
                y: style.shadowY
            )
        }
    }
}

struct CardChromeModifier: ViewModifier {
    let cornerRadius: CGFloat
    let depth: DepthStyle
    let gloss: Bool

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(cardFill)
                    .overlay(highlightStroke)
                    .overlay(alignment: .top) {
                        if gloss {
                            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                .fill(glossOverlay)
                                .frame(height: 28)
                                .allowsHitTesting(false)
                        }
                    }
            )
            .modifier(SoftShadowModifier(style: depth))
    }

    private var cardFill: LinearGradient {
        LinearGradient(
            colors: [
                Color("AppSurface").opacity(0.98),
                Color("AppPrimary").opacity(0.22)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var glossOverlay: LinearGradient {
        LinearGradient(
            colors: [
                Color("AppTextPrimary").opacity(0.10),
                Color("AppTextPrimary").opacity(0.0)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var highlightStroke: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .stroke(
                LinearGradient(
                    colors: [
                        Color("AppAccent").opacity(0.45),
                        Color("AppPrimary").opacity(0.15),
                        Color("AppAccent").opacity(0.20)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
    }
}

extension View {
    func softShadow(_ style: DepthStyle = .raised) -> some View {
        modifier(SoftShadowModifier(style: style))
    }

    func cardChrome(cornerRadius: CGFloat = 18, depth: DepthStyle = .raised, gloss: Bool = true) -> some View {
        modifier(CardChromeModifier(cornerRadius: cornerRadius, depth: depth, gloss: gloss))
    }

    func pressableScale(_ pressed: Bool) -> some View {
        scaleEffect(pressed ? 0.97 : 1)
            .animation(.easeInOut(duration: 0.15), value: pressed)
    }
}
