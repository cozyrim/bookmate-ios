import Foundation

protocol ShelfOrderRepository {
    func load(ownerID: UUID?) -> [UUID]
    func save(_ bookIDs: [UUID], ownerID: UUID?)
    func remove(_ bookID: UUID, ownerID: UUID?)
}

struct UserDefaultsShelfOrderRepository: ShelfOrderRepository {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) { self.defaults = defaults }

    func load(ownerID: UUID?) -> [UUID] {
        defaults.stringArray(forKey: key(ownerID))?.compactMap(UUID.init(uuidString:)) ?? []
    }

    func save(_ bookIDs: [UUID], ownerID: UUID?) {
        defaults.set(bookIDs.map(\.uuidString), forKey: key(ownerID))
    }

    func remove(_ bookID: UUID, ownerID: UUID?) {
        guard var order = defaults.stringArray(forKey: key(ownerID)) else { return }
        order.removeAll { $0 == bookID.uuidString }
        defaults.set(order, forKey: key(ownerID))
    }

    private func key(_ ownerID: UUID?) -> String {
        "shelfBookOrder.\(ownerID?.uuidString ?? "guest")"
    }
}
