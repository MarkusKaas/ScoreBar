import Foundation

// MARK: - GoalEvent

/// A single scored goal, persisted in the recent-goals history feed.
struct GoalEvent: Codable, Identifiable {
    var id        = UUID()
    /// `"player1"` or `"player2"`.
    let scorer:    String
    let timestamp: Date
    /// Score for player 1 **after** this goal was recorded.
    let p1Score:   Int
    /// Score for player 2 **after** this goal was recorded.
    let p2Score:   Int

    static let storageKey = "sb_history"

    /// Loads all persisted goal events from `UserDefaults`, or returns `[]` on failure.
    static func loadAll() -> [GoalEvent] {
        guard
            let data   = UserDefaults.standard.data(forKey: storageKey),
            let events = try? JSONDecoder().decode([GoalEvent].self, from: data)
        else { return [] }
        return events
    }

    /// Encodes and writes `events` to `UserDefaults`. Silently no-ops on encode failure.
    static func saveAll(_ events: [GoalEvent]) {
        guard let data = try? JSONEncoder().encode(events) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}

// MARK: - AllTimeStats

/// Wins-only ledger, persisted independently from per-game history.
///
/// Goals are intentionally **not** accumulated here to avoid double-counting
/// when the peer Mac also receives and stores the same goal events.
struct AllTimeStats: Codable {
    var player1Wins: Int = 0
    var player2Wins: Int = 0
    var totalGames:  Int = 0

    static let storageKey = "sb_stats"

    /// Loads persisted all-time stats from `UserDefaults`, or returns zeroed defaults.
    static func load() -> AllTimeStats {
        guard
            let data  = UserDefaults.standard.data(forKey: storageKey),
            let stats = try? JSONDecoder().decode(AllTimeStats.self, from: data)
        else { return AllTimeStats() }
        return stats
    }

    /// Encodes and writes `stats` to `UserDefaults`. Silently no-ops on encode failure.
    static func save(_ stats: AllTimeStats) {
        guard let data = try? JSONEncoder().encode(stats) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}

// MARK: - ScoreSettings

/// All user-configurable preferences for ScoreBar.
///
/// Stored as a single JSON blob in `UserDefaults`. Every feature is independently
/// togglable — flip a switch in `SettingsView` and press **Save**.
/// Adding new optional properties with default values keeps this Codable-backward-compatible.
struct ScoreSettings: Codable {

    // ── Player identity ───────────────────────────────────────────────────
    var player1Name: String = "Markus"
    var player2Name: String = "Marcus"

    // ── Game rules ────────────────────────────────────────────────────────
    /// Declare a winner when a player reaches this score.
    var winScore:            Int  = 10
    var winDetectionEnabled: Bool = true

    // ── Features ──────────────────────────────────────────────────────────
    /// Show the last 5 goals below the foosball table.
    var matchHistoryEnabled:       Bool   = true

    /// Show the all-time wins record at the bottom of the popover.
    var allTimeStatsEnabled:       Bool   = true

    /// Play a sound on each goal and on winning.
    var soundEffectsEnabled:       Bool   = true
    var goalSound:                 String = "Pop"    // NSSound name
    var winSound:                  String = "Glass"  // NSSound name

    /// Ask for confirmation before resetting the score mid-game.
    var resetConfirmEnabled:       Bool   = true

    /// Full-screen confetti on both Macs when Player 1 scores.
    var fullScreenConfettiEnabled: Bool   = true

    static let storageKey = "sb_settings"

    static func load() -> ScoreSettings {
        guard
            let data = UserDefaults.standard.data(forKey: storageKey),
            let s    = try? JSONDecoder().decode(ScoreSettings.self, from: data)
        else { return ScoreSettings() }
        return s
    }

    /// Encodes and writes `settings` to `UserDefaults`. Silently no-ops on encode failure.
    static func save(_ settings: ScoreSettings) {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}
