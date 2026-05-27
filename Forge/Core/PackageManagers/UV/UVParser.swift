import Foundation

struct UVToolEntry: Sendable {
    let name: String
    let version: String
    let pythonVersion: String?
    let binaries: [String]
}

enum UVParser {
    static func parseToolList(_ output: String) -> [UVToolEntry] {
        let lines = output.split(separator: "\n", omittingEmptySubsequences: true)
        var entries: [UVToolEntry] = []
        var currentName: String?
        var currentVersion: String?
        var currentPython: String?
        var currentBinaries: [String] = []

        func flush() {
            if let name = currentName, let version = currentVersion {
                entries.append(UVToolEntry(
                    name: name,
                    version: version,
                    pythonVersion: currentPython,
                    binaries: currentBinaries
                ))
            }
            currentName = nil
            currentVersion = nil
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

            guard let (name, version, python) = parseHeader(trimmed) else { continue }

            currentName = name
            currentVersion = version
            currentPython = python
        }

        flush()

        return entries
    }

    private static func parseHeader(_ line: String) -> (name: String, version: String, python: String?)? {
        let components = line.split(separator: " ", maxSplits: 2, omittingEmptySubsequences: true)
        guard components.count >= 2 else { return nil }

        let name = String(components[0])
        var versionPart = String(components[1])

        guard versionPart.hasPrefix("v") else { return nil }
        versionPart.removeFirst()

        if components.count >= 3 {
            let rest = String(components[2])
            let stripped = rest.filter { $0 != "(" && $0 != ")" }
            return (name, versionPart, stripped)
        }

        return (name, versionPart, nil)
    }
}
