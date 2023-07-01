import Dependencies
import GoogleDriveClient
import SwiftUI

struct ContentView: View {
  @Dependency(\.googleDriveExample) var example

  var body: some View {
    VStack {
      Image(systemName: "globe")
        .imageScale(.large)
        .foregroundColor(.accentColor)
      Text("Hello, world!")
      Text(example())
    }
    .padding()
  }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
#endif
