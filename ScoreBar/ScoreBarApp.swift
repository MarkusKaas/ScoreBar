import SwiftUI

@main
struct ScoreBarApp: App {
    @State private var engine = ScoreEngine()

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
            // Full-screen confetti fires on both Macs when Player 1 scores
            if new > old && engine.settings.fullScreenConfettiEnabled {
                FullScreenConfettiPanel.shared.show()
            }
        }
    }

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
