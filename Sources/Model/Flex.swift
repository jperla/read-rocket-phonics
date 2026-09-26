import Foundation

/// "Set for variability" (Steacy & Compton, 2023 — one of the strongest reading
/// predictors): the skill of flexing an ambiguous grapheme to the pronunciation
/// that makes a REAL word. English vowel teams are quasi-regular — "oo" says a
/// long sound in *moon* but a short one in *book*; "ow" says /oʊ/ in *snow* but
/// /aʊ/ in *cow*. After a child sounds a word out, a flex step asks them to pick
/// which sound the team makes in THIS word.
struct FlexContrast: Equatable, Hashable {
    let grapheme: String        // the ambiguous team, e.g. "oo"
    let optionA: FlexOption     // one pronunciation
    let optionB: FlexOption     // the other
    let correctIsA: Bool        // which one this word uses
}

struct FlexOption: Equatable, Hashable {
    let ipa: String             // sound to play
    let keyword: String         // a known word that uses it ("moon")
    let picture: String         // emoji anchor
}

enum Flex {
    private static let longOO  = FlexOption(ipa: "uː", keyword: "moon", picture: "🌙")
    private static let shortOO = FlexOption(ipa: "ʊ",  keyword: "book", picture: "📖")
    private static let longOW  = FlexOption(ipa: "oʊ", keyword: "snow", picture: "❄️")
    /// RP packs author the long-OW reading as /əʊ/ — same contrast, different vowel.
    private static let longOWrp = FlexOption(ipa: "əʊ", keyword: "snow", picture: "❄️")
    private static let downOW   = FlexOption(ipa: "aʊ", keyword: "cow",  picture: "🐮")

    /// The flex contrast for a word, if it contains a known ambiguous team.
    /// Returns nil for unambiguous words (no flex step needed). Comparisons use
    /// the option's own `.ipa` so the FlexOption definitions stay the single
    /// source of truth for what sound each option represents.
    static func contrast(for word: PWord) -> FlexContrast? {
        // Which sound does THIS word actually use for the team? Read it off the
        // word's own grapheme IPA so data stays the single source of truth.
        for g in word.graphemes {
            switch g.letters {
            case "oo":
                let isLong = g.ipa == longOO.ipa
                return FlexContrast(grapheme: "oo", optionA: longOO, optionB: shortOO, correctIsA: isLong)
            case "ow":
                // Pick the long option matching the active pack's authoring (GenAm
                // /oʊ/ or RP /əʊ/) so a correct reading is never marked wrong.
                let longOption = g.ipa == longOWrp.ipa ? longOWrp : longOW
                let isLong = g.ipa == longOption.ipa
                return FlexContrast(grapheme: "ow", optionA: longOption, optionB: downOW, correctIsA: isLong)
            default: continue
            }
        }
        return nil
    }
}
