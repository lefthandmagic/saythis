import Foundation

enum DictionaryError: LocalizedError {
    case notFound(String)
    case network

    var errorDescription: String? {
        switch self {
        case .notFound(let word):
            return "No English entry for “\(word)”."
        case .network:
            return "Couldn’t reach the dictionary. Check the connection and try again."
        }
    }
}

actor DictionaryService {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func lookup(_ raw: String) async throws -> DictionaryWord {
        let query = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { throw DictionaryError.notFound(raw) }

        let rows = try await fetchWords(spelling: query, limit: 8)
        if let exact = rows.first(where: { $0.word.compare(query, options: .caseInsensitive) == .orderedSame }) {
            return exact.asDictionaryWord()
        }
        if let first = rows.first {
            return first.asDictionaryWord()
        }
        throw DictionaryError.notFound(query)
    }

    func suggestions(prefix: String) async throws -> [WordSuggestion] {
        let query = prefix.trimmingCharacters(in: .whitespacesAndNewlines)
        guard query.count >= 2 else { return [] }

        var components = URLComponents(string: "https://api.datamuse.com/sug")
        components?.queryItems = [
            URLQueryItem(name: "s", value: query),
            URLQueryItem(name: "max", value: "8"),
        ]
        guard let url = components?.url else { return [] }

        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw DictionaryError.network
        }
        let rows = try JSONDecoder().decode([SuggestionRow].self, from: data)
        return rows.map { WordSuggestion(word: $0.word) }
    }

    private func fetchWords(spelling: String, limit: Int) async throws -> [DatamuseWord] {
        var components = URLComponents(string: "https://api.datamuse.com/words")
        components?.queryItems = [
            URLQueryItem(name: "sp", value: spelling),
            URLQueryItem(name: "md", value: "dpr"),
            URLQueryItem(name: "max", value: String(limit)),
        ]
        guard let url = components?.url else { throw DictionaryError.network }

        do {
            let (data, response) = try await session.data(from: url)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                throw DictionaryError.network
            }
            return try JSONDecoder().decode([DatamuseWord].self, from: data)
        } catch is DecodingError {
            throw DictionaryError.network
        } catch let error as DictionaryError {
            throw error
        } catch {
            throw DictionaryError.network
        }
    }
}

private struct SuggestionRow: Decodable {
    let word: String
}

private struct DatamuseWord: Decodable {
    let word: String
    let tags: [String]?
    let defs: [String]?
    let defHeadword: String?

    func asDictionaryWord() -> DictionaryWord {
        let display = defHeadword?.trimmingCharacters(in: .whitespacesAndNewlines)
        let title = (display?.isEmpty == false ? display! : word)
        let arpabet = tags?.compactMap { tag -> String? in
            guard tag.hasPrefix("pron:") else { return nil }
            return String(tag.dropFirst(5))
        }.first
        let transcribed = arpabet.flatMap(Arpabet.transcribe)
        return DictionaryWord(
            key: word.lowercased(),
            displayWord: title,
            ipa: transcribed?.ipa,
            respell: transcribed?.respell,
            definitions: (defs ?? []).compactMap(Self.parseDefinition)
        )
    }

    private static func parseDefinition(_ raw: String) -> WordDefinition? {
        let parts = raw.split(separator: "\t", maxSplits: 1).map(String.init)
        guard parts.count == 2 else {
            let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            return text.isEmpty ? nil : WordDefinition(partOfSpeech: "", text: text)
        }
        let pos = expandedPOS(parts[0])
        let text = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return nil }
        return WordDefinition(partOfSpeech: pos, text: text)
    }

    private static func expandedPOS(_ code: String) -> String {
        switch code.lowercased() {
        case "n": "noun"
        case "v": "verb"
        case "adj": "adjective"
        case "adv": "adverb"
        case "u": "unknown"
        default: code
        }
    }
}
