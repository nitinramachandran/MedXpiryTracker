import Foundation

/// Filters OCR text down to medicine-name candidates.
///
/// The scanner can see full label sentences, dosage instructions, and dates. For the name
/// field we keep short same-row candidates of 1 to 3 words. This allows real names like
/// `Crocin Advance` or `Dolo 650`, while still ignoring longer sentence-like text.
enum MedicineNameParser {
    nonisolated private static let maximumWords = 3
    nonisolated private static let medicineNameSymbols = CharacterSet(charactersIn: "®™℠")
    nonisolated private static let allowedWordCharacters = CharacterSet.alphanumerics
        .union(CharacterSet(charactersIn: "-"))

    /// Returns unique medicine-name candidates from OCR text.
    static func candidates(from texts: [String]) -> [String] {
        var seen: Set<String> = []
        var candidates: [String] = []

        for text in texts {
            guard let candidate = candidate(from: text) else { continue }
            guard !seen.contains(candidate) else { continue }

            seen.insert(candidate)
            candidates.append(candidate)
        }

        return candidates
    }

    /// Returns one cleaned candidate, or `nil` when the OCR text looks like a sentence.
    static func candidate(from text: String) -> String? {
        let cleaned = text
            .components(separatedBy: medicineNameSymbols)
            .joined()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: .punctuationCharacters)

        guard !cleaned.isEmpty else { return nil }
        guard cleaned.rangeOfCharacter(from: .letters) != nil else { return nil }

        let words = cleaned
            .split(whereSeparator: { $0.isWhitespace || $0.isNewline })
            .map(String.init)

        guard (1...maximumWords).contains(words.count) else { return nil }
        guard words.allSatisfy(isAllowedWord(_:)) else { return nil }

        return words.joined(separator: " ").localizedCapitalized
    }

    private static func isAllowedWord(_ word: String) -> Bool {
        word.unicodeScalars.allSatisfy { allowedWordCharacters.contains($0) }
    }
}
