import SwiftData
import SwiftUI

struct WordView: View {
    let word: DictionaryWord

    @Environment(\.modelContext) private var modelContext
    @Query private var bookmarks: [WordBookmark]
    @AppStorage("saythis.accent") private var accentRaw = Accent.us.rawValue
    @State private var player = SpeechPlayer()

    private var accent: Accent {
        get { Accent(rawValue: accentRaw) ?? .us }
        nonmutating set { accentRaw = newValue.rawValue }
    }

    private var bookmark: WordBookmark? {
        bookmarks.first { $0.key == word.key }
    }

    private var isFavorite: Bool {
        bookmark?.isFavorite == true
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(word.displayWord)
                        .font(.system(size: 40, weight: .regular, design: .serif))
                    if let ipa = word.ipa {
                        Text(ipa)
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    if let respell = word.respell {
                        Text(respell)
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                }

                Picker("Accent", selection: Binding(
                    get: { accent },
                    set: { accent = $0 }
                )) {
                    ForEach(Accent.allCases) { item in
                        Text(item.label).tag(item)
                    }
                }
                .pickerStyle(.segmented)

                HStack(spacing: 12) {
                    speakButton("Play", systemImage: "speaker.wave.2.fill", slow: false)
                    speakButton("Slow", systemImage: "tortoise.fill", slow: true)
                }

                if word.definitions.isEmpty {
                    Text("No definition in the English dictionary. You can still play the word.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(groupedDefinitions, id: \.pos) { group in
                        VStack(alignment: .leading, spacing: 8) {
                            if !group.pos.isEmpty {
                                Text(group.pos)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                    .textCase(.uppercase)
                            }
                            ForEach(Array(group.defs.enumerated()), id: \.offset) { index, def in
                                HStack(alignment: .top, spacing: 8) {
                                    Text("\(index + 1).")
                                        .foregroundStyle(.secondary)
                                        .monospacedDigit()
                                    Text(def.text)
                                }
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemBackground))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    toggleFavorite()
                } label: {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                }
                .accessibilityLabel(isFavorite ? "Remove favorite" : "Add favorite")
            }
        }
        .onDisappear { player.stop() }
    }

    private var groupedDefinitions: [(pos: String, defs: [WordDefinition])] {
        var order: [String] = []
        var map: [String: [WordDefinition]] = [:]
        for def in word.definitions {
            if map[def.partOfSpeech] == nil {
                order.append(def.partOfSpeech)
            }
            map[def.partOfSpeech, default: []].append(def)
        }
        return order.map { ($0, map[$0] ?? []) }
    }

    private func speakButton(_ title: String, systemImage: String, slow: Bool) -> some View {
        Button {
            player.speak(word.displayWord, accent: accent, slow: slow)
        } label: {
            Label(title, systemImage: systemImage)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
    }

    private func toggleFavorite() {
        if let bookmark {
            bookmark.isFavorite.toggle()
            bookmark.lastViewedAt = .now
        } else {
            modelContext.insert(
                WordBookmark(
                    key: word.key,
                    displayWord: word.displayWord,
                    ipa: word.ipa ?? "",
                    isFavorite: true
                )
            )
        }
    }
}

#Preview {
    NavigationStack {
        WordView(
            word: DictionaryWord(
                key: "chablis",
                displayWord: "Chablis",
                ipa: "/ʃəˈbli/",
                respell: "shuh-BLEE",
                definitions: [
                    WordDefinition(partOfSpeech: "noun", text: "A dry white wine from Burgundy."),
                ]
            )
        )
    }
    .modelContainer(for: WordBookmark.self, inMemory: true)
}
