import Foundation

/// The Greek (Ελληνικά) language pack — alphabet on-ramp for pre-readers. Modern
/// Greek is wonderfully regular grapheme→phoneme, which is ideal for phonics. Note
/// the authentic challenge that η, ι, υ all say /i/ and ο, ω both say /o/ — taught
/// as real sounds (we teach the SOUND, never the letter name).
///
/// v1 covers the 24 lowercase letters: meet → hear→tap → find → match Αα. The
/// `.trace` step is intentionally omitted until Greek centerline stroke skeletons
/// are authored (we won't ship the old fat-glyph outline tracing).
enum GreekLand {
    static let letters: [Letter] = [
        // Group 1 — open vowels + easy continuants (blend-friendly first)
        Letter(letter: "α", ipa: "a",  keyword: "αστέρι",   picture: "⭐"),
        Letter(letter: "ο", ipa: "o",  keyword: "ομπρέλα",  picture: "☂️"),
        Letter(letter: "ε", ipa: "e",  keyword: "ελέφαντας", picture: "🐘"),
        Letter(letter: "μ", ipa: "m",  keyword: "μήλο",     picture: "🍎"),
        Letter(letter: "λ", ipa: "l",  keyword: "λεμόνι",   picture: "🍋"),
        Letter(letter: "σ", ipa: "s",  keyword: "σάκος",    picture: "🎒"),
        // Group 2
        Letter(letter: "ι", ipa: "i",  keyword: "ιγκλού",   picture: "🧊"),
        Letter(letter: "ν", ipa: "n",  keyword: "νερό",     picture: "💧"),
        Letter(letter: "π", ipa: "p",  keyword: "παπί",     picture: "🐤"),
        Letter(letter: "τ", ipa: "t",  keyword: "τόπι",     picture: "🏐"),
        Letter(letter: "ρ", ipa: "r",  keyword: "ρολόι",    picture: "🕐"),
        Letter(letter: "κ", ipa: "k",  keyword: "κότα",     picture: "🐔"),
        // Group 3
        Letter(letter: "η", ipa: "i",  keyword: "ήρωας",    picture: "🦸"),
        Letter(letter: "ω", ipa: "o",  keyword: "ωκεανός",  picture: "🌊"),
        Letter(letter: "υ", ipa: "i",  keyword: "ύπνος",    picture: "😴"),
        Letter(letter: "β", ipa: "v",  keyword: "βάρκα",    picture: "⛵"),
        Letter(letter: "γ", ipa: "ɣ",  keyword: "γάτα",     picture: "🐱"),
        Letter(letter: "δ", ipa: "ð",  keyword: "δέντρο",   picture: "🌳"),
        // Group 4
        Letter(letter: "ζ", ipa: "z",  keyword: "ζέβρα",    picture: "🦓"),
        Letter(letter: "θ", ipa: "θ",  keyword: "θάλασσα",  picture: "🌊"),
        Letter(letter: "φ", ipa: "f",  keyword: "φεγγάρι",  picture: "🌙"),
        Letter(letter: "χ", ipa: "x",  keyword: "χαρά",     picture: "😄"),
        // Group 5
        Letter(letter: "ξ", ipa: "ks", keyword: "ξύλο",     picture: "🪵"),
        Letter(letter: "ψ", ipa: "ps", keyword: "ψάρι",     picture: "🐟")
    ]

    static func letter(_ s: String) -> Letter? { letters.first { $0.letter == s } }

    /// Phonemic awareness groups (hear a sound → tap the picture that starts with it).
    private static let firstSoundGroups: [[String]] = [
        ["α", "μ", "σ"], ["ο", "λ", "π"], ["ε", "ν", "τ"], ["ι", "ρ", "κ"]
    ]

    /// Letter-sound lessons chunked into units (phonics-friendly order).
    private static let letterChunks: [(String, [String])] = [
        ("Γράμματα: α ο ε μ λ σ", ["α", "ο", "ε", "μ", "λ", "σ"]),
        ("Γράμματα: ι ν π τ ρ κ", ["ι", "ν", "π", "τ", "ρ", "κ"]),
        ("Γράμματα: η ω υ β γ δ", ["η", "ω", "υ", "β", "γ", "δ"]),
        ("Γράμματα: ζ θ φ χ",     ["ζ", "θ", "φ", "χ"]),
        ("Γράμματα: ξ ψ",         ["ξ", "ψ"])
    ]

    static let units: [Unit] = {
        let pa: [Lesson] = firstSoundGroups.enumerated().map { i, group in
            Lesson(id: "el_snd_\(i + 1)", title: "Πρώτοι Ήχοι \(i + 1)", icon: "👂",
                   letters: group.compactMap { letter($0) },
                   letterActivities: [.firstSound])
        }
        let soundsUnit = Unit(id: "el_snd", title: "Πρώτοι Ήχοι", colorA: "#FFCD3C", colorB: "#FF9A6B", lessons: pa)
        var letterUnits: [(unit: Unit, letters: [Letter])] = []
        for (gi, chunk) in letterChunks.enumerated() {
            let letters = chunk.1.compactMap { letter($0) }
            let lessons: [Lesson] = letters.map { L in
                Lesson(id: "el_ltr_\(L.letter)", title: "Γράμμα \(L.letter.uppercased())", icon: L.picture,
                       letters: [L],
                       letterActivities: [.meet, .trace, .hearTap, .hearTap, .hearTap])
            }
            letterUnits.append((Unit(id: "el_ltr_\(gi + 1)", title: chunk.0,
                                     colorA: "#67C8FF", colorB: "#A78BFA", lessons: lessons), letters))
        }
        return ReviewLessons.assemble(soundsUnit: soundsUnit, letterUnits: letterUnits,
                                      reviewTitle: "Αντιστοίχιση Ήχων", idPrefix: "el",
                                      wordUnits: GreekLand.wordUnits,
                                      spellTitle: "Γράψε το!",
                                      practiceTitle: "Εξάσκηση!", mixTitle: "Ανακάτεψέ τα!")
    }()
}

extension LanguagePack {
    /// Greek — alphabet on-ramp with immersion strings + el-GR voice.
    static let greek = LanguagePack(
        id: "el", name: "Greek", nativeName: "Ελληνικά", flag: "🇬🇷",
        ttsLocale: "el-GR", rtl: false,
        letters: GreekLand.letters,
        reversible: [],
        // Keyed by SINGLE taught letter (LanguagePack.mnemonic looks up L.letter);
        // contrast pairs duplicate the sentence under each letter so it plays
        // whichever one the child is tracing.
        mnemonics: [
            "η": "Τρία γράμματα, ένας ήχος: η, ι, υ λένε όλα «ι». Πες «ιιι» και διάλεξε αυτό που χρειάζεσαι.",
            "ι": "Τρία γράμματα, ένας ήχος: η, ι, υ λένε όλα «ι». Πες «ιιι» και διάλεξε αυτό που χρειάζεσαι.",
            "υ": "Τρία γράμματα, ένας ήχος: η, ι, υ λένε όλα «ι». Πες «ιιι» και διάλεξε αυτό που χρειάζεσαι.",
            "ο": "Το μικρό ο είναι κουμπί, το μεγάλο ω είναι δύο κύματα — μα και τα δύο λένε «ο».",
            "ω": "Το μικρό ο είναι κουμπί, το μεγάλο ω είναι δύο κύματα — μα και τα δύο λένε «ο».",
            "θ": "Το θ έχει γραμμή στη μέση και λέει «θθθ» — γλώσσα στα δόντια.",
            "φ": "Το φ είναι μπάλα με σπαθί και λέει «φφφ» — φύσα.",
            "ξ": "Το ξ έχει τρεις σκάλες και λέει «κσ».",
            "ζ": "Το ζ είναι ένα φιδάκι και λέει «ζζζ».",
            "β": "Μόνο του το β λέει «βββ» σαν βάρκα· τα δύο γράμματα μαζί, μπ, λένε «μπ» σαν μπάλα.",
        ],
        strings: GreekStrings.table
    )
}

/// Greek UI + spoken prompts (immersion mode).
enum GreekStrings {
    static let table: [String: String] = [
        "great_job": "Μπράβο!",
        "hi_lets_read": "Γεια σου %@! Πάμε να διαβάσουμε!",
        "which_read": "Ποιο διάβασες;",
        "daily_review": "Σημερινή Επανάληψη",
        "placement_title": "Από πού ξεκινάμε;",
        "placement_new": "Νέος αναγνώστης — από την αρχή",
        "placement_letters": "Ξέρει μερικά γράμματα",
        "placement_words": "Διαβάζει ήδη απλές λέξεις",
        "locked_hint": "Τελείωσε το προηγούμενο πρώτα!",
        "who_reads": "Ποιος θα διαβάσει σήμερα;",
        "blast_off": "Απογείωση!",
        "blast_off_spoken": "Απογείωση! Μπράβο!",
        "back_to_map": "Πίσω στον χάρτη",
        "got_it": "Το έπιασα!",
        "lets_go": "Πάμε!",
        "try_again_spoken": "Ας ξαναπροσπαθήσουμε!",
        "which_starts": "Τι αρχίζει με…",
        "find_the_letter": "Βρες το γράμμα",
        "tap_what_you_hear": "Πάτα αυτό που ακούς",
        "match_big_little": "Ταίριαξε το μεγάλο και το μικρό",
        "keep_going_uncover": "Συνέχισε για να το αποκαλύψεις!",
        "you_found": "Βρήκες το %@!",
        "my_posters": "Οι αφίσες μου",
        "trace_it": "Γράψε το!",
        "new_sound": "Νέος ήχος!",
        "tap_to_hear": "Πάτα να ακούσεις",
        "say_with_me": "Πες το μαζί μου!",
        "how_to_play": "Πώς να παίξεις",
        "coach_tap": "Πάτα ένα γράμμα για να ακούσεις τον ήχο",
        "coach_slide": "Σύρε τον κομήτη για να το πεις — μετά διάβασέ το!",
        "coach_prove": "Δείξε ότι το διάβασες: διάλεξε εικόνα ή γράψ' το",
        "coach_blast": "Βρες τα σωστά για να απογειωθείς!",
        "drag_sound": "Σύρε το σωστό ζώο στο γράμμα!",
    ]
}