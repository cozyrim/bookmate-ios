import Foundation

protocol BookMetadataRepository {
    func fetchMetadata(isbn: String) async -> BookLookupMetadata?
}
