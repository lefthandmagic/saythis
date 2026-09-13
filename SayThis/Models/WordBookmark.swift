import Foundation
import SwiftData

@Model
final class WordBookmark {
    @Attribute(.unique) var key: String
    var displayWord: String
    var ipa: String
    var isFavorite: Bool
    var lastViewedAt: Date

    init(
        key: String,
        displayWord: String,
        ipa: String = "",
        isFavorite: Bool = false,
        lastViewedAt: Date = .now
    ) {
        self.key = key
        self.displayWord = displayWord
        self.ipa = ipa
        self.isFavorite = isFavorite
        self.lastViewedAt = lastViewedAt
    }
}
