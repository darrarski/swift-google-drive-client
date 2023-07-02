import Pulse
import PulseUI
import SwiftUI

@main
struct App: SwiftUI.App {
  init() {
    Experimental.URLSessionProxy.shared.isEnabled = true
  }

  var body: some Scene {
    WindowGroup {
      TabView {
        NavigationStack {
          ContentView()
        }
        .tabItem {
          Label("Example", systemImage: "play")
        }

        NavigationStack {
          ConsoleView(store: .shared)
        }
        .tabItem {
          Label("Console", systemImage: "list.dash.header.rectangle")
        }
      }
    }
  }
}
