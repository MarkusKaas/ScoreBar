import AppKit
import SwiftUI

// MARK: - FullScreenConfettiPanel

/// Singleton that creates a borderless, click-through `NSPanel` covering the main screen
/// and fills it with animated confetti for ~2 seconds.
///
/// The panel sits at `.screenSaver` window level so it appears above all other windows,
/// including the menu-bar popover that triggered it.
final class FullScreenConfettiPanel {
    static let shared = FullScreenConfettiPanel()
    private var panel: NSPanel?

    /// Shows the full-screen confetti panel. No-ops if a panel is already on screen.
    func show() {
        guard panel == nil else { return }  // prevent stacking multiple panels

        let screen = NSScreen.main ?? NSScreen.screens[0]
        let frame  = screen.frame

        let p = NSPanel(
            contentRect: frame,
            styleMask:   [.borderless, .nonactivatingPanel],
            backing:     .buffered,
            defer:       false
        )
        p.level                = .screenSaver   // above everything
        p.backgroundColor      = .clear
        p.isOpaque             = false
        p.hasShadow            = false
        p.ignoresMouseEvents   = true           // clicks pass through
        p.collectionBehavior   = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let host = NSHostingView(rootView: FullScreenConfettiView(size: frame.size))
        host.frame = CGRect(origin: .zero, size: frame.size)
        host.wantsLayer = true
        host.layer?.backgroundColor = .clear
        p.contentView = host

        p.orderFront(nil)
        panel = p

        Task {
            try? await Task.sleep(for: .seconds(2.2))
            self.panel?.close()
            self.panel = nil
        }
    }
}

// MARK: - FullScreenConfettiView

/// Full-screen SwiftUI view that animates 150 confetti particles launched
/// from three evenly-spaced horizontal positions across the screen.
private struct FullScreenConfettiView: View {
    let size: CGSize

    @State private var particles: [Particle] = []
    @State private var animating = false

    private let colors: [Color] = [
        .red, .orange, .yellow, .green, .blue, .purple, .pink, .cyan, .white
    ]

    private struct Particle: Identifiable {
        let id       = UUID()
        let color:    Color
        let startX:   CGFloat
        let startY:   CGFloat
        let endX:     CGFloat
        let endY:     CGFloat
        let rotation: Double
        let width:    CGFloat
        let height:   CGFloat
        let delay:    Double
    }

    var body: some View {
        ZStack {
            ForEach(particles) { p in
                RoundedRectangle(cornerRadius: 2)
                    .fill(p.color)
                    .frame(width: p.width, height: p.height)
                    .position(
                        x: animating ? p.endX   : p.startX,
                        y: animating ? p.endY   : p.startY
                    )
                    .rotationEffect(.degrees(animating ? p.rotation : 0))
                    .opacity(animating ? 0 : 0.9)
                    .animation(
                        .easeOut(duration: 1.6).delay(p.delay),
                        value: animating
                    )
            }
        }
        .frame(width: size.width, height: size.height)
        .onAppear { launch() }
    }

    /// Spawns 150 particles in three bursts (left, centre, right),
    /// then triggers the animation after a 30 ms mount delay.
    private func launch() {
        let w = size.width
        let h = size.height

        let origins: [CGFloat] = [w * 0.25, w * 0.50, w * 0.75]

        particles = (0..<150).map { i in
            let origin = origins[i % origins.count]
            return Particle(
                color:    colors.randomElement()!,
                startX:   origin + CGFloat.random(in: -30...30),
                startY:   h * CGFloat.random(in: 0.0...0.1),
                endX:     CGFloat.random(in: 40...(w - 40)),
                endY:     CGFloat.random(in: h * 0.15...h * 0.92),
                rotation: Double.random(in: -720...720),
                width:    CGFloat.random(in: 8...22),
                height:   CGFloat.random(in: 4...10),
                delay:    Double.random(in: 0...0.15)
            )
        }

        // Small delay so the view is mounted before animating
        Task {
            try? await Task.sleep(for: .milliseconds(30))
            animating = true
        }
    }
}
