import Foundation

class TextSplitter {
    static func splitIntoSentences(_ text: String) -> [String] {
        // Common sentence endings
        let sentenceEndings = [".", "!", "?", "...", "。", "！", "？"]
        
        var sentences: [String] = []
        var currentSentence = ""
        var inQuotes = false
        var lastChar: Character?
        
        for (index, char) in text.enumerated() {
            currentSentence.append(char)
            
            // Track if we're inside quotes
            if char == "\"" {
                inQuotes.toggle()
            }
            
            // Check if this might be a sentence ending
            let charStr = String(char)
            if sentenceEndings.contains(charStr) && !inQuotes {
                // Look ahead to see if this is really the end of a sentence
                let nextIndex = text.index(text.startIndex, offsetBy: index + 1)
                
                if nextIndex < text.endIndex {
                    let nextChar = text[nextIndex]
                    
                    // Check for common abbreviations
                    if charStr == "." && lastChar?.isLetter == true {
                        let precedingWord = getPrecedingWord(from: currentSentence)
                        if isAbbreviation(precedingWord) {
                            lastChar = char
                            continue
                        }
                    }
                    
                    // If next character is a space or newline, it's likely a sentence end
                    if nextChar == " " || nextChar == "\n" || nextChar == "\r" {
                        sentences.append(currentSentence.trimmingCharacters(in: .whitespacesAndNewlines))
                        currentSentence = ""
                    }
                } else {
                    // End of text
                    sentences.append(currentSentence.trimmingCharacters(in: .whitespacesAndNewlines))
                    currentSentence = ""
                }
            }
            
            lastChar = char
        }
        
        // Add any remaining text
        if !currentSentence.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            sentences.append(currentSentence.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        
        // Filter out empty sentences and merge very short ones
        return mergeShortSentences(sentences.filter { !$0.isEmpty })
    }
    
    private static func getPrecedingWord(from sentence: String) -> String {
        let words = sentence.split(separator: " ")
        guard let lastWord = words.last else { return "" }
        return String(lastWord).replacingOccurrences(of: ".", with: "")
    }
    
    private static func isAbbreviation(_ word: String) -> Bool {
        let commonAbbreviations = [
            "Dr", "Mr", "Mrs", "Ms", "Prof", "Sr", "Jr", "St", "Ave", "Inc", "Ltd", "Co",
            "vs", "etc", "i.e", "e.g", "cf", "al", "Vol", "No", "pp", "Ph.D", "M.D", "B.A",
            "M.A", "B.S", "M.S", "Ph", "U.S", "U.K", "E.U", "U.N"
        ]
        return commonAbbreviations.contains(word)
    }
    
    private static func mergeShortSentences(_ sentences: [String]) -> [String] {
        var merged: [String] = []
        var currentGroup = ""
        
        for sentence in sentences {
            if sentence.count < 30 && !currentGroup.isEmpty {
                // Merge short sentences
                currentGroup += " " + sentence
            } else {
                if !currentGroup.isEmpty {
                    merged.append(currentGroup)
                }
                currentGroup = sentence
            }
            
            // If the current group is getting long enough, add it
            if currentGroup.count > 100 {
                merged.append(currentGroup)
                currentGroup = ""
            }
        }
        
        if !currentGroup.isEmpty {
            merged.append(currentGroup)
        }
        
        return merged
    }
}