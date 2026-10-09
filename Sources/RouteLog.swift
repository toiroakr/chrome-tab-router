import Foundation

func routeLogLine(route: String,
                  sinceLaunchMs: Double,
                  steps: [(String, Double)],
                  totalMs: Double,
                  frontBefore: String,
                  frontAfter: String) -> String {
    var fields = ["\(route)", "total=\(Int(totalMs.rounded()))ms", "sinceLaunch=\(Int(sinceLaunchMs.rounded()))ms"]
    fields += steps.map { "\($0.0)=\(Int($0.1.rounded()))ms" }
    fields.append("\(frontBefore) -> \(frontAfter)")
    return fields.joined(separator: " ").trimmingCharacters(in: .whitespaces)
}
