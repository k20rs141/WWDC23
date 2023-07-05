import SwiftUI
import SwiftData

@main
struct SwiftData_iOS17App: App {

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: Item.self)
    }
}
