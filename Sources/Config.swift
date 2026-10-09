import Foundation

let configPath = NSString(string: "~/.config/chrome-tab-router/config.json").expandingTildeInPath

func parseProfile(_ data: Data) -> String? {
    guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          let profile = object["profile"] as? String,
          !profile.isEmpty else { return nil }
    return profile
}

func loadProfile() -> String? {
    FileManager.default.contents(atPath: configPath).flatMap(parseProfile)
}
