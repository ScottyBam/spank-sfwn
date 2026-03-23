import XCTest
@testable import SpankBar

final class SpankConfigTests: XCTestCase {

    func testDecodeFromJSON() throws {
        let json = """
        {"enabled":true,"pack":"nikke/Privaty","escalate":false,"fast":false,
         "volumeScaling":false,"sensitivity":0.05,"speed":1.0,"cooldown":750}
        """.data(using: .utf8)!
        let cfg = try JSONDecoder().decode(SpankConfig.self, from: json)
        XCTAssertEqual(cfg.pack, "nikke/Privaty")
        XCTAssertEqual(cfg.sensitivity, 0.05)
        XCTAssertEqual(cfg.cooldown, 750)
        XCTAssertTrue(cfg.enabled)
    }

    func testEncodeToJSON() throws {
        var cfg = SpankConfig.defaults
        cfg.pack = "sexy"
        let data = try JSONEncoder().encode(cfg)
        let decoded = try JSONDecoder().decode(SpankConfig.self, from: data)
        XCTAssertEqual(decoded.pack, "sexy")
    }

    func testAtomicWriteAndRead() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("test-spank-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: url) }

        var cfg = SpankConfig.defaults
        cfg.pack = "halo"
        try cfg.write(to: url)

        let loaded = try SpankConfig.read(from: url)
        XCTAssertEqual(loaded.pack, "halo")
    }

    func testDiscoverNikkeCharacters() throws {
        let base = FileManager.default.temporaryDirectory
            .appendingPathComponent("nikke-test-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: base) }

        try FileManager.default.createDirectory(at: base.appendingPathComponent("Privaty"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: base.appendingPathComponent("Rapi"), withIntermediateDirectories: true)
        FileManager.default.createFile(atPath: base.appendingPathComponent("notes.txt").path, contents: nil)

        let chars = SpankConfig.discoverNikkeCharacters(in: base)
        XCTAssertEqual(chars.sorted(), ["Privaty", "Rapi"])
    }
}
