import SwiftUI

// Environment key for tab selection
struct TabSelectionKey: EnvironmentKey {
    static let defaultValue: Binding<Int> = .constant(0)
}

extension EnvironmentValues {
    var tabSelection: Binding<Int> {
        get { self[TabSelectionKey.self] }
        set { self[TabSelectionKey.self] = newValue }
    }
}

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ArenaView()
                .tabItem {
                    Label("Arena", systemImage: "person.2.fill")
                }
                .tag(0)
                .environment(\.tabSelection, $selectedTab)
            
            ChatView()
                .tabItem {
                    Label("Chat", systemImage: "message.fill")
                }
                .tag(1)
            
            ProphetListView()
                .tabItem {
                    Label("Prophets", systemImage: "person.3.fill")
                }
                .tag(2)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(3)
        }
    }
}