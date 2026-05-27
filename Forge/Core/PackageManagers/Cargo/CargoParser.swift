import Foundation

struct CargoInstallEntry: Sendable {
    let name: String
    let version: String
    let binaries: [String]
}

struct CargoSearchEntry: Sendable {
    let name: String
    let description: String
    let version: String?
}

enum CargoParser {
    static func parseInstallList(_ output: String) -> [CargoInstallEntry] {
        let lines = output.split(separator: "\n", omittingEmptySubsequences: true)
        var entries: [CargoInstallEntry] = []
        var currentName: String?
        var currentVersion: String?
        var currentBinaries: [String] = []

        func flush() {
            if let name = currentName, let version = currentVersion {
                entries.append(CargoInstallEntry(
                    name: name,
                    version: version,
                    binaries: currentBinaries
                ))
            }
            currentName = nil
            currentVersion = nil
            currentBinaries = []
        }

        for rawLine in lines {
            let line = String(rawLine)
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if line.hasPrefix("    ") && !trimmed.isEmpty {
                currentBinaries.append(trimmed)
                continue
            }

            if !line.hasPrefix("    ") {
                flush()

                guard let colonIndex = trimmed.firstIndex(of: ":") else { continue }
                let header = String(trimmed[..<colonIndex]).trimmingCharacters(in: .whitespaces)

                let parts = header.split(separator: " ", omittingEmptySubsequences: true)
                guard parts.count >= 2 else { continue }

                let name = String(parts[0])
                let version = parts[1].hasPrefix("v") ? String(parts[1].dropFirst()) : String(parts[1])

                guard !name.isEmpty, !version.isEmpty else { continue }

                currentName = name
                currentVersion = version
            }
        }

        flush()

        return entries
    }

    static func parseSearch(_ output: String) -> [CargoSearchEntry] {
        let lines = output.split(separator: "\n", omittingEmptySubsequences: true)
        var entries: [CargoSearchEntry] = []

        for line in lines {
            let trimmed = String(line).trimmingCharacters(in: .whitespaces)

            guard let equalsIndex = trimmed.firstIndex(of: "=") else { continue }
            let name = String(trimmed[..<equalsIndex]).trimmingCharacters(in: .whitespaces)
            guard !name.isEmpty else { continue }

            let rest = String(trimmed[trimmed.index(after: equalsIndex)...]).trimmingCharacters(in: .whitespaces)
            guard rest.hasPrefix("\""), let closeQuote = rest[rest.index(after: rest.startIndex)...].firstIndex(of: "\"") else { continue }

            let descStart = rest.index(after: rest.startIndex)
            let description = String(rest[descStart..<closeQuote])

            let afterQuote = rest[rest.index(after: closeQuote)...]
            let version = parseSearchVersion(from: String(afterQuote))

            entries.append(CargoSearchEntry(name: name, description: description, version: version))
        }

        return entries
    }

    private static func parseSearchVersion(from text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("#") else { return nil }
        let afterHash = trimmed.dropFirst().trimmingCharacters(in: .whitespaces)
        let parts = afterHash.split(separator: " ", omittingEmptySubsequences: true)
        guard let first = parts.first else { return nil }
        return String(first)
    }
}
