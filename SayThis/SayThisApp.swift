import SwiftData
import SwiftUI

@main
struct SayThisApp: App {
    var body: some Scene {
        WindowGroup {
            SearchView()
        }
        .modelContainer(for: WordBookmark.self)
    }
}
