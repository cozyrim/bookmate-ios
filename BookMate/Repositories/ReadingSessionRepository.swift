import Foundation

@MainActor
protocol ReadingSessionRepository {
    func load(ownerID: UUID) throws -> ReadingSessionArchive
    func save(_ archive: ReadingSessionArchive, ownerID: UUID) throws
}

/// One atomic file contains both the running session and its completed records.
/// A failed write never clears the in-memory session or overwrites corrupt input.
struct FileReadingSessionRepository: ReadingSessionRepository {
    private let directory: URL
    private let environment: String

    init(directory: URL? = nil, environment: String = APIEnvironment.currentEnvironment.rawValue) {
        self.directory = directory ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ReadingSessions", isDirectory: true)
        self.environment = environment
    }

    func load(ownerID: UUID) throws -> ReadingSessionArchive {
        let file = url(ownerID)
        guard FileManager.default.fileExists(atPath: file.path) else { return ReadingSessionArchive() }
        let archive = try JSONDecoder().decode(ReadingSessionArchive.self, from: Data(contentsOf: file))
        guard archive.active?.endedAt == nil,
              archive.history.allSatisfy({ $0.endedAt != nil && $0.runningSince == nil }),
              Set(archive.history.map(\.id)).count == archive.history.count,
              !archive.history.contains(where: { $0.id == archive.active?.id }) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        return archive
    }

    func save(_ archive: ReadingSessionArchive, ownerID: UUID) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try JSONEncoder().encode(archive)
        try data.write(to: url(ownerID), options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
    }

    private func url(_ ownerID: UUID) -> URL {
        directory.appendingPathComponent("\(environment)-\(ownerID.uuidString).json")
    }
}
