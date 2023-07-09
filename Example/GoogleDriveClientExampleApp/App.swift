import Logging
import Pulse
import PulseLogHandler
import PulseUI
import SwiftUI

@main
struct App: SwiftUI.App {
  init() {
    LoggingSystem.bootstrap(PersistentLogHandler.init)
    Experimental.URLSessionProxy.shared.isEnabled = true
  }

  var body: some Scene {
    WindowGroup {
      TabView {
        NavigationStack {
          ExampleView()
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
