import SwiftUI

/// Menu-bar entry point for ScoreBar.
///
/// Hosts a single `MenuBarExtra` whose label shows the live score and whose
/// popover content is `PopoverView`. A full-screen confetti panel fires on both
/// Macs whenever Player 1 scores (opt-in via `ScoreSettings.fullScreenConfettiEnabled`).
@main
struct ScoreBarApp: App {

    // MARK: - State

    @State private var engine = ScoreEngine()

    // MARK: - Scene

    var body: some Scene {
        MenuBarExtra {
            PopoverView()
                .environment(engine)
                .frame(width: 300)
        } label: {
            menuBarLabel
        }
        .menuBarExtraStyle(.window)
        .onChange(of: engine.player1Score) { old, new in
            // Full-screen confetti fires on both Macs when Player 1 scores.
            if new > old && engine.settings.fullScreenConfettiEnabled {
                FullScreenConfettiPanel.shared.show()
            }
        }
    }

    // MARK: - Menu Bar Label

    /// Compact score label shown in the system menu bar.
    /// Shows a trophy emoji when the game has a winner.
    @ViewBuilder
    private var menuBarLabel: some View {
        if engine.gameWinner != nil {
            HStack(spacing: 3) {
                Text("🏆")
                Text("\(engine.player1Score)–\(engine.player2Score)")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
            }
        } else {
            Text("⚽ \(engine.player1Score) – \(engine.player2Score)")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
        }
    }
}
