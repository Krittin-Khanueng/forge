import Foundation

enum ProcessError: LocalizedError, Sendable {
    case binaryNotFound(String)
    case nonZeroExit(command: String, code: Int32, stderr: String)
    case timeout(command: String, after: Duration)
    case cancelled
    case decodingFailed(String)

    var errorDescription: String? {
        switch self {
        case .binaryNotFound(let name):
            "Binary not found: \(name)"
        case .nonZeroExit(let command, let code, _):
            "Command exited with code \(code): \(command)"
        case .timeout(let command, let duration):
            "Command timed out after \(duration): \(command)"
        case .cancelled:
            "Process was cancelled"
        case .decodingFailed(let detail):
            "Failed to decode output: \(detail)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .binaryNotFound(let name):
            "Ensure '\(name)' is installed and available in /opt/homebrew/bin, /usr/local/bin, or /usr/bin."
        case .nonZeroExit:
            "Check the command's stderr output for details about the failure."
        case .timeout:
            "The operation took too long. Try increasing the timeout or checking network connectivity."
        case .cancelled:
            "The operation was interrupted. Try running it again."
        case .decodingFailed:
            "The command's output was in an unexpected format. Try running it manually to inspect the output."
        }
    }
}
