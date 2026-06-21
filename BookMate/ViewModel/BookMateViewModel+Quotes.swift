//
//  BookMateViewModel+Quotes.swift
//  BookMate
//
//  Created by 한채림 on 6/13/26.
//
// 구절 조회, 저장, 수정, 삭제를 관리한다.

import Foundation

extension BookMateViewModel {
    // 특정 책에 저장된 구절 목록을 서버에서 불러온다.
    func loadQuotes(bookId: UUID) async {
        let signpostID = PerformanceLogger.makeSignpostID()
        PerformanceLogger.begin("LoadQuotesAPI", id: signpostID)

        defer {
            PerformanceLogger.end("LoadQuotesAPI", id: signpostID)
        }

        do {
            quotes = try await quoteAPIService.fetchQuotes(bookId: bookId)
            quoteLoadErrorMessage = nil
        } catch {
            if handleUnauthorizedIfNeeded(error) {
                quoteLoadErrorMessage = nil
                return
            }
            quoteLoadErrorMessage = "구절을 불러오지 못했습니다."
            DebugLogger.log("구절 조회 실패:", error)
        }
    }

    // 메모리에 있는 구절 중 특정 책에 속한 구절만 반환한다.
    func savedQuotes(for bookId: UUID) -> [Quote] {
        quotes.filter { $0.bookId == bookId }
    }

    // 새 구절을 서버에 저장하고 로컬 목록 맨 앞에 추가한다.
    func saveQuote(bookId: UUID, text: String, page: Int?, memo: String?) async -> Bool {
        let signpostID = PerformanceLogger.makeSignpostID()
        PerformanceLogger.begin("SaveQuoteAPI", id: signpostID)

        defer {
            PerformanceLogger.end("SaveQuoteAPI", id: signpostID)
        }

        do {
            let savedQuote = try await quoteAPIService.saveQuote(
                bookId: bookId,
                text: text,
                page: page,
                memo: memo
            )
            quotes.insert(savedQuote, at: 0)
            operationErrorMessage = nil
            showToast("구절을 저장했어요.", style: .success)
            return true
        } catch {
            if handleUnauthorizedIfNeeded(error) { return false }
            operationErrorMessage = "구절 저장에 실패했습니다."
            showToast("구절 저장에 실패했어요.", style: .error)
            DebugLogger.log("구절 저장 실패:", error)
            return false
        }
    }

    // 기존 구절을 서버에 수정 요청하고 로컬 목록을 갱신한다.
    func updateQuote(_ quote: Quote) async -> Bool {
        let signpostID = PerformanceLogger.makeSignpostID()
        PerformanceLogger.begin("UpdateQuoteAPI", id: signpostID)

        defer {
            PerformanceLogger.end("UpdateQuoteAPI", id: signpostID)
        }

        do {
            let updatedQuote = try await quoteAPIService.updateQuote(quote)
            if let index = quotes.firstIndex(where: { $0.id == updatedQuote.id }) {
                quotes[index] = updatedQuote
            }
            operationErrorMessage = nil
            showToast("구절을 수정했어요.", style: .success)
            return true
        } catch {
            if handleUnauthorizedIfNeeded(error) { return false }
            operationErrorMessage = "구절 수정에 실패했습니다."
            showToast("구절 수정에 실패했어요.", style: .error)
            DebugLogger.log("구절 수정 실패:", error)
            return false
        }
    }

    // 서버에서 구절을 삭제하고 로컬 목록에서도 제거한다.
    func deleteQuote(_ quote: Quote) async -> Bool {
        let signpostID = PerformanceLogger.makeSignpostID()
        PerformanceLogger.begin("DeleteQuoteAPI", id: signpostID)

        defer {
            PerformanceLogger.end("DeleteQuoteAPI", id: signpostID)
        }

        do {
            try await quoteAPIService.deleteQuote(id: quote.id)
            quotes.removeAll { $0.id == quote.id }
            operationErrorMessage = nil
            showToast("구절을 삭제했어요.", style: .success)
            return true
        } catch {
            if handleUnauthorizedIfNeeded(error) { return false }
            operationErrorMessage = "구절 삭제에 실패했습니다."
            showToast("구절 삭제에 실패했어요.", style: .error)
            DebugLogger.log("구절 삭제 실패:", error)
            return false
        }
    }
}
