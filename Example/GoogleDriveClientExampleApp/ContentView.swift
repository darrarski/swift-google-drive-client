import Dependencies
import GoogleDriveClient
import Logging
import SwiftUI

struct ContentView: View {
  let log = Logger(label: Bundle.main.bundleIdentifier!)
  @Dependency(\.googleDriveClientAuthService) var auth
  @Dependency(\.googleDriveClientListFiles) var listFiles
  @Dependency(\.googleDriveClientCreateFile) var createFile
  @Dependency(\.googleDriveClientGetFileData) var getFileData
  @Dependency(\.googleDriveClientDeleteFile) var deleteFile
  @State var isSignedIn = false
  @State var filesList: FilesList?
  @State var fileContentAlert: String?

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
      Task<Void, Never> {
        do {
          try await auth.handleRedirect(url)
        } catch {
          log.error("Auth.HandleRedirect failure", metadata: [
            "error": "\(error)",
            "localizedDescription": "\(error.localizedDescription)"
          ])
        }
        isSignedIn = await auth.isSignedIn()
      }
    }
    .alert(
      "File content",
      isPresented: Binding(
        get: { fileContentAlert != nil },
        set: { isPresented in
          if !isPresented {
            fileContentAlert = nil
          }
        }
      ),
      presenting: fileContentAlert,
      actions: { _ in Button("OK") {} },
      message: { Text($0) }
    )
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
              query: "trashed=false",
              spaces: [.appDataFolder]
            )
            filesList = try await listFiles(params)
          } catch {
            log.error("ListFiles failure", metadata: [
              "error": "\(error)",
              "localizedDescription": "\(error.localizedDescription)"
            ])
          }
        }
      } label: {
        Text("List Files")
      }

      Button {
        Task<Void, Never> {
          do {
            let dateText = Date().formatted(date: .complete, time: .complete)
            let params = CreateFile.Params(
              data: "Hello, World! \(dateText)".data(using: .utf8)!,
              metadata: .init(
                name: "test.txt",
                spaces: "appDataFolder",
                mimeType: "text/plain",
                parents: ["appDataFolder"]
              )
            )
            _ = try await createFile(params)
          } catch {
            log.error("CreateFile failure", metadata: [
              "error": "\(error)",
              "localizedDescription": "\(error.localizedDescription)"
            ])
          }
        }
      } label: {
        Text("Create File")
      }
    }

    if let filesList {
      Section {
        if filesList.files.isEmpty {
          Text("No files")
        } else {
          ForEach(filesList.files) { file in
            HStack {
              VStack(alignment: .leading) {
                Text(file.name)

                Text(file.id)
                  .font(.caption)
                  .foregroundColor(.secondary)
              }

              Spacer()

              Button {
                Task<Void, Never> {
                  do {
                    let params = GetFileData.Params(fileId: file.id)
                    let data = try await getFileData(params)
                    if let string = String(data: data, encoding: .utf8) {
                      fileContentAlert = string
                    } else {
                      fileContentAlert = data.base64EncodedString()
                    }
                  } catch {
                    log.error("GetFileData failure", metadata: [
                      "error": "\(error)",
                      "localizedDescription": "\(error.localizedDescription)"
                    ])
                  }
                }
              } label: {
                Image(systemName: "arrow.down.circle")
              }
              .buttonStyle(.borderless)
            }
          }
          .onDelete { indexSet in
            let fileIds = indexSet.map { filesList.files[$0].id }
            self.filesList?.files.remove(atOffsets: indexSet)
            Task<Void, Never> {
              for id in fileIds {
                do {
                  let params = DeleteFile.Params(fileId: id)
                  try await deleteFile(params)
                } catch {
                  log.error("DeleteFile failure", metadata: [
                    "error": "\(error)",
                    "localizedDescription": "\(error.localizedDescription)"
                  ])
                }
              }
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

extension Encodable {
  func jsonEncodedString() throws -> String {
    String(data: try JSONEncoder().encode(self), encoding: .utf8)!
  }
}
