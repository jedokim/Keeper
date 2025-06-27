//
//  ContentView.swift
//  Keeper
//
//  Created by Jeremy Kim on 5/24/25.
//


import SwiftUI
import SwiftData

struct Player: Identifiable {
    let id = UUID()
    var name: String
    var points: Int
    var rebounds: Int
    var assists: Int
    var turnovers: Int
}

struct Team {
    var name: String
    var players: [Player]
}

struct BoxScoreView: View {
    @State var teams: [Team]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ForEach(teams.indices, id: \.self) { index in
                    VStack(alignment: .leading) {
                        Text(teams[index].name)
                            .font(.headline)

                        HStack {
                            Text("Player").frame(width: 100, alignment: .leading)
                            Text("PTS").frame(width: 40)
                            Text("REB").frame(width: 40)
                            Text("AST").frame(width: 40)
                            Text("TO").frame(width: 40)
                        }
                        .font(.subheadline)
                        .foregroundColor(.gray)

                        ForEach(teams[index].players.indices, id: \.self) { playerIndex in
                            HStack {
                                TextField("Name", text: $teams[index].players[playerIndex].name)
                                    .frame(width: 100, alignment: .leading)
                                TextField("PTS", value: $teams[index].players[playerIndex].points, format: .number)
                                    .frame(width: 40)
                                TextField("REB", value: $teams[index].players[playerIndex].rebounds, format: .number)
                                    .frame(width: 40)
                                TextField("AST", value: $teams[index].players[playerIndex].assists, format: .number)
                                    .frame(width: 40)
                                TextField("TO", value: $teams[index].players[playerIndex].turnovers, format: .number)
                                    .frame(width: 40)
                            }
                            .textFieldStyle(.roundedBorder)
                            .padding(.vertical, 2)
                        }
                    }
                    Divider()
                }
            }
            .padding()
        }
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]

    var body: some View {
        NavigationSplitView {
            List {
                ForEach(items) { item in
                    NavigationLink {
                        Text("Item at \(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))")
                    } label: {
                        Text(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))
                    }
                }
                .onDelete(perform: deleteItems)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: addItem) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
        } detail: {
            BoxScoreView(teams: sampleTeams)
        }
    }

    private func addItem() {
        withAnimation {
            let newItem = Item(timestamp: Date())
            modelContext.insert(newItem)
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
        }
    }

    private var sampleTeams: [Team] {
        let team1 = Team(name: "Lions", players: [
            Player(name: "Alice", points: 12, rebounds: 8, assists: 5, turnovers: 2),
            Player(name: "Bob", points: 15, rebounds: 3, assists: 7, turnovers: 1),
            Player(name: "Charlie", points: 9, rebounds: 5, assists: 2, turnovers: 3),
            Player(name: "Dylan", points: 7, rebounds: 6, assists: 4, turnovers: 2),
            Player(name: "Eve", points: 10, rebounds: 4, assists: 6, turnovers: 1)
        ])

        let team2 = Team(name: "Tigers", players: [
            Player(name: "Frank", points: 14, rebounds: 7, assists: 3, turnovers: 2),
            Player(name: "Grace", points: 11, rebounds: 6, assists: 5, turnovers: 3),
            Player(name: "Heidi", points: 13, rebounds: 5, assists: 4, turnovers: 1),
            Player(name: "Ivan", points: 8, rebounds: 4, assists: 6, turnovers: 2),
            Player(name: "Judy", points: 10, rebounds: 6, assists: 2, turnovers: 3)
        ])

        return [team1, team2]
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
