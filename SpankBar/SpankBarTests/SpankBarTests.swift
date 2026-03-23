import Testing
import Foundation
@testable import SpankBar

@Suite struct SpankConfigTests {

    @Test func decodeFromJSON() throws {
        let json = """
        {"enabled":true,"pack":"nikke/Privaty","escalate":false,"fast":false,
         "volumeScaling":false,"sensitivity":0.05,"speed":1.0,"cooldown":750}
        """.data(using: .utf8)!
        let cfg = try JSONDecoder().decode(SpankConfig.self, from: json)
        #expect(cfg.pack == "nikke/Privaty")
        #expect(cfg.sensitivity == 0.05)
        #expect(cfg.cooldown == 750)
        #expect(cfg.enabled == true)
    }

    @Test func encodeToJSON() throws {
        var cfg = SpankConfig.defaults
        cfg.pack = "sexy"
        let data = try JSONEncoder().encode(cfg)
        let decoded = try JSONDecoder().decode(SpankConfig.self, from: data)
        #expect(decoded.pack == "sexy")
    }

    @Test func atomicWriteAndRead() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("test-spank-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: url) }

        var cfg = SpankConfig.defaults
        cfg.pack = "halo"
        try cfg.write(to: url)

        let loaded = try SpankConfig.read(from: url)
        #expect(loaded.pack == "halo")
    }

    @Test func discoverCharacters() throws {
        let base = FileManager.default.temporaryDirectory
            .appendingPathComponent("sounds-test-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: base) }

        try FileManager.default.createDirectory(at: base.appendingPathComponent("nikke/Privaty"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: base.appendingPathComponent("nikke/Rapi"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: base.appendingPathComponent("lol/Ahri"), withIntermediateDirectories: true)
        FileManager.default.createFile(atPath: base.appendingPathComponent("nikke/notes.txt").path, contents: nil)

        let nikke = SpankConfig.discoverCharacters(inSubfolder: "nikke", base: base)
        #expect(nikke == ["Privaty", "Rapi"])

        let lol = SpankConfig.discoverCharacters(inSubfolder: "lol", base: base)
        #expect(lol == ["Ahri"])
    }

    @Test func discoverCategories() throws {
        let base = FileManager.default.temporaryDirectory
            .appendingPathComponent("cat-test-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: base) }

        try FileManager.default.createDirectory(at: base.appendingPathComponent("nikke/Privaty"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: base.appendingPathComponent("lol/Ahri"), withIntermediateDirectories: true)
        // empty dir — should not appear as a category
        try FileManager.default.createDirectory(at: base.appendingPathComponent("empty"), withIntermediateDirectories: true)

        let cats = SpankConfig.discoverCategories(base: base)
        #expect(cats == ["lol", "nikke"])
    }
}
