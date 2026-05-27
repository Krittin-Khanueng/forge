import Foundation

struct AnyCodable: Codable, Sendable, Hashable {
    private let raw: Data

    init<T: Codable & Sendable>(_ value: T) {
        if let ac = value as? AnyCodable {
            self.raw = ac.raw
        } else if let data = try? JSONEncoder().encode(Box(value)) {
            self.raw = data
        } else {
            self.raw = Data("null".utf8)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let str = try? container.decode(String.self) {
            raw = (try? JSONEncoder().encode(str)) ?? Data("\"\"".utf8)
        } else if let num = try? container.decode(Double.self) {
            raw = (try? JSONEncoder().encode(num)) ?? Data("0".utf8)
        } else if let bool = try? container.decode(Bool.self) {
            raw = (try? JSONEncoder().encode(bool)) ?? Data("false".utf8)
        } else if let arr = try? container.decode([AnyCodable].self) {
            raw = (try? JSONEncoder().encode(arr)) ?? Data("[]".utf8)
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            raw = (try? JSONEncoder().encode(dict)) ?? Data("{}".utf8)
        } else {
            raw = Data("null".utf8)
        }
    }

    func encode(to encoder: Encoder) throws {
        guard !raw.isEmpty,
              let obj = try? JSONSerialization.jsonObject(with: raw),
              let reencoded = try? JSONSerialization.data(withJSONObject: obj),
              let str = String(data: reencoded, encoding: .utf8) else {
            var container = encoder.singleValueContainer()
            try container.encodeNil()
            return
        }
        var container = encoder.singleValueContainer()
        try container.encode(str)
    }

    func hash(into hasher: inout Hasher) { raw.hashValue.hash(into: &hasher) }
    static func == (lhs: AnyCodable, rhs: AnyCodable) -> Bool { lhs.raw == rhs.raw }
}

private struct Box<T: Codable & Sendable>: Codable {
    let value: T
    init(_ value: T) { self.value = value }
}
