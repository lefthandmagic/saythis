import Foundation

enum Accent: String, CaseIterable, Identifiable {
    case us
    case uk

    var id: String { rawValue }

    var label: String {
        switch self {
        case .us: "US"
        case .uk: "UK"
        }
    }

    var voiceLanguage: String {
        switch self {
        case .us: "en-US"
        case .uk: "en-GB"
        }
    }
}

struct WordDefinition: Identifiable, Hashable {
    var id: String { "\(partOfSpeech)|\(text)" }
    let partOfSpeech: String
    let text: String
}

struct DictionaryWord: Identifiable, Hashable {
    var id: String { key }
    let key: String
    let displayWord: String
    let ipa: String?
    let respell: String?
    let definitions: [WordDefinition]

    var hasPronunciation: Bool { ipa != nil || respell != nil }
}

struct WordSuggestion: Identifiable, Hashable {
    var id: String { word.lowercased() }
    let word: String
}
