import Foundation

func baseURL(_ url: String) -> String {
    var stripped = url
    if let cut = url.firstIndex(where: { $0 == "#" || $0 == "?" }) {
        stripped = String(url[..<cut])
    }
    if let components = URLComponents(string: stripped),
       components.scheme == "http" || components.scheme == "https",
       components.path.isEmpty {
        stripped += "/"
    }
    return normalizeGitHubPR(stripped)
}

private func normalizeGitHubPR(_ url: String) -> String {
    guard url.contains("github.com/"),
          let marker = url.range(of: "/pull/") else { return url }
    let afterPull = url[marker.upperBound...]
    guard let slash = afterPull.firstIndex(of: "/") else { return url }
    return String(url[..<marker.upperBound]) + afterPull[..<slash]
}
