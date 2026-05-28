import Foundation

enum PackageStatus: String, Sendable {
    case upToDate
    case outdated
    case notInstalled
    case unknown

    var label: String {
        switch self {
        case .upToDate:     return "Up to date"
        case .outdated:     return "Outdated"
        case .notInstalled:  return "Not installed"
        case .unknown:      return "Unknown"
        }
    }
}
