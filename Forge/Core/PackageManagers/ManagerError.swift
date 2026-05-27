import Foundation

enum ManagerError: LocalizedError, Sendable {
    case unsupported(reason: String)

    var errorDescription: String? {
        switch self {
        case .unsupported(let reason):
            "Unsupported operation: \(reason)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .unsupported:
            nil
        }
    }
}
