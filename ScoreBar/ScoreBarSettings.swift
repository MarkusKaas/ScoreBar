import Foundation

// MARK: - GoalEvent
// One logged goal — kept in history for the recent-goals feed.
struct GoalEvent: Codable, Identifiable {
    var id         = UUID()
    let scorer:     String   // "player1" or "player2"
    let timestamp:  Date
    let p1Score:    Int      // score after this goal
    let p2Score:    Int

    static let storageKey = "sb_history"

    static func loadAll() -> [GoalEvent] {
        guard
            let data   = UserDefaults.standard.data(forKey: storageKey),
            let events = try? JSONDecoder().decode([GoalEvent].self, from: data)
        else { return [] }
        return events
    }

    static func saveAll(_ events: [GoalEvent]) {
        guard let data = try? JSONEncoder().encode(events) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}

// MARK: - AllTimeStats
// Wins-only ledger. Goals are not tracked here to avoid sync double-counting.
struct AllTimeStats: Codable {
    var player1Wins: Int = 0
    var player2Wins: Int = 0
    var totalGames:  Int = 0

    static let storageKey = "sb_stats"

    static func load() -> AllTimeStats {
        guard
            let data  = UserDefaults.standard.data(forKey: storageKey),
            let stats = try? JSONDecoder().decode(AllTimeStats.self, from: data)
        else { return AllTimeStats() }
        return stats
    }

    static func save(_ s: AllTimeStats) {
        guard let data = try? JSONEncoder().encode(s) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}

// MARK: - ScoreSettings
// All feature flags live here so every feature can be turned on/off
// independently — just flip a toggle in Settings and press Save.
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

    static func save(_ s: ScoreSettings) {
        guard let data = try? JSONEncoder().encode(s) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}
