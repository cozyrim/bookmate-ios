import Foundation
import Combine

@MainActor
final class ReadingSessionViewModel: ObservableObject {
    @Published private(set) var archive = ReadingSessionArchive()
    @Published private(set) var errorMessage: String?
    @Published private(set) var isLoaded = false
    private(set) var ownerID: UUID?
    private let repository: any ReadingSessionRepository
    private let now: () -> Date

    var active: ReadingSession? { archive.active }
    var history: [ReadingSession] { archive.history.sorted { ($0.endedAt ?? $0.startedAt) > ($1.endedAt ?? $1.startedAt) } }

    init(repository: any ReadingSessionRepository, now: @escaping () -> Date = Date.init) {
        self.repository = repository
        self.now = now
    }

    func selectOwner(_ id: UUID?) {
        guard ownerID != id || !isLoaded else { return }
        ownerID = id
        archive = ReadingSessionArchive()
        isLoaded = false
        errorMessage = nil
        guard let id else { return }
        do {
            archive = try repository.load(ownerID: id)
            isLoaded = true
        } catch { errorMessage = "독서 기록을 불러오지 못했어요. 다시 시도해 주세요." }
    }

    @discardableResult
    func start(book: Book) -> Bool {
        guard isLoaded, active == nil else { return false }
        var next = archive
        let date = now()
        next.active = ReadingSession(id: UUID(), bookID: book.id, bookTitle: book.title, startedAt: date,
                                     accumulatedSeconds: 0, runningSince: date)
        return persist(next)
    }

    func pause() {
        guard var session = active, session.runningSince != nil else { return }
        session.accumulatedSeconds = session.elapsed(at: now())
        session.runningSince = nil
        var next = archive
        next.active = session
        _ = persist(next)
    }

    func resume() {
        guard var session = active, session.isPaused else { return }
        session.runningSince = now()
        var next = archive
        next.active = session
        _ = persist(next)
    }

    @discardableResult
    func finish() -> Bool {
        guard var session = active else { return false }
        let date = now()
        session.accumulatedSeconds = session.elapsed(at: date)
        session.runningSince = nil
        session.endedAt = date
        var next = archive
        next.active = nil
        next.history.removeAll { $0.id == session.id }
        next.history.append(session)
        return persist(next)
    }

    private func persist(_ next: ReadingSessionArchive) -> Bool {
        guard let ownerID, isLoaded else { return false }
        do {
            try repository.save(next, ownerID: ownerID)
            archive = next
            errorMessage = nil
            return true
        } catch {
            errorMessage = "기기에 저장하지 못했어요. 기록은 유지되니 다시 시도해 주세요."
            return false
        }
    }
}
