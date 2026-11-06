import Foundation
import Combine

@MainActor
final class UserSearchViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var searchResults: [PublicUserResponse] = []
    @Published var blockedUserIDs: Set<UUID> = []
    @Published var isSearching = false
    private var searchTask: Task<Void, Never>?
    private let dependencies: AppDependencies
    private var socialService: any SocialRepository { dependencies.social }
    private var moderationService: any ModerationRepository { dependencies.moderation }
    private var tokenStore: any AuthTokenStore { dependencies.tokens }
    init(dependencies: AppDependencies) { self.dependencies = dependencies }
    func cancelSearch() { searchTask?.cancel() }
    @MainActor
    func scheduleSearch(for rawText: String) {
        searchTask?.cancel()
        
        let query = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard query.count >= 1 else {
                searchResults = []
                isSearching = false
                return
            }
        
        searchTask = Task {
                try? await Task.sleep(nanoseconds: 300_000_000)
                if Task.isCancelled { return }

                await performSearch(query: query)
            }
    }
    
    @MainActor
    func performSearch(query: String) async {
        guard let token = tokenStore.load() else { return }

            isSearching = true
            defer { isSearching = false }

        do {
            let users = try await socialService.searchUsers(token: token, nickname: query)
            
            guard !Task.isCancelled, query == searchText.trimmingCharacters(in: .whitespacesAndNewlines) else {
                        return
                    }
            
            searchResults = users.filter { !blockedUserIDs.contains($0.id) }
        } catch {
            if !Task.isCancelled {
                        print("유저 검색 실패:", error)
                    }
        }
    }

    private func loadBlockedUsers() async {
        do {
            let blocks = try await moderationService.fetchBlockedUsers()
            blockedUserIDs = Set(blocks.map(\.blockedUserId))
        } catch {
            print("차단 목록 로드 실패:", error)
        }
    }
}
