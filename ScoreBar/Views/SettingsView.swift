import AppKit
import SwiftUI

/// Settings panel that slides up from the bottom of the popover.
///
/// All controls mirror the current `ScoreSettings` in local `@State`.
/// Changes are only committed to the engine when the user taps **Save**,
/// so back-navigation without saving discards edits cleanly.
struct SettingsView: View {
    @Environment(ScoreEngine.self) var engine
    @Binding var show: Bool

    // MARK: - Local state
    @State private var player1Name:             String = "Markus"
    @State private var player2Name:             String = "Marcus"
    @State private var winScore:                Double = 10
    @State private var winDetectionEnabled:     Bool   = true
    @State private var matchHistoryEnabled:     Bool   = true
    @State private var allTimeStatsEnabled:     Bool   = true
    @State private var soundEffectsEnabled:     Bool   = true
    @State private var goalSound:               String = "Pop"
    @State private var winSound:                String = "Glass"
    @State private var resetConfirmEnabled:     Bool   = true
    @State private var fullScreenConfettiEnabled: Bool = true

    var body: some View {
        VStack(spacing: 0) {

            // ── Header ────────────────────────────────────────────────────
            HStack {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { show = false }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 11, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 13))
                    }
                    .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)

                Spacer()
                Text("Settings").font(.system(size: 13, weight: .semibold))
                Spacer()
                Color.clear.frame(width: 48, height: 1)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Divider()

            ScrollView {
                VStack(spacing: 18) {

                    // ── Player names ──────────────────────────────────────
                    sectionLabel("Player Names")
                    VStack(spacing: 10) {
                        HStack(spacing: 10) {
                            Circle().fill(Color.red).frame(width: 8, height: 8)
                            Text("Player 1")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            Spacer()
                            TextField("Name", text: $player1Name)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(size: 12))
                                .frame(width: 120)
                        }
                        HStack(spacing: 10) {
                            Circle().fill(Color.blue).frame(width: 8, height: 8)
                            Text("Player 2")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            Spacer()
                            TextField("Name", text: $player2Name)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(size: 12))
                                .frame(width: 120)
                        }
                    }

                    Divider()

                    // ── Game rules ────────────────────────────────────────
                    sectionLabel("Game Rules")

                    featureToggle(
                        isOn: $winDetectionEnabled,
                        icon: "trophy.fill",
                        title: "Win detection",
                        subtitle: "Declare a winner at a set score"
                    )

                    if winDetectionEnabled {
                        VStack(spacing: 6) {
                            HStack {
                                Text("First to \(Int(winScore)) goals")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                Spacer()
                                Stepper("", value: $winScore, in: 3...50, step: 1)
                                    .labelsHidden()
                            }
                            // Quick presets
                            HStack(spacing: 6) {
                                ForEach([3, 5, 7, 10, 15, 21], id: \.self) { n in
                                    Button("\(n)") { winScore = Double(n) }
                                        .buttonStyle(.plain)
                                        .font(.system(size: 11, weight: winScore == Double(n) ? .bold : .regular))
                                        .foregroundColor(winScore == Double(n) ? .white : .secondary)
                                        .frame(width: 30, height: 22)
                                        .background(winScore == Double(n) ? Color.indigo : Color(nsColor: .controlBackgroundColor))
                                        .clipShape(RoundedRectangle(cornerRadius: 5))
                                }
                            }
                        }
                        .padding(.leading, 28)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    Divider()

                    // ── Features ──────────────────────────────────────────
                    sectionLabel("Features")

                    featureToggle(
                        isOn: $matchHistoryEnabled,
                        icon: "clock.fill",
                        title: "Match history",
                        subtitle: "Show the last 5 goals below the table"
                    )

                    featureToggle(
                        isOn: $allTimeStatsEnabled,
                        icon: "chart.bar.fill",
                        title: "All-time record",
                        subtitle: "Track wins across all completed games"
                    )

                    featureToggle(
                        isOn: $resetConfirmEnabled,
                        icon: "exclamationmark.triangle.fill",
                        title: "Reset confirmation",
                        subtitle: "Ask before clearing the score mid-game"
                    )

                    featureToggle(
                        isOn: $fullScreenConfettiEnabled,
                        icon: "sparkles",
                        title: "Full-screen celebration",
                        subtitle: "Big confetti on both Macs when \(player1Name) scores"
                    )

                    Divider()

                    // ── Sound effects ─────────────────────────────────────
                    sectionLabel("Sound Effects")

                    featureToggle(
                        isOn: $soundEffectsEnabled,
                        icon: "speaker.wave.2.fill",
                        title: "Sound effects",
                        subtitle: "Play sounds on goals and wins"
                    )

                    if soundEffectsEnabled {
                        VStack(spacing: 10) {
                            soundRow(label: "Goal sound", selection: $goalSound,
                                     options: ["Pop", "Ping", "Blow", "Bottle", "Funk", "Morse"])

                            soundRow(label: "Win sound",  selection: $winSound,
                                     options: ["Glass", "Hero", "Purr", "Sosumi", "Submarine", "Ping"])
                        }
                        .padding(.leading, 28)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    Divider()

                    // ── Save ──────────────────────────────────────────────
                    Button {
                        engine.applySettings(ScoreSettings(
                            player1Name:             player1Name,
                            player2Name:             player2Name,
                            winScore:                Int(winScore),
                            winDetectionEnabled:     winDetectionEnabled,
                            matchHistoryEnabled:     matchHistoryEnabled,
                            allTimeStatsEnabled:     allTimeStatsEnabled,
                            soundEffectsEnabled:     soundEffectsEnabled,
                            goalSound:               goalSound,
                            winSound:                winSound,
                            resetConfirmEnabled:     resetConfirmEnabled,
                            fullScreenConfettiEnabled: fullScreenConfettiEnabled
                        ))
                        withAnimation(.easeInOut(duration: 0.2)) { show = false }
                    } label: {
                        Text("Save")
                            .font(.system(size: 14, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.indigo)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)

                    // ── Danger zone ───────────────────────────────────────
                    HStack(spacing: 20) {
                        Button("Clear history") { engine.clearHistory() }
                            .buttonStyle(.plain)
                            .font(.system(size: 11))
                            .foregroundColor(.red.opacity(0.7))
                        Button("Reset records") { engine.clearStats() }
                            .buttonStyle(.plain)
                            .font(.system(size: 11))
                            .foregroundColor(.red.opacity(0.7))
                    }
                }
                .padding(16)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.regularMaterial)
        .animation(.easeInOut(duration: 0.2), value: winDetectionEnabled)
        .animation(.easeInOut(duration: 0.2), value: soundEffectsEnabled)
        .onAppear {
            let s = engine.settings
            player1Name              = s.player1Name
            player2Name              = s.player2Name
            winScore                 = Double(s.winScore)
            winDetectionEnabled      = s.winDetectionEnabled
            matchHistoryEnabled      = s.matchHistoryEnabled
            allTimeStatsEnabled      = s.allTimeStatsEnabled
            soundEffectsEnabled      = s.soundEffectsEnabled
            goalSound                = s.goalSound
            winSound                 = s.winSound
            resetConfirmEnabled      = s.resetConfirmEnabled
            fullScreenConfettiEnabled = s.fullScreenConfettiEnabled
        }
    }

    // MARK: - Helpers

    /// Styled uppercase section header used throughout the settings scroll view.
    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(.secondary)
            .textCase(.uppercase)
            .tracking(1.5)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Consistent icon + title + subtitle toggle row used for every optional feature.
    @ViewBuilder
    private func featureToggle(isOn: Binding<Bool>, icon: String,
                               title: String, subtitle: String) -> some View {
        Toggle(isOn: isOn) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .frame(width: 18)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.system(size: 13))
                    Text(subtitle).font(.system(size: 10)).foregroundColor(.secondary)
                }
            }
        }
        .toggleStyle(.switch)
    }

    /// Labelled picker row with an inline play button to preview the selected sound.
    @ViewBuilder
    private func soundRow(label: String, selection: Binding<String>, options: [String]) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .frame(width: 78, alignment: .leading)
            Picker("", selection: selection) {
                ForEach(options, id: \.self) { name in
                    Text(name).tag(name)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .frame(maxWidth: .infinity)

            // Preview button
            Button {
                NSSound(named: NSSound.Name(selection.wrappedValue))?.play()
            } label: {
                Image(systemName: "play.circle")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
    }
}
