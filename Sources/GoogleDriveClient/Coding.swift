import Foundation

extension JSONDecoder {
  static let auth: JSONDecoder = {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    return decoder
  }()

  static let api: JSONDecoder = {
    let decoder = JSONDecoder()
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
    dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
    decoder.dateDecodingStrategy = .formatted(dateFormatter)
    return decoder
  }()
}
