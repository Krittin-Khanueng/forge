enum ShellEscape {
    static func escape(_ argument: String) -> String {
        if argument.isEmpty {
            return "''"
        }
        if argument.allSatisfy({ $0.isLetter || $0.isNumber || "-_/.@:=+".contains($0) }) {
            return argument
        }
        let escaped = argument.replacing("'", with: "'\\''")
        return "'\(escaped)'"
    }

    static func command(_ executable: String, _ arguments: [String]) -> String {
        let parts = [escape(executable)] + arguments.map(escape)
        return parts.joined(separator: " ")
    }
}
