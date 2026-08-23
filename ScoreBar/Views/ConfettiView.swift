import SwiftUI

/// Inline confetti burst layered over the score popover.
///
/// Particles spray from the centre of the 300 pt popover and fade out over ~1.1 s.
/// Hit-testing is disabled so the overlay never intercepts button taps.
/// Increment `trigger` from the outside to start a new burst.
struct ConfettiView: View {

    /// Increment this value to fire a new confetti burst.
    var trigger: Int

    // MARK: - State

    @State private var particles: [Particle] = []
    @State private var animating = false

    // MARK: - Particle model

    private let colors: [Color] = [
        .red, .orange, .yellow, .green, .blue, .purple, .pink, .cyan
    ]

    private struct Particle: Identifiable {
        let id       = UUID()
        let color:    Color
        let endX:     CGFloat
        let endY:     CGFloat
        let rotation: Double
        let width:    CGFloat
        let height:   CGFloat
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            ForEach(particles) { p in
                RoundedRectangle(cornerRadius: 2)
                    .fill(p.color)
                    .frame(width: p.width, height: p.height)
                    .position(
                        x: animating ? p.endX : 150,  // 150 pt = centre of 300 pt popover
                        y: animating ? p.endY : 60
                    )
                    .rotationEffect(.degrees(animating ? p.rotation : 0))
                    .opacity(animating ? 0 : 0.92)
            }
        }
        .allowsHitTesting(false)  // clicks pass through to buttons below
        .onChange(of: trigger) { _, _ in fire() }
    }

    // MARK: - Animation

    /// Spawns 45 random particles, animates them outward with easeOut, then clears them.
    private func fire() {
        particles = (0..<45).map { _ in
            Particle(
                color:    colors.randomElement()!,
                endX:     CGFloat.random(in: 15...285),
                endY:     CGFloat.random(in: 70...360),
                rotation: Double.random(in: -450...450),
                width:    CGFloat.random(in: 6...14),
                height:   CGFloat.random(in: 3...7)
            )
        }
        animating = false

        withAnimation(.easeOut(duration: 1.1)) {
            animating = true
        }

        Task {
            try? await Task.sleep(for: .seconds(1.4))
            particles = []
            animating = false
        }
    }
}
