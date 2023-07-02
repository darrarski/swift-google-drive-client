import Dependencies
import GoogleDriveClient
import SwiftUI

struct ContentView: View {
  @Dependency(\.googleDriveClientAuthService) var auth
  @Dependency(\.googleDriveClientListFiles) var listFiles
  @State var isSignedIn = false
  @State var filesList: FilesList?

  var body: some View {
    Form {
      authSection
      filesSection
    }
    .navigationTitle("Example")
    .task {
      for await isSignedIn in auth.isSignedInStream() {
        self.isSignedIn = isSignedIn
      }
    }
    .onOpenURL { url in
      Task {
        try await auth.handleRedirect(url)
        isSignedIn = await auth.isSignedIn()
      }
    }
  }

  var authSection: some View {
    Section("Auth") {
      if !isSignedIn {
        Text("You are signed out")

        Button {
          Task {
            await auth.signIn()
          }
        } label: {
          Text("Sign In")
        }
      } else {
        Text("You are signed in")

        Button(role: .destructive) {
          Task {
            await auth.signOut()
          }
        } label: {
          Text("Sign Out")
        }
      }
    }
  }

  @ViewBuilder
  var filesSection: some View {
    Section("Files") {
      Button {
        Task<Void, Never> {
          do {
            let params = ListFiles.Params(
              spaces: [.appDataFolder]
            )
            filesList = try await listFiles(params)
          } catch {
            logError(error)
          }
        }
      } label: {
        Text("List Files")
      }
    }

    if let filesList {
      Section {
        if filesList.files.isEmpty {
          Text("No files")
        } else {
          ForEach(filesList.files) { file in
            VStack(alignment: .leading) {
              Text(file.name)

              Text(file.id)
                .font(.caption)
                .foregroundColor(.secondary)
            }
          }
        }
      }
    }
  }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
#endif

extension GoogleDriveClient.Config: DependencyKey {
  public static let liveValue = Config(
    clientID: "437442953929-vk9agcivr59cldl92jqaiqdvlncpuh2v.apps.googleusercontent.com",
    authScope: "https://www.googleapis.com/auth/drive.appdata",
    redirectURI: "com.googleusercontent.apps.437442953929-vk9agcivr59cldl92jqaiqdvlncpuh2v://"
  )
}

private func logError(
  _ error: Error,
  fileID: StaticString = #fileID,
  line: UInt = #line
) {
  print("^^^ ERROR in \(fileID) line \(line): \(error)")
}
