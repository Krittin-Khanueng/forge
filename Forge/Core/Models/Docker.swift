import Foundation

struct DockerContainer: Identifiable, Hashable, Sendable, Decodable {
    let id: String
    let names: [String]
    let image: String
    let state: String
    let status: String
    let ports: String
    let createdAt: Date?
    let command: String?
    let runningFor: String?
    let size: String?

    private enum CodingKeys: String, CodingKey {
        case id = "ID"
        case namesRaw = "Names"
        case image = "Image"
        case state = "State"
        case status = "Status"
        case ports = "Ports"
        case createdAt = "CreatedAt"
        case command = "Command"
        case runningFor = "RunningFor"
        case size = "Size"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        let namesString = try container.decode(String.self, forKey: .namesRaw)
        names = namesString.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        image = try container.decode(String.self, forKey: .image)
        state = try container.decode(String.self, forKey: .state)
        status = try container.decode(String.self, forKey: .status)
        ports = try container.decodeIfPresent(String.self, forKey: .ports) ?? ""
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        command = try container.decodeIfPresent(String.self, forKey: .command)
        runningFor = try container.decodeIfPresent(String.self, forKey: .runningFor)
        size = try container.decodeIfPresent(String.self, forKey: .size)
    }

    var displayName: String {
        names.first.map { name in
            name.hasPrefix("/") ? String(name.dropFirst()) : name
        } ?? id.prefix(12).lowercased()
    }

    var isRunning: Bool { state.lowercased() == "running" }
}

struct DockerImage: Identifiable, Hashable, Sendable, Decodable {
    let id: String
    let repository: String
    let tag: String
    let size: String
    let createdAt: Date?
    let digest: String?
    let createdSince: String?

    private enum CodingKeys: String, CodingKey {
        case id = "ID"
        case repository = "Repository"
        case tag = "Tag"
        case digest = "Digest"
        case createdSince = "CreatedSince"
        case createdAt = "CreatedAt"
        case size = "Size"
    }

    var displayName: String { "\(repository):\(tag)" }
}
