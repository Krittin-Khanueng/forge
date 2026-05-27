import Foundation

struct UVToolEntry: Sendable {
    let name: String
    let version: String
    let latestVersion: String?
    let pythonVersion: String?
    let binaries: [String]
}

enum UVParser {
    static func parseToolList(_ output: String) -> [UVToolEntry] {
        let lines = output.split(separator: "\n", omittingEmptySubsequences: true)
        var entries: [UVToolEntry] = []
        var currentName: String?
        var currentVersion: String?
        var currentLatest: String?
        var currentPython: String?
        var currentBinaries: [String] = []

        func flush() {
            if let name = currentName, let version = currentVersion {
                entries.append(UVToolEntry(
                    name: name,
                    version: version,
                    latestVersion: currentLatest,
                    pythonVersion: currentPython,
                    binaries: currentBinaries
                ))
            }
            currentName = nil
            currentVersion = nil
            currentLatest = nil
            currentPython = nil
            currentBinaries = []
        }

        for line in lines {
            let trimmed = String(line).trimmingCharacters(in: .whitespaces)

            if trimmed.hasPrefix("- ") {
                let binary = String(trimmed.dropFirst(2)).trimmingCharacters(in: .whitespaces)
                if !binary.isEmpty {
                    currentBinaries.append(binary)
                }
                continue
            }

            flush()

            guard let (name, version, latest, python) = parseHeader(trimmed) else { continue }

            currentName = name
            currentVersion = version
            currentLatest = latest
            currentPython = python
        }

        flush()

        return entries
    }

    private static func parseHeader(_ line: String) -> (name: String, version: String, latest: String?, python: String?)? {
        let components = line.split(separator: " ", maxSplits: 2, omittingEmptySubsequences: true)
        guard components.count >= 2 else { return nil }

        let name = String(components[0])
        var versionPart = String(components[1])

        guard versionPart.hasPrefix("v") else { return nil }
        versionPart.removeFirst()

        if components.count >= 3 {
            let rest = String(components[2])
            let latest = parseLatestVersion(from: rest)
            let python = parsePythonVersion(from: rest)
            return (name, versionPart, latest, python)
        }

        return (name, versionPart, nil, nil)
    }

    private static func parseLatestVersion(from text: String) -> String? {
        guard let start = text.range(of: "[latest:") else { return nil }
        let afterPrefix = text[start.upperBound...]
        guard let end = afterPrefix.firstIndex(of: "]") else { return nil }
        let latest = afterPrefix[..<end].trimmingCharacters(in: .whitespaces)
        return latest.isEmpty ? nil : latest
    }

    private static func parsePythonVersion(from text: String) -> String? {
        let withoutLatest: String
        if let latestStart = text.range(of: "[latest:"),
           let latestEnd = text[latestStart.upperBound...].firstIndex(of: "]") {
            var copy = text
            copy.removeSubrange(latestStart.lowerBound...latestEnd)
            withoutLatest = copy.trimmingCharacters(in: .whitespaces)
        } else {
            withoutLatest = text.trimmingCharacters(in: .whitespaces)
        }

        guard !withoutLatest.isEmpty else { return nil }

        let pairs: [(Character, Character)] = [("(", ")"), ("[", "]")]
        for (opening, closing) in pairs {
            if withoutLatest.first == opening, withoutLatest.last == closing {
                let stripped = withoutLatest.dropFirst().dropLast().trimmingCharacters(in: .whitespaces)
                return stripped.isEmpty ? nil : stripped
            }
        }

        return withoutLatest
    }
}
