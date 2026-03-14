import Foundation
import NaturalLanguage

// MARK: - CardIntelligenceService
// On-device AI using Apple's NaturalLanguage framework (Neural Engine).
// No custom ML models, no network calls — ambient intelligence that enhances
// existing UI surfaces without "AI" branding or sparkle icons.
//
// Features:
// 1. Tag suggestions via NLTagger (.lexicalClass + .nameType)
// 2. Sentiment analysis via NLTagger (.sentimentScore)
// 3. Smart list suggestion via NLEmbedding word similarity

@Observable
final class CardIntelligenceService {

    // MARK: - Tag Suggestions

    /// Extracts key nouns and named entities from card text.
    /// Returns up to 5 unique suggestions, excluding common stopwords.
    func suggestTags(title: String, description: String) -> [String] {
        let text = "\(title) \(description)"
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return [] }

        var candidates: [String] = []

        // Extract nouns via lexical class tagging
        let lexTagger = NLTagger(tagSchemes: [.lexicalClass])
        lexTagger.string = text
        lexTagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lexicalClass) { tag, range in
            if tag == .noun {
                let word = String(text[range])
                if word.count >= 3, !stopwords.contains(word.lowercased()) {
                    candidates.append(word.capitalized)
                }
            }
            return true
        }

        // Extract named entities (people, places, organizations)
        let nameTagger = NLTagger(tagSchemes: [.nameType])
        nameTagger.string = text
        nameTagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .nameType) { tag, range in
            if tag == .personalName || tag == .placeName || tag == .organizationName {
                let entity = String(text[range])
                if entity.count >= 2 {
                    candidates.append(entity.capitalized)
                }
            }
            return true
        }

        // Deduplicate, preserve order, limit to 5
        var seen = Set<String>()
        return candidates.filter { seen.insert($0).inserted }.prefix(5).map { $0 }
    }

    // MARK: - Sentiment Analysis

    /// Returns sentiment score from -1.0 (negative) to 1.0 (positive).
    /// Uses NLTagger with .sentimentScore scheme for on-device inference.
    func analyzeSentiment(text: String) -> Double {
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return 0.0 }

        let tagger = NLTagger(tagSchemes: [.sentimentScore])
        tagger.string = text

        let (tag, _) = tagger.tag(at: text.startIndex, unit: .paragraph, scheme: .sentimentScore)
        return Double(tag?.rawValue ?? "0") ?? 0.0
    }

    // MARK: - Smart List Suggestion

    /// Compares card text to list titles using NLEmbedding word vectors.
    /// Returns the best-matching list title if similarity score > 0.3.
    func suggestList(cardText: String, listTitles: [String]) -> String? {
        guard !cardText.trimmingCharacters(in: .whitespaces).isEmpty,
              !listTitles.isEmpty,
              let embedding = NLEmbedding.wordEmbedding(for: .english)
        else { return nil }

        var bestMatch: (title: String, score: Double)?

        for listTitle in listTitles {
            // Compare each word in cardText to the list title words
            let cardWords = cardText.lowercased().split(separator: " ").map(String.init)
            let listWords = listTitle.lowercased().split(separator: " ").map(String.init)

            var maxScore: Double = 0
            for cardWord in cardWords {
                for listWord in listWords {
                    // Check both words exist in vocabulary before computing distance
                    guard embedding.contains(cardWord), embedding.contains(listWord) else { continue }
                    let distance = embedding.distance(between: cardWord, and: listWord)
                    // NLEmbedding.distance returns cosine distance (0 = identical, 2 = opposite)
                    // Convert to similarity: 1 - (distance / 2)
                    let similarity = 1.0 - (distance / 2.0)
                    maxScore = max(maxScore, similarity)
                }
            }

            if maxScore > (bestMatch?.score ?? 0.3) {
                bestMatch = (listTitle, maxScore)
            }
        }

        return bestMatch?.title
    }

    // MARK: - Stopwords

    /// Common English words to filter from tag suggestions
    private let stopwords: Set<String> = [
        "the", "a", "an", "and", "or", "but", "in", "on", "at", "to", "for",
        "of", "with", "by", "from", "is", "it", "this", "that", "are", "was",
        "be", "has", "had", "have", "will", "can", "may", "not", "all", "each",
        "every", "both", "few", "more", "most", "other", "some", "such", "than",
        "too", "very", "just", "also", "now", "new", "one", "two", "three",
    ]
}
