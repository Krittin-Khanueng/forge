import OSLog

extension Logger {
    private static let subsystem = "com.forge.app"

    static let process = Logger(subsystem: subsystem, category: "process")
    static let brew = Logger(subsystem: subsystem, category: "brew")
    static let npm = Logger(subsystem: subsystem, category: "npm")
    static let ui = Logger(subsystem: subsystem, category: "ui")
    static let storage = Logger(subsystem: subsystem, category: "storage")
    static let pnpm = Logger(subsystem: subsystem, category: "pnpm")
    static let yarn = Logger(subsystem: subsystem, category: "yarn")
    static let bun = Logger(subsystem: subsystem, category: "bun")
    static let uv = Logger(subsystem: subsystem, category: "uv")
    static let cargo = Logger(subsystem: subsystem, category: "cargo")
    static let ai = Logger(subsystem: subsystem, category: "ai")
}
