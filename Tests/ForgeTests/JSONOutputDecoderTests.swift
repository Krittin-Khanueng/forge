import Foundation
import Testing
@testable import Forge

@Suite("JSON Output Decoder Tests")
struct JSONOutputDecoderTests {

    @Test("Decodes clean JSON")
    func decodesCleanJSON() throws {
        let json = #"{"name": "test", "value": 42}"#

        struct TestModel: Decodable {
            let name: String
            let value: Int
        }

        let model = try JSONOutputDecoder.decode(TestModel.self, from: json)
        #expect(model.name == "test")
        #expect(model.value == 42)
    }

    @Test("Strips npm warning prefix before JSON")
    func stripsNpmWarningPrefix() throws {
        let output = #"""
        npm WARN config global This is a warning
        npm WARN deprecated package@1.0.0
        {"name": "test", "value": 42}
        """#

        struct TestModel: Decodable {
            let name: String
            let value: Int
        }

        let model = try JSONOutputDecoder.decode(TestModel.self, from: output)
        #expect(model.name == "test")
        #expect(model.value == 42)
    }

    @Test("Decodes JSON array from string with prefix")
    func decodesArrayWithPrefix() throws {
        let output = #"""
        some prefix garbage
        [{"name": "a"}, {"name": "b"}]
        """#

        struct TestItem: Decodable {
            let name: String
        }

        let items = try JSONOutputDecoder.decode([TestItem].self, from: output)
        #expect(items.count == 2)
        #expect(items[0].name == "a")
        #expect(items[1].name == "b")
    }

    @Test("Throws on empty string")
    func throwsOnEmptyString() throws {
        do {
            let _ = try JSONOutputDecoder.decode(String.self, from: "")
            #expect(Bool(false), "Expected throw")
        } catch let error as ProcessError {
            #expect(String(describing: error).contains("empty"))
        }
    }

    @Test("Throws on string with no JSON tokens")
    func throwsOnNoJSONTokens() throws {
        do {
            let _ = try JSONOutputDecoder.decode(String.self, from: "just plain text")
            #expect(Bool(false), "Expected throw")
        } catch let error as ProcessError {
            #expect(String(describing: error).contains("no JSON start token"))
        }
    }

    @Test("Decodes object keyed by string")
    func decodesDictionaryObject() throws {
        let json = #"""
        {"typescript": {"current": "5.4.5", "wanted": "5.4.5", "latest": "5.5.0", "location": null}}
        """#

        struct OutdatedEntry: Decodable {
            let current: String?
            let wanted: String?
            let latest: String?
            let location: String?
        }

        let entries = try JSONOutputDecoder.decode([String: OutdatedEntry].self, from: json)
        #expect(entries.count == 1)
        #expect(entries["typescript"]?.current == "5.4.5")
        #expect(entries["typescript"]?.latest == "5.5.0")
    }
}
