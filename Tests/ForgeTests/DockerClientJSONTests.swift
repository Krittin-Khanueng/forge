import Foundation
import Testing
@testable import Forge

@Suite("Docker Client JSON Tests")
struct DockerClientJSONTests {

    @Test("Decodes docker ps --format json output")
    func decodesDockerPS() throws {
        let ndjson = #"""
        {"ID":"abc123def456","Names":"/nginx-prod","Image":"nginx:1.25","State":"running","Status":"Up 3 hours","Ports":"0.0.0.0:8080-\u003e80/tcp","CreatedAt":"2024-01-15T10:30:00Z","Command":"nginx -g daemon off;","RunningFor":"3 hours ago","Size":"0B (virtual 188MB)","Labels":"env=prod","Mounts":"","Networks":"bridge"}
        {"ID":"789xyz","Names":"/redis-cache","Image":"redis:7-alpine","State":"exited","Status":"Exited (0) 2 days ago","Ports":"6379/tcp","CreatedAt":"2024-01-10T08:00:00Z","Command":"redis-server","RunningFor":"","Size":"0B","Labels":"","Mounts":"/data","Networks":"host"}
        """#

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let containers = ndjson
            .split(separator: "\n", omittingEmptySubsequences: true)
            .compactMap { line in
                try? decoder.decode(DockerContainer.self, from: Data(line.utf8))
            }

        #expect(containers.count == 2)

        let nginx = try #require(containers.first)
        #expect(nginx.id == "abc123def456")
        #expect(nginx.displayName == "nginx-prod")
        #expect(nginx.image == "nginx:1.25")
        #expect(nginx.state == "running")
        #expect(nginx.isRunning == true)
        #expect(nginx.status == "Up 3 hours")
        #expect(nginx.ports == "0.0.0.0:8080->80/tcp")

        let redis = containers[1]
        #expect(redis.displayName == "redis-cache")
        #expect(redis.state == "exited")
        #expect(redis.isRunning == false)
    }

    @Test("Decodes docker image ls --format json output")
    func decodesDockerImages() throws {
        let ndjson = #"""
        {"ID":"sha256:a1b2c3d4","Repository":"nginx","Tag":"latest","Digest":"sha256:e1f2g3h4","CreatedSince":"2 weeks ago","CreatedAt":"2024-01-01T00:00:00Z","Size":"188MB"}
        {"ID":"sha256:f5g6h7i8","Repository":"redis","Tag":"7-alpine","Digest":"sha256:j9k0l1m2","CreatedSince":"3 days ago","CreatedAt":"2024-01-12T12:00:00Z","Size":"32MB"}
        {"ID":"sha256:n3o4p5q6","Repository":"node","Tag":"20-slim","Digest":"sha256:r7s8t9u0","CreatedSince":"5 days ago","CreatedAt":"2024-01-10T16:00:00Z","Size":"240MB"}
        """#

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let images = ndjson
            .split(separator: "\n", omittingEmptySubsequences: true)
            .compactMap { line in
                try? decoder.decode(DockerImage.self, from: Data(line.utf8))
            }

        #expect(images.count == 3)

        let nginx = try #require(images.first)
        #expect(nginx.id == "sha256:a1b2c3d4")
        #expect(nginx.repository == "nginx")
        #expect(nginx.tag == "latest")
        #expect(nginx.size == "188MB")
        #expect(nginx.displayName == "nginx:latest")

        let node = images[2]
        #expect(node.repository == "node")
        #expect(node.tag == "20-slim")
        #expect(node.size == "240MB")
    }

    @Test("Decodes container with slash in name drops leading slash")
    func displayNameDropsLeadingSlash() throws {
        let json = #"""
        {"ID":"abc","Names":"/my-app","Image":"myapp:latest","State":"running","Status":"Up 1 hour","Ports":"","CreatedAt":"2024-01-01T00:00:00Z"}
        """#

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let container = try decoder.decode(DockerContainer.self, from: Data(json.utf8))
        #expect(container.displayName == "my-app")
    }

    @Test("Decodes container with multiple names")
    func multipleNames() throws {
        let json = #"""
        {"ID":"abc","Names":"/web,/api","Image":"myapp:latest","State":"running","Status":"Up 1 hour","Ports":"80/tcp","CreatedAt":"2024-01-01T00:00:00Z"}
        """#

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let container = try decoder.decode(DockerContainer.self, from: Data(json.utf8))
        #expect(container.names.count == 2)
        #expect(container.names[0] == "/web")
        #expect(container.names[1] == "/api")
    }

    @Test("Empty NDJSON returns empty")
    func emptyNDJSON() throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let containers: [DockerContainer] = ""
            .split(separator: "\n", omittingEmptySubsequences: true)
            .compactMap { try? decoder.decode(DockerContainer.self, from: Data($0.utf8)) }

        #expect(containers.isEmpty)
    }

    @Test("Malformed line is skipped in NDJSON")
    func malformedLineSkipped() throws {
        let ndjson = #"""
        {"ID":"abc","Names":"/ok","Image":"img","State":"running","Status":"ok","Ports":"","CreatedAt":"2024-01-01T00:00:00Z"}
        not-valid-json
        {"ID":"def","Names":"/also-ok","Image":"img2","State":"exited","Status":"done","Ports":"","CreatedAt":"2024-01-02T00:00:00Z"}
        """#

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let containers = ndjson
            .split(separator: "\n", omittingEmptySubsequences: true)
            .compactMap { line in
                try? decoder.decode(DockerContainer.self, from: Data(line.utf8))
            }

        #expect(containers.count == 2)
        #expect(containers[0].id == "abc")
        #expect(containers[1].id == "def")
    }

    @Test("DockerImage displayName format")
    func dockerImageDisplayName() throws {
        let json = #"""
        {"ID":"sha256:abc","Repository":"postgres","Tag":"16","Digest":"sha256:def","CreatedSince":"1 week ago","CreatedAt":"2024-01-05T00:00:00Z","Size":"400MB"}
        """#

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let image = try decoder.decode(DockerImage.self, from: Data(json.utf8))
        #expect(image.displayName == "postgres:16")
    }

    @Test("DockerContainer isRunning detection via JSON")
    func isRunningDetection() throws {
        let runningJSON = #"""
        {"ID":"a","Names":"/a","Image":"x","State":"running","Status":"Up","Ports":"","CreatedAt":"2024-01-01T00:00:00Z"}
        """#
        let exitedJSON = #"""
        {"ID":"b","Names":"/b","Image":"x","State":"exited","Status":"Exited","Ports":"","CreatedAt":"2024-01-01T00:00:00Z"}
        """#
        let pausedJSON = #"""
        {"ID":"c","Names":"/c","Image":"x","State":"paused","Status":"Paused","Ports":"","CreatedAt":"2024-01-01T00:00:00Z"}
        """#

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let running = try decoder.decode(DockerContainer.self, from: Data(runningJSON.utf8))
        let exited = try decoder.decode(DockerContainer.self, from: Data(exitedJSON.utf8))
        let paused = try decoder.decode(DockerContainer.self, from: Data(pausedJSON.utf8))

        #expect(running.isRunning == true)
        #expect(exited.isRunning == false)
        #expect(paused.isRunning == false)
    }
}
