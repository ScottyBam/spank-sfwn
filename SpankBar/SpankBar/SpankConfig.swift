import Foundation

struct SpankConfig: Codable {
    var enabled: Bool
    var pack: String
    var escalate: Bool
    var fast: Bool
    var volumeScaling: Bool
    var sensitivity: Double
    var speed: Double
    var cooldown: Int

    static var defaults: SpankConfig {
        SpankConfig(
            enabled: true,
            pack: "pain",
            escalate: false,
            fast: false,
            volumeScaling: false,
            sensitivity: 0.05,
            speed: 1.0,
            cooldown: 750
        )
    }

    static var configURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/spank/config.json")
    }

    static var nikkeBaseURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("spank-sounds/nikke")
    }

    /// Read config from a URL. Throws if file is missing or malformed.
    static func read(from url: URL = configURL) throws -> SpankConfig {
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(SpankConfig.self, from: data)
    }

    /// Atomic write: write to a temp file then rename.
    func write(to url: URL = SpankConfig.configURL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(self)
        let tmp = url.deletingLastPathComponent()
            .appendingPathComponent(".spankbar-tmp-\(UUID().uuidString).json")
        try data.write(to: tmp, options: .atomic)
        _ = try FileManager.default.replaceItemAt(url, withItemAt: tmp)
    }

    /// Returns sorted list of character names from the nikke sounds directory.
    static func discoverNikkeCharacters(in base: URL = nikkeBaseURL) -> [String] {
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: base, includingPropertiesForKeys: [.isDirectoryKey], options: .skipsHiddenFiles
        ) else { return [] }
        return contents
            .filter { (try? $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true }
            .map { $0.lastPathComponent }
            .sorted()
    }
}
