import Foundation
import OSLog

enum JSONOutputDecoder {
    private static let logger = Logger.process

    private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        return d
    }()

    static func decode<T: Decodable>(
        _ type: T.Type,
        from string: String,
        context: String = "JSON output"
    ) throws -> T {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            logger.error("Decode failed: \(context) returned empty output")
            throw ProcessError.decodingFailed("\(context): empty output")
        }

        guard let braceIndex = trimmed.firstIndex(where: { $0 == "{" || $0 == "[" }) else {
            let preview = String(trimmed.prefix(500))
            logger.error("Decode failed: \(context) has no JSON start token. output=\(preview)")
            throw ProcessError.decodingFailed("\(context): no JSON start token found in output: \(trimmed.prefix(200))")
        }

        let jsonString = String(trimmed[braceIndex...])
        guard let data = jsonString.data(using: .utf8) else {
            logger.error("Decode failed: \(context) could not encode JSON substring as UTF-8")
            throw ProcessError.decodingFailed("\(context): could not encode JSON substring as UTF-8")
        }

        do {
            return try decoder.decode(type, from: data)
        } catch {
            let preview = String(jsonString.prefix(1000))
            logger.error("Decode failed: \(context). error=\(error.localizedDescription), json=\(preview)")
            throw ProcessError.decodingFailed("\(context): JSON parse error: \(error.localizedDescription)")
        }
    }
}
