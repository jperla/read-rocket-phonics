import Foundation

/// One letter the child is learning: the letter, its sound (IPA), and a keyword
/// picture (e.g. s → ☀️ "sun"). Used by the pre-reader on-ramp.
struct Letter: Equatable, Hashable {
    let letter: String
    let ipa: String
    let keyword: String
    let picture: String
}

/// Which letter activity a step presents.
/// `matchCase` = match the BIG letter to its little one (uppercase↔lowercase), a
/// matching-game for variety and extra recognition reps.
enum LetterActivity: String, Equatable {
    case meet, trace, find, hearTap, firstSound, matchCase
    /// Drag the animal (which says the sound) onto the matching letter — a
    /// kinesthetic sound→letter discrimination among several letters.
    case soundToLetter
}

/// The pre-reader ON-RAMP — everything that comes BEFORE blending whole words,
/// for a 3-year-old who barely knows letters. Two phases:
///   1. "First Sounds" — pure phonemic awareness (hear a sound, tap the picture
///      that starts with it). No letters required.
///   2. "Letter Sounds" — single letters in SATPIN order (s a t i p n, …), which
///      keeps the reversible letters b/d/p/q far apart so they're never confused.
///      Each letter lesson: meet it → trace → hear→tap → find → match Aa (no
///      first-sound picture-pick — that stays in the First Sounds unit only).
enum LetterLand {

    /// CONTINUOUS-SOUND-FIRST order (research-grounded). The opening group is all
    /// stretchable continuant sounds + vowels (s a m f i n) so the very first
    /// blends use sounds a child can hold ("sssaaammm") rather than stops that
    /// distort to "buh". Reversible letters are deliberately spread far apart:
    /// d(9) · b(17) · p(19) · q(25) — never adjacent (enforced by a unit test).
    static let letters: [Letter] = [
        // Group 1 — continuants + vowels (blend-friendly from lesson one)
        Letter(letter: "s", ipa: "s", keyword: "sun", picture: "☀️"),
        Letter(letter: "a", ipa: "æ", keyword: "apple", picture: "🍎"),
        Letter(letter: "m", ipa: "m", keyword: "moon", picture: "🌙"),
        Letter(letter: "f", ipa: "f", keyword: "fish", picture: "🐟"),
        Letter(letter: "i", ipa: "ɪ", keyword: "igloo", picture: "🧊"),
        Letter(letter: "n", ipa: "n", keyword: "nest", picture: "🪺"),
        // Group 2 — first stops + more vowels
        Letter(letter: "t", ipa: "t", keyword: "turtle", picture: "🐢"),
        Letter(letter: "o", ipa: "ɑ", keyword: "octopus", picture: "🐙"),
        Letter(letter: "d", ipa: "d", keyword: "dog", picture: "🐶"),
        Letter(letter: "l", ipa: "l", keyword: "leaf", picture: "🍃"),
        Letter(letter: "h", ipa: "h", keyword: "hat", picture: "🎩"),
        Letter(letter: "e", ipa: "ɛ", keyword: "egg", picture: "🥚"),
        // Group 3
        Letter(letter: "g", ipa: "g", keyword: "goat", picture: "🐐"),
        Letter(letter: "u", ipa: "ʌ", keyword: "umbrella", picture: "☂️"),
        Letter(letter: "c", ipa: "k", keyword: "cat", picture: "🐱"),
        Letter(letter: "r", ipa: "r", keyword: "rabbit", picture: "🐰"),
        Letter(letter: "b", ipa: "b", keyword: "bug", picture: "🐛"),
        Letter(letter: "k", ipa: "k", keyword: "kite", picture: "🪁"),
        // Group 4
        Letter(letter: "p", ipa: "p", keyword: "pig", picture: "🐷"),
        Letter(letter: "j", ipa: "dʒ", keyword: "jam", picture: "🍓"),
        Letter(letter: "v", ipa: "v", keyword: "van", picture: "🚐"),
        Letter(letter: "w", ipa: "w", keyword: "web", picture: "🕸️"),
        Letter(letter: "y", ipa: "j", keyword: "yoyo", picture: "🪀"),
        Letter(letter: "z", ipa: "z", keyword: "zebra", picture: "🦓"),
        // Group 5
        Letter(letter: "q", ipa: "kw", keyword: "queen", picture: "👑"),
        Letter(letter: "x", ipa: "ks", keyword: "fox", picture: "🦊")
    ]

    static func letter(_ s: String) -> Letter? { letters.first { $0.letter == s } }

    /// All keyword pictures, for building distractors.
    static let allPictures: [String] = letters.map { $0.picture }
    static let allLetters: [String] = letters.map { $0.letter }

    // MARK: - Reversible letters (b / d / p / q)

    /// The letters young readers most often flip. Forming the shape over and over
    /// is what builds the motor memory that disambiguates them, so these get many
    /// more tracing reps than the rest (a 3yo "traces it again and again").
    static let reversible: Set<String> = ["b", "d", "p", "q"]

    /// How many times a letter is traced in its trace activity. Reversible letters
    /// get one extra rep because the shape is hard; everything else once.
    /// (2, not more — repeated forced retracing reads as failure to a child.)
    static func traceReps(_ letter: String) -> Int {
        reversible.contains(letter) ? 2 : 1
    }

    /// A spoken + on-screen shape mnemonic for the most-confused pair. The bump is
    /// the baby's belly out front (b) vs. the diaper round the back (d) — said out
    /// loud every trace so "which way does the bump go" sticks. Returns the display
    /// line (also the audio lookup key, lowercased) or nil for letters without one.
    static func mnemonic(_ letter: String) -> String? {
        switch letter {
        case "b": return "B is for belly!"
        case "d": return "D is for diaper!"
        default:  return nil
        }
    }

    // MARK: - Units

    /// 1. Phonemic awareness ("First Sounds"): hear a sound → tap the picture that
    /// starts with it. Each lesson groups a few well-separated sounds (no letters).
    private static let firstSoundGroups: [[String]] = [
        ["s", "a", "m"], ["t", "p", "i"], ["n", "c", "h"], ["d", "o", "f"]
    ]

    /// 2. Letter-sound lessons, chunked into units of six in SATPIN order.
    private static let letterChunks: [(String, [String])] = [
        ("Letters: s a t i p n", ["s","a","t","i","p","n"]),
        ("Letters: c e h r m d", ["c","e","h","r","m","d"]),
        ("Letters: g o k u l f", ["g","o","k","u","l","f"]),
        ("Letters: b j v w y z", ["b","j","v","w","y","z"]),
        ("Letters: q x", ["q","x"])
    ]

    static let units: [Unit] = {
        // First Sounds (phonemic awareness)
        let paLessons: [Lesson] = firstSoundGroups.enumerated().map { i, group in
            Lesson(id: "snd_\(i + 1)", title: "First Sounds \(i + 1)", icon: "👂",
                   letters: group.compactMap { letter($0) },
                   letterActivities: [.firstSound])
        }
        let soundsUnit = Unit(id: "snd", title: "First Sounds", colorA: "#FFCD3C", colorB: "#FF9A6B", lessons: paLessons)

        // Letter Sounds (SATPIN) — meet the letter, trace it, then ONE challenge
        // type repeated (Mentava-style focus: kids improve by repeating the same
        // activity within a lesson; variety lives BETWEEN lessons, not inside one).
        var letterUnits: [(unit: Unit, letters: [Letter])] = []
        for (gi, chunk) in letterChunks.enumerated() {
            let letters = chunk.1.compactMap { letter($0) }
            let lessons: [Lesson] = letters.map { L in
                Lesson(id: "ltr_\(L.letter)", title: "Letter \(L.letter.uppercased())", icon: L.picture,
                       letters: [L],
                       letterActivities: [.meet, .trace, .hearTap, .hearTap, .hearTap])
            }
            letterUnits.append((Unit(id: "ltr_\(gi + 1)", title: chunk.0,
                                     colorA: "#67C8FF", colorB: "#A78BFA", lessons: lessons), letters))
        }
        // Interleave discrimination reviews + a big one before words (Curriculum
        // appends the English word units after these).
        return ReviewLessons.assemble(soundsUnit: soundsUnit, letterUnits: letterUnits,
                                      reviewTitle: "Sound Match", idPrefix: "en", wordUnits: [])
    }()

    static let lessonIDs: [String] = units.flatMap { $0.lessons.map { $0.id } }
}
