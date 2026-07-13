import SwiftUI

struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 8
    var shakesPerUnit = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(
            CGAffineTransform(
                translationX: amount * sin(animatableData * .pi * CGFloat(shakesPerUnit)),
                y: 0
            )
        )
    }
}

extension View {
    func clearScrollBackground() -> some View {
        scrollContentBackground(.hidden)
            .background(Color.clear)
    }

    func transparentScreenChrome() -> some View {
        background(Color.clear)
    }

    func tabBarClearance(_ value: CGFloat = 96) -> some View {
        padding(.bottom, value)
    }
}
