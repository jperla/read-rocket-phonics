import Foundation

/// Everything language-specific about a learnable language/alphabet. The lesson
/// player, reward system, tracing engine, and progress store are all language-
/// agnostic and read from the *active* pack — so adding Greek (or later Russian,
/// Arabic, Korean…) is "just another pack".
struct LanguagePack {
    let id: String            // "en", "el"
    let name: String          // English name, e.g. "Greek"
    let nativeName: String    // e.g. "Ελληνικά"
    let flag: String          // 🇬🇷
    let ttsLocale: String     // BCP-47 voice locale, e.g. "el-GR"
    let rtl: Bool             // right-to-left script (Arabic later); Greek/English = false
    let letters: [Letter]     // alphabet in teaching order, with ipa/keyword/picture
    let reversible: Set<String>          // easily-flipped letters → extra tracing reps
    let mnemonics: [String: String]      // letter → spoken shape mnemonic
    let strings: [String: String]        // L10n table for UI + spoken prompts

    var allLetters: [String] { letters.map { $0.letter } }
    var allPictures: [String] { letters.map { $0.picture } }
    func letter(_ s: String) -> Letter? { letters.first { $0.letter == s } }
    /// Reversible letters (b/d/p/q…) get extra tracing practice to fight mirror-flips.
    // 2, not more: piling on reps reads as "I keep failing" to a 4-year-old.
    static let reversibleTraceReps = 2, standardTraceReps = 1
    func traceReps(_ l: String) -> Int { reversible.contains(l) ? Self.reversibleTraceReps : Self.standardTraceReps }
    func mnemonic(_ l: String) -> String? { mnemonics[l] }
    /// Localized string for a key, falling back to the key itself.
    func t(_ key: String) -> String { strings[key] ?? LanguagePack.english.strings[key] ?? key }
}

/// The registry + the single global "active language". `Languages.current` is the
/// source the static curriculum reads; the app keeps it in sync with the selected
/// profile's chosen language (ProfileStore is the persisted source of truth).
enum Languages {
    static let all: [LanguagePack] = [.english, .englishUK, .greek, .spanish, .french, .portuguese, .portugueseEU, .german]
    static func pack(_ id: String) -> LanguagePack { all.first { $0.id == id } ?? .english }

    private(set) static var current: String = "en"
    static func setCurrent(_ code: String) { current = code }
    static var active: LanguagePack { pack(current) }
}

extension LanguagePack {
    /// English — wraps the existing LetterLand data so behavior is unchanged.
    static let english = LanguagePack(
        id: "en", name: "English (US)", nativeName: "English (US)", flag: "🇺🇸",
        ttsLocale: "en-US", rtl: false,
        letters: LetterLand.letters,
        reversible: LetterLand.reversible,
        mnemonics: ["b": "B is for belly!", "d": "D is for diaper!",
                    "p": "P points its tail down, like a puppy's leg below the line!",
                    "q": "Q has a curly tail and always brings its friend u!"],
        strings: EnglishStrings.table
    )
}

/// English UI/spoken strings (the L10n baseline; other packs override what they can).
enum EnglishStrings {
    static let table: [String: String] = [
        "great_job": "Great job!",
        "hi_lets_read": "Hi %@! Let's read!",
        "which_read": "Which one did you read?",
        "daily_review": "Today's Review",
        "placement_title": "Where should we start?",
        "placement_new": "Brand-new reader — start at the beginning",
        "placement_letters": "Knows some letters",
        "placement_words": "Already reads simple words",
        "locked_hint": "Finish the one before to open this!",
        "who_reads": "Who is reading today?",
        "blast_off": "Blast off!",
        "blast_off_spoken": "Blast off! Great job!",
        "back_to_map": "Back to map",
        "got_it": "Got it!",
        "lets_go": "Let's go!",
        "try_again_spoken": "Let's try again!",
        "which_starts": "Which one starts with…",
        "find_the_letter": "Find the letter",
        "tap_what_you_hear": "Tap what you hear",
        "match_big_little": "Match the big and little letter",
        "keep_going_uncover": "Keep going to uncover it!",
        "you_found": "You found the %@!",
        "my_posters": "My Posters",
        "trace_it": "Trace it!",
        "new_sound": "New sound!",
        "tap_to_hear": "Tap to hear it",
        "say_with_me": "Say it with me!",
        "how_to_play": "How to play",
        "coach_tap": "Tap a letter to hear its sound",
        "coach_slide": "Slide the comet to sound it out — then read it!",
        "coach_prove": "Show you read it: pick the picture or spell it",
        "coach_blast": "Get them right to blast off!",
        "drag_sound": "Drag the right animal to the letter!",
        "library_title": "📚 Library",
        "library_subtitle": "Read a story all by yourself!",
        "the_end": "The End!",
        "you_read": "You read %@!",
        "back_to_books": "Back to books",
    ]
}
