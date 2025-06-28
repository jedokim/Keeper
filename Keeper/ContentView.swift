import SwiftData

enum PlayerAction: String {
    case rebound = "Rebound"
    case shotAttempt = "Shot Attempt"
    case shotMade = "Shot Made"
    case steal = "Steal"
    case turnover = "Turnover"
    case assist = "Assist"
}

import SwiftUI

@Model
class PlayerStats: Identifiable {
    var id: UUID
    var name: String
    var points: Int
    var rebounds: Int
    var assists: Int
    var steals: Int
    var turnovers: Int
    var shotsMade: Int
    var shotsAttempted: Int

    init(id: UUID = UUID(), name: String, points: Int = 0, rebounds: Int = 0, assists: Int = 0, steals: Int = 0, turnovers: Int = 0, shotsMade: Int = 0, shotsAttempted: Int = 0) {
        self.id = id
        self.name = name
        self.points = points
        self.rebounds = rebounds
        self.assists = assists
        self.steals = steals
        self.turnovers = turnovers
        self.shotsMade = shotsMade
        self.shotsAttempted = shotsAttempted
    }

    var fieldGoalPercentage: Double {
        shotsAttempted == 0 ? 0 : (Double(shotsMade) / Double(shotsAttempted)) * 100
    }
}

class Team: ObservableObject {
    @Published var players: [PlayerStats]

    init(players: [PlayerStats] = []) {
        self.players = players
    }
}

struct ContentView: View {
    @Query private var allPlayers: [PlayerStats]
    @Environment(\.modelContext) private var modelContext

    @StateObject private var teamA = Team()
    @StateObject private var teamB = Team()
    @State private var selectedPlayer: PlayerStats?
    @State private var showingGestureMenu = false

    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    TeamView(team: teamA, title: "Team A", onSelect: handlePlayerSelect)
                    TeamView(team: teamB, title: "Team B", onSelect: handlePlayerSelect)
                }
                .onAppear {
                    if allPlayers.isEmpty {
                        let teamAPlayers = (1...5).map { PlayerStats(name: "Player \($0)") }
                        let teamBPlayers = (1...5).map { PlayerStats(name: "Player \($0+5)") }
                        teamA.players = teamAPlayers
                        teamB.players = teamBPlayers
                        (teamAPlayers + teamBPlayers).forEach { modelContext.insert($0) }
                    } else {
                        let mid = allPlayers.count / 2
                        teamA.players = Array(allPlayers.prefix(mid))
                        teamB.players = Array(allPlayers.suffix(from: mid))
                    }
                }
                .sheet(isPresented: $showingGestureMenu) {
                    if let player = selectedPlayer {
                        GestureMenuView(player: player) { updatedPlayer in
                            updatePlayerStats(updatedPlayer)
                            showingGestureMenu = false
                        }
                    }
                }
            }
            .navigationTitle("Basketball Boxscore")
        }
    }

    private func handlePlayerSelect(_ player: PlayerStats) {
        selectedPlayer = player
        showingGestureMenu = true
    }

    private func updatePlayerStats(_ updated: PlayerStats) {
        [teamA, teamB].forEach { team in
            if let idx = team.players.firstIndex(where: { $0.id == updated.id }) {
                team.players[idx] = updated
            }
        }
    }
}

struct TeamView: View {
    @ObservedObject var team: Team
    var title: String
    var onSelect: (PlayerStats) -> Void

    var body: some View {
        VStack {
            Text(title).font(.headline)
            List(team.players) { player in
                Button {
                    onSelect(player)
                } label: {
                    HStack {
                        Text(player.name).frame(width: 80, alignment: .leading)
                        Spacer()
                        Text("PTS: \(player.points)")
                        Text("REB: \(player.rebounds)")
                        Text("AST: \(player.assists)")
                        Text("STL: \(player.steals)")
                        Text("TO: \(player.turnovers)")
                        Text("FG%: \(String(format: "%.1f", player.fieldGoalPercentage))")
                    }
                    .font(.system(size: 12))
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct GestureMenuView: View {
    var player: PlayerStats
    var onGestureComplete: (PlayerStats) -> Void

    @GestureState private var dragOffset = CGSize.zero
    @State private var updatedPlayer: PlayerStats
    @State private var lastSwipe: PlayerAction?
    @State private var actionMessage: String?

    init(player: PlayerStats, onGestureComplete: @escaping (PlayerStats) -> Void) {
        self.player = player
        self.onGestureComplete = onGestureComplete
        _updatedPlayer = State(initialValue: player)
    }

    var body: some View {
        ZStack {
            VStack {
                Text("Gesture for \(player.name)").font(.title)
                Spacer()
                Text("Swipe to log stat").padding()
                Spacer()
            }

            if let message = actionMessage {
                Text(message)
                    .padding()
                    .background(Color.black.opacity(0.75))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .transition(.opacity)
            }
        }
        .gesture(
            DragGesture()
                .updating($dragOffset) { value, state, _ in
                    state = value.translation
                }
                .onEnded { value in
                    let threshold: CGFloat = 30
                    var action: PlayerAction?

                    if value.translation.width > threshold {
                        updatedPlayer.shotsAttempted += 1
                        action = .shotAttempt
                    } else if value.translation.width < -threshold {
                        updatedPlayer.rebounds += 1
                        action = .rebound
                    } else if value.translation.height < -threshold {
                        updatedPlayer.steals += 1
                        action = .steal
                    } else if value.translation.height > threshold {
                        updatedPlayer.turnovers += 1
                        action = .turnover
                    }

                    if let action = action {
                        lastSwipe = action
                        showMessage(action.rawValue)
                    }
                }
        )
        .simultaneousGesture(
            TapGesture()
                .onEnded {
                    if lastSwipe == .shotAttempt {
                        updatedPlayer.shotsMade += 1
                        updatedPlayer.points += 2
                        showMessage(PlayerAction.shotMade.rawValue)
                        onGestureComplete(updatedPlayer)
                    }
                }
        )
        .simultaneousGesture(
            TapGesture(count: 2)
                .onEnded {
                    updatedPlayer.assists += 1
                    showMessage(PlayerAction.assist.rawValue)
                    onGestureComplete(updatedPlayer)
                }
        )
    }

    private func showMessage(_ message: String) {
        actionMessage = "+1 \(message)"
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            actionMessage = nil
            onGestureComplete(updatedPlayer)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: PlayerStats.self, inMemory: true)
}
