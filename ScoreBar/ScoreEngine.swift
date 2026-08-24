import AppKit   // NSSound
import Foundation
import MultipeerConnectivity
import Observation

/// Single source of truth for the ScoreBar game state.
///
/// `ScoreEngine` uses MultipeerConnectivity to keep two Macs in sync
/// over a local Wi-Fi / peer-to-peer connection. The host that records a goal
/// is the source of truth; the peer applies the received `ScorePacket` rather than
/// re-calculating locally.
///
/// `@Observable` (Swift 5.9 macro) lets SwiftUI views subscribe directly via
/// `@Environment(ScoreEngine.self)` without wrapping in `@StateObject`/`@ObservedObject`.
/// `NSObject` inheritance is required by the `MCSession` / `MCNearbyService*` delegates.
@Observable
class ScoreEngine: NSObject {

    // MARK: - Scores & game state
    var player1Score: Int    = 0
    var player2Score: Int    = 0
    var gameWinner:   String? = nil   // "player1", "player2", or nil = in progress

    // MARK: - Connection
    var isConnected:       Bool   = false
    var connectedPeerName: String = ""

    // MARK: - Settings / History / Stats
    var settings: ScoreSettings = ScoreSettings.load()
    var history:  [GoalEvent]   = GoalEvent.loadAll()
    var stats:    AllTimeStats  = AllTimeStats.load()

    // MARK: - Multipeer
    private let serviceType = "foos-score"
    private let myPeerID:   MCPeerID
    private var session:    MCSession!
    private var advertiser: MCNearbyServiceAdvertiser!
    private var browser:    MCNearbyServiceBrowser!

    // MARK: - Init
    override init() {
        let name = Host.current().localizedName ?? "Mac"
        myPeerID = MCPeerID(displayName: name)
        super.init()

        player1Score = UserDefaults.standard.integer(forKey: "sb_player1")
        player2Score = UserDefaults.standard.integer(forKey: "sb_player2")
        gameWinner   = UserDefaults.standard.string(forKey:  "sb_winner")

        // Migrate old keys if needed (sb_markus / sb_marcus → sb_player1 / sb_player2)
        if player1Score == 0 {
            let legacyMarkus = UserDefaults.standard.integer(forKey: "sb_markus")
            if legacyMarkus > 0 { player1Score = legacyMarkus }
        }
        if player2Score == 0 {
            let legacyMarcus = UserDefaults.standard.integer(forKey: "sb_marcus")
            if legacyMarcus > 0 { player2Score = legacyMarcus }
        }

        session          = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .none)
        session.delegate = self

        advertiser          = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: nil, serviceType: serviceType)
        advertiser.delegate = self
        advertiser.startAdvertisingPeer()

        browser          = MCNearbyServiceBrowser(peer: myPeerID, serviceType: serviceType)
        browser.delegate = self
        browser.startBrowsingForPeers()

        // Pre-warm the audio subsystem in the background so the first button
        // press doesn't stall while NSSound initialises the audio stack.
        DispatchQueue.global(qos: .background).async {
            _ = NSSound(named: NSSound.Name("Pop"))
        }
    }

    // MARK: - Score actions
    func incrementPlayer1() {
        guard gameWinner == nil else { return }
        player1Score += 1
        logGoal("player1")
        checkWin(for: "player1")
        persist(); broadcast()
    }

    func decrementPlayer1() {
        guard gameWinner == nil else { return }
        player1Score = max(0, player1Score - 1)
        persist(); broadcast()
    }

    func incrementPlayer2() {
        guard gameWinner == nil else { return }
        player2Score += 1
        logGoal("player2")
        checkWin(for: "player2")
        persist(); broadcast()
    }

    func decrementPlayer2() {
        guard gameWinner == nil else { return }
        player2Score = max(0, player2Score - 1)
        persist(); broadcast()
    }

    /// Clears scores without recording a win — used for mid-game resets.
    func reset() {
        player1Score = 0; player2Score = 0; gameWinner = nil
        persist(); broadcast()
    }

    /// Records the winner in stats, then starts a fresh game.
    func newGame() {
        if let w = gameWinner {
            stats.totalGames  += 1
            if w == "player1" { stats.player1Wins += 1 }
            else              { stats.player2Wins += 1 }
            AllTimeStats.save(stats)
        }
        player1Score = 0; player2Score = 0; gameWinner = nil
        persist(); broadcast()
    }

    /// Saves and applies new settings, then broadcasts current state to the peer
    /// so it can re-evaluate display (e.g. updated player names, win score).
    func applySettings(_ newSettings: ScoreSettings) {
        settings = newSettings
        ScoreSettings.save(newSettings)
        broadcast()
    }

    /// Clears the local goal-event history. Does not affect all-time win records.
    func clearHistory() {
        history = []
        GoalEvent.saveAll([])
    }

    /// Resets the all-time wins ledger to zero. Does not affect current-game scores.
    func clearStats() {
        stats = AllTimeStats()
        AllTimeStats.save(stats)
    }

    // MARK: - Win detection

    /// Checks whether `scorer` has reached `settings.winScore` and updates `gameWinner`.
    /// Plays the win or goal sound depending on the outcome.
    private func checkWin(for scorer: String) {
        guard settings.winDetectionEnabled else {
            playSound(settings.goalSound)
            return
        }
        let score = scorer == "player1" ? player1Score : player2Score
        if score >= settings.winScore {
            gameWinner = scorer
            playSound(settings.winSound)
        } else {
            playSound(settings.goalSound)
        }
    }

    // MARK: - History
    /// Logs a goal to local history (newest first, capped at 50).
    private func logGoal(_ scorer: String) {
        let event = GoalEvent(scorer: scorer,
                              timestamp: Date(),
                              p1Score: player1Score,
                              p2Score: player2Score)
        history.insert(event, at: 0)
        if history.count > 50 { history = Array(history.prefix(50)) }
        GoalEvent.saveAll(history)
    }

    // MARK: - Sound
    func playSound(_ name: String) {
        guard settings.soundEffectsEnabled, !name.isEmpty, name != "none" else { return }
        NSSound(named: NSSound.Name(name))?.play()
    }

    // MARK: - Persistence

    /// Writes current scores and winner to `UserDefaults` for crash/relaunch recovery.
    private func persist() {
        UserDefaults.standard.set(player1Score, forKey: "sb_player1")
        UserDefaults.standard.set(player2Score, forKey: "sb_player2")
        if let w = gameWinner {
            UserDefaults.standard.set(w, forKey: "sb_winner")
        } else {
            UserDefaults.standard.removeObject(forKey: "sb_winner")
        }
    }

    // MARK: - Multipeer broadcast

    /// Encodes current score state into a `ScorePacket` and sends it reliably to all
    /// connected peers. No-ops when no peers are connected.
    private func broadcast() {
        guard !session.connectedPeers.isEmpty else { return }
        let packet = ScorePacket(player1: player1Score, player2: player2Score, winner: gameWinner)
        guard let data = try? JSONEncoder().encode(packet) else { return }
        try? session.send(data, toPeers: session.connectedPeers, with: .reliable)
    }
}

// MARK: - Network packet

/// Minimal payload sent over MultipeerConnectivity on every score change.
/// The receiving Mac applies these values directly — it does not independently
/// validate them against `winScore` to avoid any drift between devices.
private struct ScorePacket: Codable {
    let player1: Int
    let player2: Int
    /// `"player1"`, `"player2"`, or `nil` if the game is still in progress.
    let winner:  String?
}

// MARK: - MCSessionDelegate
extension ScoreEngine: MCSessionDelegate {

    nonisolated func session(_ session: MCSession, peer peerID: MCPeerID,
                             didChange state: MCSessionState) {
        Task { @MainActor in
            self.isConnected       = !session.connectedPeers.isEmpty
            self.connectedPeerName = session.connectedPeers.first?.displayName ?? ""
        }
    }

    nonisolated func session(_ session: MCSession, didReceive data: Data,
                             fromPeer peerID: MCPeerID) {
        guard let packet = try? JSONDecoder().decode(ScorePacket.self, from: data) else { return }
        Task { @MainActor in
            let prevP1 = self.player1Score
            let prevP2 = self.player2Score

            self.player1Score = packet.player1
            self.player2Score = packet.player2

            // Log goal events for history display (source of truth is sender)
            if packet.player1 > prevP1 { self.logGoal("player1") }
            else if packet.player2 > prevP2 { self.logGoal("player2") }

            // Apply win state — don't re-record stats (newGame() handles that)
            if self.gameWinner == nil, let winner = packet.winner {
                self.gameWinner = winner
                self.playSound(self.settings.winSound)
            } else if packet.winner == nil {
                self.gameWinner = nil   // peer started a new game
            }

            self.persist()
        }
    }

    nonisolated func session(_ session: MCSession, didReceive stream: InputStream,
                             withName streamName: String, fromPeer peerID: MCPeerID) {}
    nonisolated func session(_ session: MCSession,
                             didStartReceivingResourceWithName resourceName: String,
                             fromPeer peerID: MCPeerID, with progress: Progress) {}
    nonisolated func session(_ session: MCSession,
                             didFinishReceivingResourceWithName resourceName: String,
                             fromPeer peerID: MCPeerID, at localURL: URL?,
                             withError error: Error?) {}
}

// MARK: - MCNearbyServiceAdvertiserDelegate
extension ScoreEngine: MCNearbyServiceAdvertiserDelegate {
    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser,
                                didReceiveInvitationFromPeer peerID: MCPeerID,
                                withContext context: Data?,
                                invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        invitationHandler(true, session)
    }
}

// MARK: - MCNearbyServiceBrowserDelegate
extension ScoreEngine: MCNearbyServiceBrowserDelegate {
    nonisolated func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID,
                             withDiscoveryInfo info: [String: String]?) {
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
    }
    nonisolated func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {}
}
