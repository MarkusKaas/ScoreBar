import SwiftUI

/// Root content of the ScoreBar menu-bar popover.
///
/// Sections (top to bottom): header row → score/win panel → foosball table →
/// optional match history → optional all-time stats → reset/quit buttons.
///
/// A `ConfettiView` overlay fires on every goal. The `SettingsView` slides up
/// from the bottom as a `ZStack` overlay when the gear icon is tapped.
struct PopoverView: View {
    @Environment(ScoreEngine.self) var engine
    @State private var confettiTrigger = 0
    @State private var showSettings    = false
    @State private var showResetAlert  = false

    var body: some View {
        ZStack {
            // ── Main content ─────────────────────────────────────────────
            VStack(spacing: 0) {
                headerRow
                Divider()
                scoreSection
                Divider()
                foosballSection
                if engine.settings.matchHistoryEnabled && !engine.history.isEmpty {
                    Divider()
                    historySection
                }
                if engine.settings.allTimeStatsEnabled {
                    Divider()
                    allTimeStatsRow
                }
                Divider()
                bottomButtons
            }
            .background(.regularMaterial)
            .overlay { ConfettiView(trigger: confettiTrigger) }

            // ── Settings overlay ─────────────────────────────────────────
            if showSettings {
                SettingsView(show: $showSettings)
                    .environment(engine)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(1)
            }
        }
        .onChange(of: engine.player1Score) { old, new in
            if new > old { confettiTrigger += 1 }
        }
        .onChange(of: engine.player2Score) { old, new in
            if new > old { confettiTrigger += 1 }
        }
        .alert("Reset Score?", isPresented: $showResetAlert) {
            Button("Reset", role: .destructive) { engine.reset() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will clear both scores and cannot be undone.")
        }
    }

    // MARK: - Header
    private var headerRow: some View {
        HStack {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { showSettings = true }
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)

            Spacer()

            Text("⚽ ScoreBar")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)

            Spacer()

            HStack(spacing: 4) {
                Circle()
                    .fill(engine.isConnected ? Color.green : Color.orange)
                    .frame(width: 6, height: 6)
                Text(engine.isConnected ? engine.connectedPeerName : "Looking…")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - Score / Win section
    @ViewBuilder
    private var scoreSection: some View {
        if let winner = engine.gameWinner {
            winBanner(winner: winner)
        } else {
            HStack(spacing: 0) {
                PlayerColumn(
                    name: engine.settings.player1Name,
                    score: engine.player1Score,
                    color: .red,
                    targetScore: engine.settings.winDetectionEnabled ? engine.settings.winScore : nil,
                    onIncrement: { engine.incrementPlayer1() },
                    onDecrement: { engine.decrementPlayer1() }
                )

                Text("–")
                    .font(.system(size: 44, weight: .black))
                    .foregroundColor(.secondary)
                    .frame(width: 36)

                PlayerColumn(
                    name: engine.settings.player2Name,
                    score: engine.player2Score,
                    color: .blue,
                    targetScore: engine.settings.winDetectionEnabled ? engine.settings.winScore : nil,
                    onIncrement: { engine.incrementPlayer2() },
                    onDecrement: { engine.decrementPlayer2() }
                )
            }
            .padding(.vertical, 16)
        }
    }

    // MARK: - Win banner
    private func winBanner(winner: String) -> some View {
        let name:  String = winner == "player1" ? engine.settings.player1Name : engine.settings.player2Name
        let color: Color  = winner == "player1" ? .red : .blue

        return VStack(spacing: 10) {
            Text("🏆").font(.system(size: 48))
            Text("\(name) wins!")
                .font(.system(size: 24, weight: .black))
                .foregroundColor(color)
            HStack(spacing: 24) {
                VStack(spacing: 2) {
                    Text("\(engine.player1Score)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                    Text(engine.settings.player1Name)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                Text("–")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.secondary)
                VStack(spacing: 2) {
                    Text("\(engine.player2Score)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                    Text(engine.settings.player2Name)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            Button { engine.newGame() } label: {
                Label("New Game", systemImage: "arrow.counterclockwise")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(color)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Foosball table
    private var foosballSection: some View {
        FoosballView()
            .frame(height: 110)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
    }

    // MARK: - Match history (last 5 goals)
    private var historySection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Recent Goals")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .tracking(1.0)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 4)

            ForEach(engine.history.prefix(5)) { event in
                HStack(spacing: 8) {
                    Circle()
                        .fill(event.scorer == "player1" ? Color.red : Color.blue)
                        .frame(width: 5, height: 5)
                    Text(event.scorer == "player1"
                         ? engine.settings.player1Name
                         : engine.settings.player2Name)
                        .font(.system(size: 12, weight: .semibold))
                    Text("scored")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(event.p1Score) – \(event.p2Score)")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.secondary)
                    Text(event.timestamp, style: .relative)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .frame(width: 54, alignment: .trailing)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
            }
            .padding(.bottom, 6)
        }
    }

    // MARK: - All-time stats
    private var allTimeStatsRow: some View {
        HStack(spacing: 0) {
            statCell(value: "\(engine.stats.player1Wins)",
                     label: "\(engine.settings.player1Name) wins",
                     color: .red)
            Divider()
            statCell(value: "\(engine.stats.totalGames)",
                     label: "Games",
                     color: Color(.secondaryLabelColor))
            Divider()
            statCell(value: "\(engine.stats.player2Wins)",
                     label: "\(engine.settings.player2Name) wins",
                     color: .blue)
        }
        .frame(height: 48)
    }

    private func statCell(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 9))
                .foregroundColor(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Bottom buttons
    private var bottomButtons: some View {
        HStack(spacing: 0) {
            if engine.gameWinner == nil {
                Button {
                    if engine.settings.resetConfirmEnabled {
                        showResetAlert = true
                    } else {
                        engine.reset()
                    }
                } label: {
                    Text("Reset")
                        .font(.system(size: 12))
                        .foregroundColor(.red.opacity(0.8))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.plain)

                Divider().frame(height: 20)
            }

            Button { NSApplication.shared.terminate(nil) } label: {
                Text("Quit")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - PlayerColumn

/// Vertical stack showing a player's name, score, optional win-progress bar, and ±1 buttons.
private struct PlayerColumn: View {
    let name:        String
    let score:       Int
    let color:       Color
    /// Winning score threshold. `nil` when win detection is disabled.
    let targetScore: Int?
    let onIncrement: () -> Void
    let onDecrement: () -> Void

    var body: some View {
        VStack(spacing: 6) {
            Text(name)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(color)

            Text("\(score)")
                .font(.system(size: 52, weight: .black, design: .rounded))
                .foregroundColor(.primary)
                .frame(minWidth: 60)
                .contentTransition(.numericText())
                .animation(.spring(response: 0.3), value: score)

            // Progress bar toward win score
            if let target = targetScore, target > 0 {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(color.opacity(0.15))
                            .frame(height: 3)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(color)
                            .frame(width: geo.size.width * min(1, Double(score) / Double(target)),
                                   height: 3)
                            .animation(.easeOut(duration: 0.3), value: score)
                    }
                }
                .frame(height: 3)
                .padding(.horizontal, 12)
            }

            HStack(spacing: 8) {
                ScoreButton(label: "–", bg: color.opacity(0.12),
                            fg: color,  action: onDecrement)
                ScoreButton(label: "+", bg: color,
                            fg: .white, action: onIncrement)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - ScoreButton

/// Rounded square button used for the `+` and `–` score actions in each `PlayerColumn`.
private struct ScoreButton: View {
    let label:  String
    let bg:     Color
    let fg:     Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 20, weight: .bold))
                .frame(width: 38, height: 38)
                .background(bg)
                .foregroundColor(fg)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}
