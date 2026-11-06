import Foundation

protocol WordRepository {
    func fetchWords() async throws -> [Word]
    func fetchWords(bookId: UUID) async throws -> [Word]
    func saveWord(
        bookId: UUID,
        text: String,
        meaning: String,
        partOfSpeech: String,
        exampleSentence: String?,
        targetCode: String
        ) async throws -> Word
    func updateWord(_ word: Word) async throws -> Word
    func deleteWord(id: UUID) async throws
}
