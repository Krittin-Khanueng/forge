import Foundation

enum JSONOutputDecoder {
    private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        return d
    }()

    static func decode<T: Decodable>(_ type: T.Type, from string: String) throws -> T {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw ProcessError.decodingFailed("empty output")
        }

        guard let braceIndex = trimmed.firstIndex(where: { $0 == "{" || $0 == "[" }) else {
            throw ProcessError.decodingFailed("no JSON start token found in output: \(trimmed.prefix(200))")
        }

        let jsonString = String(trimmed[braceIndex...])
        guard let data = jsonString.data(using: .utf8) else {
            throw ProcessError.decodingFailed("could not encode JSON substring as UTF-8")
        }

        do {
            return try decoder.decode(type, from: data)
        } catch {
            throw ProcessError.decodingFailed("JSON parse error: \(error.localizedDescription)")
        }
    }
}
