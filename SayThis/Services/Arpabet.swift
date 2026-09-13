import Foundation

enum Arpabet {
    private static let ipaSymbols: [String: String] = [
        "AA": "ɑ", "AE": "æ", "AH": "ə", "AO": "ɔ", "AW": "aʊ", "AY": "aɪ",
        "B": "b", "CH": "tʃ", "D": "d", "DH": "ð",
        "EH": "ɛ", "ER": "ɝ", "EY": "eɪ",
        "F": "f", "G": "ɡ", "HH": "h",
        "IH": "ɪ", "IY": "i", "JH": "dʒ",
        "K": "k", "L": "l", "M": "m", "N": "n", "NG": "ŋ",
        "OW": "oʊ", "OY": "ɔɪ",
        "P": "p", "R": "r", "S": "s", "SH": "ʃ",
        "T": "t", "TH": "θ", "UH": "ʊ", "UW": "u",
        "V": "v", "W": "w", "Y": "j", "Z": "z", "ZH": "ʒ",
    ]

    private static let respellSymbols: [String: String] = [
        "AA": "ah", "AE": "a", "AH": "uh", "AO": "aw", "AW": "ow", "AY": "eye",
        "B": "b", "CH": "ch", "D": "d", "DH": "th",
        "EH": "eh", "ER": "ur", "EY": "ay",
        "F": "f", "G": "g", "HH": "h",
        "IH": "ih", "IY": "ee", "JH": "j",
        "K": "k", "L": "l", "M": "m", "N": "n", "NG": "ng",
        "OW": "oh", "OY": "oy",
        "P": "p", "R": "r", "S": "s", "SH": "sh",
        "T": "t", "TH": "th", "UH": "oo", "UW": "oo",
        "V": "v", "W": "w", "Y": "y", "Z": "z", "ZH": "zh",
    ]

    private static let vowels: Set<String> = [
        "AA", "AE", "AH", "AO", "AW", "AY", "EH", "ER", "EY", "IH", "IY", "OW", "OY", "UH", "UW",
    ]

    static func transcribe(_ raw: String) -> (ipa: String, respell: String)? {
        let phones = parse(raw)
        guard !phones.isEmpty else { return nil }
        return (ipaString(phones), friendly(phones))
    }

    private struct Phone {
        let base: String
        let stress: Int?
    }

    private static func parse(_ raw: String) -> [Phone] {
        raw.split(whereSeparator: \.isWhitespace).compactMap { token in
            let value = String(token).uppercased()
            guard !value.isEmpty else { return nil }
            if let last = value.last, last.isNumber {
                return Phone(base: String(value.dropLast()), stress: Int(String(last)))
            }
            return Phone(base: value, stress: nil)
        }
    }

    private static func ipaString(_ phones: [Phone]) -> String {
        syllables(in: phones).map { syllable in
            let body = syllable.compactMap { ipaSymbols[$0.base] }.joined()
            if syllable.contains(where: { $0.stress == 1 }) { return "ˈ" + body }
            if syllable.contains(where: { $0.stress == 2 }) { return "ˌ" + body }
            return body
        }.joined().wrappedInSlashes()
    }

    private static func friendly(_ phones: [Phone]) -> String {
        syllables(in: phones).map { syllable in
            let text = syllable.compactMap { respellSymbols[$0.base] }.joined()
            return syllable.contains(where: { $0.stress == 1 }) ? text.uppercased() : text
        }.filter { !$0.isEmpty }.joined(separator: "-")
    }

    private static func syllables(in phones: [Phone]) -> [[Phone]] {
        let vowelIdx = phones.indices.filter { vowels.contains(phones[$0].base) }
        guard !vowelIdx.isEmpty else { return [phones] }

        var groups: [[Phone]] = []
        var start = phones.startIndex
        for (i, vowel) in vowelIdx.enumerated() {
            let end = i == vowelIdx.count - 1 ? phones.endIndex : vowel + 1
            groups.append(Array(phones[start ..< end]))
            start = end
        }
        return groups
    }
}

private extension String {
    func wrappedInSlashes() -> String { "/\(self)/" }
}
