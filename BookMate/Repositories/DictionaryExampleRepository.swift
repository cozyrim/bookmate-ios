import Foundation

protocol DictionaryExampleRepository {
    func fetchExample(word: String, targetCode: String) async -> String?
}
