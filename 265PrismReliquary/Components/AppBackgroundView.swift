import SwiftUI

/// Static layered gradients only — no Canvas, no blur, no animation.
struct AppBackgroundView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color("AppBackground"),
                    Color("AppSurface"),
                    Color("AppBackground")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Soft volume blobs (cheap vector fills)
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            Color("AppAccent").opacity(0.28),
                            Color("AppAccent").opacity(0.0)
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 220
                    )
                )
                .frame(width: 340, height: 280)
                .offset(x: -110, y: -260)
                .allowsHitTesting(false)

            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            Color("AppPrimary").opacity(0.22),
                            Color("AppPrimary").opacity(0.0)
                        ],
                        center: .center,
                        startRadius: 8,
                        endRadius: 200
                    )
                )
                .frame(width: 300, height: 260)
                .offset(x: 140, y: 280)
                .allowsHitTesting(false)

            // Subtle top sheen
            LinearGradient(
                colors: [
                    Color("AppTextPrimary").opacity(0.08),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .center
            )
            .allowsHitTesting(false)
        }
        .ignoresSafeArea()
    }
}
