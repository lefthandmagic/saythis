import SwiftData
import SwiftUI

struct SearchView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WordBookmark.lastViewedAt, order: .reverse) private var bookmarks: [WordBookmark]
    @State private var query = ""
    @State private var suggestions: [WordSuggestion] = []
    @State private var lookupWord: DictionaryWord?
    @State private var isLookingUp = false
    @State private var errorMessage: String?
    @State private var suggestTask: Task<Void, Never>?

    private let service = DictionaryService()

    private var recents: [WordBookmark] {
        Array(bookmarks.prefix(8))
    }

    private var favorites: [WordBookmark] {
        bookmarks.filter(\.isFavorite)
    }

    var body: some View {
        NavigationStack {
            List {
                if !query.trimmingCharacters(in: .whitespaces).isEmpty, !suggestions.isEmpty {
                    Section("Suggestions") {
                        ForEach(suggestions) { item in
                            Button(item.word) {
                                Task { await lookup(item.word) }
                            }
                        }
                    }
                } else if query.trimmingCharacters(in: .whitespaces).isEmpty {
                    if !favorites.isEmpty {
                        Section("Favorites") {
                            ForEach(favorites) { item in
                                bookmarkRow(item)
                            }
                        }
                    }
                    if !recents.isEmpty {
                        Section("Recent") {
                            ForEach(recents) { item in
                                bookmarkRow(item)
                            }
                        }
                    }
                    if favorites.isEmpty && recents.isEmpty {
                        ContentUnavailableView(
                            "Look up a word",
                            systemImage: "character.book.closed",
                            description: Text("English dictionary — type a word to hear it and see the IPA.")
                        )
                        .listRowBackground(Color.clear)
                    }
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("SayThis")
            .searchable(text: $query, prompt: "English word")
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .onSubmit(of: .search) {
                Task { await lookup(query) }
            }
            .onChange(of: query) { _, newValue in
                scheduleSuggestions(newValue)
            }
            .navigationDestination(item: $lookupWord) { word in
                WordView(word: word)
            }
            .overlay {
                if isLookingUp {
                    ProgressView()
                        .controlSize(.large)
                }
            }
        }
    }

    private func bookmarkRow(_ item: WordBookmark) -> some View {
        Button {
            Task { await lookup(item.key) }
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.displayWord)
                    .font(.system(.body, design: .serif))
                    .foregroundStyle(.primary)
                if !item.ipa.isEmpty {
                    Text(item.ipa)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func scheduleSuggestions(_ text: String) {
        suggestTask?.cancel()
        errorMessage = nil
        suggestTask = Task {
            try? await Task.sleep(for: .milliseconds(220))
            guard !Task.isCancelled else { return }
            do {
                suggestions = try await service.suggestions(prefix: text)
            } catch {
                suggestions = []
            }
        }
    }

    private func lookup(_ text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        isLookingUp = true
        errorMessage = nil
        defer { isLookingUp = false }
        do {
            let word = try await service.lookup(trimmed)
            touchBookmark(word)
            query = word.displayWord
            suggestions = []
            lookupWord = word
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func touchBookmark(_ word: DictionaryWord) {
        let key = word.key
        let found = bookmarks.first { $0.key == key }
        if let found {
            found.displayWord = word.displayWord
            found.ipa = word.ipa ?? ""
            found.lastViewedAt = .now
        } else {
            modelContext.insert(
                WordBookmark(key: key, displayWord: word.displayWord, ipa: word.ipa ?? "")
            )
        }
    }
}

#Preview {
    SearchView()
        .modelContainer(for: WordBookmark.self, inMemory: true)
}
