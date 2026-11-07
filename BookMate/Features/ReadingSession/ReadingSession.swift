import Foundation

struct ReadingSession: Identifiable, Codable, Equatable {
    let id: UUID
    let bookID: UUID
    let bookTitle: String
    let startedAt: Date
    var accumulatedSeconds: TimeInterval
    var runningSince: Date?
    var endedAt: Date?

    var isPaused: Bool { runningSince == nil && endedAt == nil }

    func elapsed(at date: Date) -> TimeInterval {
        accumulatedSeconds + (runningSince.map { max(0, date.timeIntervalSince($0)) } ?? 0)
    }

    static func durationText(_ seconds: TimeInterval) -> String {
        let value = Int(min(max(seconds, 0), 315_360_000))
        return String(format: "%02d:%02d:%02d", value / 3600, value / 60 % 60, value % 60)
    }
}

struct ReadingSessionArchive: Codable, Equatable {
    var active: ReadingSession?
    var history: [ReadingSession] = []
}
