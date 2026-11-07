import XCTest
@testable import BookMate

@MainActor
final class ReadingSessionTests: XCTestCase {
    func testRestoresRunningTimeAfterRecreationAndExcludesPause() async {
        let repository = SessionRepositoryStub()
        let owner = UUID()
        var date = Date(timeIntervalSince1970: 1000)
        let book = Book(title: "싯타르타", author: "헤세", imageName: "", progress: 0)
        var model = ReadingSessionViewModel(repository: repository, now: { date })
        model.selectOwner(owner)
        XCTAssertTrue(model.start(book: book))
        date += 60
        model = ReadingSessionViewModel(repository: repository, now: { date })
        model.selectOwner(owner)
        XCTAssertEqual(model.active?.elapsed(at: date), 60)
        model.pause()
        date += 120
        XCTAssertEqual(model.active?.elapsed(at: date), 60)
        model.resume()
        date += 30
        XCTAssertTrue(model.finish())
        XCTAssertFalse(model.finish())
        XCTAssertEqual(model.history.count, 1)
        XCTAssertEqual(model.history.first?.accumulatedSeconds, 90)
        XCTAssertEqual(model.history.first?.bookID, book.id)
        XCTAssertNil(model.active)
    }

    func testFailedFinishKeepsSessionAndRetryDoesNotDuplicate() async {
        let repository = SessionRepositoryStub()
        let model = ReadingSessionViewModel(repository: repository)
        model.selectOwner(UUID())
        XCTAssertTrue(model.start(book: Book(title: "책", author: "", imageName: "", progress: 0)))
        let id = model.active?.id
        repository.failsWrites = true
        XCTAssertFalse(model.finish())
        XCTAssertEqual(model.active?.id, id)
        XCTAssertTrue(model.history.isEmpty)
        XCTAssertNotNil(model.errorMessage)
        repository.failsWrites = false
        XCTAssertTrue(model.finish())
        XCTAssertEqual(model.history.map(\.id), [id!])
        XCTAssertNil(model.errorMessage)
    }

    func testOwnerChangeIsolatesAndFailedLoadCannotOverwriteRecords() async {
        let repository = SessionRepositoryStub()
        let model = ReadingSessionViewModel(repository: repository)
        let first = UUID(), second = UUID()
        let book = Book(title: "책", author: "", imageName: "", progress: 0)
        model.selectOwner(first)
        XCTAssertTrue(model.start(book: book))
        model.selectOwner(second)
        XCTAssertNil(model.active)
        model.selectOwner(first)
        XCTAssertNotNil(model.active)
        model.selectOwner(nil)
        XCTAssertNil(model.active)
        repository.failsLoads = true
        model.selectOwner(first)
        XCTAssertFalse(model.start(book: book))
        XCTAssertNotNil(repository.archives[first]?.active)
    }

    func testAtomicRepositoryPersistsAcrossInstancesAndIsolatesEnvironment() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let owner = UUID()
        let first = FileReadingSessionRepository(directory: directory, environment: "staging")
        let model = ReadingSessionViewModel(repository: first)
        model.selectOwner(owner)
        XCTAssertTrue(model.start(book: Book(title: "저장", author: "", imageName: "", progress: 0)))
        let reloaded = try FileReadingSessionRepository(directory: directory, environment: "staging").load(ownerID: owner)
        XCTAssertEqual(reloaded.active?.id, model.active?.id)
        XCTAssertNil(try FileReadingSessionRepository(directory: directory, environment: "production").load(ownerID: owner).active)
        XCTAssertNil(try first.load(ownerID: UUID()).active)
        XCTAssertTrue(model.finish())
        let completed = try first.load(ownerID: owner)
        XCTAssertNil(completed.active)
        XCTAssertEqual(completed.history.count, 1)
    }

    func testCorruptFileReportsFailureWithoutOverwritingIt() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let owner = UUID()
        let file = directory.appendingPathComponent("staging-\(owner.uuidString).json")
        let invalid = Data("invalid-json".utf8)
        try invalid.write(to: file)
        let model = ReadingSessionViewModel(repository: FileReadingSessionRepository(directory: directory, environment: "staging"))
        model.selectOwner(owner)
        XCTAssertFalse(model.isLoaded)
        XCTAssertFalse(model.start(book: Book(title: "책", author: "", imageName: "", progress: 0)))
        XCTAssertEqual(try Data(contentsOf: file), invalid)
    }

    func testClockMovingBackwardsDoesNotMakeNegativeDuration() async {
        let start = Date(timeIntervalSince1970: 100)
        let session = ReadingSession(id: UUID(), bookID: UUID(), bookTitle: "책", startedAt: start,
                                     accumulatedSeconds: 20, runningSince: start)
        XCTAssertEqual(session.elapsed(at: start - 1000), 20)
    }
}

@MainActor
private final class SessionRepositoryStub: ReadingSessionRepository {
    var archives: [UUID: ReadingSessionArchive] = [:]
    var failsWrites = false
    var failsLoads = false
    func load(ownerID: UUID) throws -> ReadingSessionArchive {
        if failsLoads { throw CocoaError(.fileReadCorruptFile) }
        return archives[ownerID] ?? ReadingSessionArchive()
    }
    func save(_ archive: ReadingSessionArchive, ownerID: UUID) throws {
        if failsWrites { throw CocoaError(.fileWriteOutOfSpace) }
        archives[ownerID] = archive
    }
}
