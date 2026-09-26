import Foundation

/// The British English (UK / Received Pronunciation) language pack — taught with
/// UK SYSTEMATIC SYNTHETIC PHONICS (Letters & Sounds). The letters are introduced
/// in the official Phase 2/3 TEACHING ORDER (s a t p i n / m d g o c k / e u r h
/// b f l / j v w x y z) so the very first lessons can already blend real words
/// (sat, pin, tap…). We teach the SOUND, never the letter name.
///
/// RP NOTES that distinguish this pack from the General-American `english` pack:
///   • **o = /ɒ/** (the British LOT vowel: dog, hot, lot) — NOT /ɑ/.
///   • **NON-RHOTIC**: the r-controlled vowel teams (ar, or, ur, ir, air, ear,
///     ure) produce a pure RP vowel and **no /r/ is sounded** (car → /kɑː/, not
///     /kɑɹ/). That lives in `EnglishUKPhonics.map` (see EnglishUKWords.swift).
///   • `qu` is taught as a Phase-3 digraph (/kw/), not a base letter, so the base
///     alphabet is the plain 26 a–z minus q (taught inside the qu digraph).
enum EnglishUKLand {
    static let letters: [Letter] = [
        // Group 1 — s a t p i n  (the famous first set: blendable from lesson one)
        Letter(letter: "s", ipa: "s", keyword: "sun",      picture: "☀️"),
        Letter(letter: "a", ipa: "æ", keyword: "apple",    picture: "🍎"),
        Letter(letter: "t", ipa: "t", keyword: "tap",      picture: "🚰"),
        Letter(letter: "p", ipa: "p", keyword: "pig",      picture: "🐷"),
        Letter(letter: "i", ipa: "ɪ", keyword: "insect",   picture: "🐜"),
        Letter(letter: "n", ipa: "n", keyword: "net",      picture: "🥅"),
        // Group 2 — m d g o c k
        Letter(letter: "m", ipa: "m", keyword: "mouse",    picture: "🐭"),
        Letter(letter: "d", ipa: "d", keyword: "dog",      picture: "🐶"),
        Letter(letter: "g", ipa: "g", keyword: "goat",     picture: "🐐"),
        Letter(letter: "o", ipa: "ɒ", keyword: "orange",   picture: "🍊"),
        Letter(letter: "c", ipa: "k", keyword: "cat",      picture: "🐱"),
        Letter(letter: "k", ipa: "k", keyword: "kite",     picture: "🪁"),
        // Group 3 — e u r h b f l
        Letter(letter: "e", ipa: "e", keyword: "egg",      picture: "🥚"),
        Letter(letter: "u", ipa: "ʌ", keyword: "umbrella", picture: "☂️"),
        Letter(letter: "r", ipa: "r", keyword: "rabbit",   picture: "🐰"),
        Letter(letter: "h", ipa: "h", keyword: "hat",      picture: "🎩"),
        Letter(letter: "b", ipa: "b", keyword: "ball",     picture: "⚽"),
        Letter(letter: "f", ipa: "f", keyword: "fish",     picture: "🐟"),
        Letter(letter: "l", ipa: "l", keyword: "leg",      picture: "🦵"),
        // Group 4 — j v w x y z
        Letter(letter: "j", ipa: "dʒ", keyword: "jam",     picture: "🍓"),
        Letter(letter: "v", ipa: "v", keyword: "van",      picture: "🚐"),
        Letter(letter: "w", ipa: "w", keyword: "web",      picture: "🕸️"),
        Letter(letter: "x", ipa: "ks", keyword: "fox",     picture: "🦊"),
        Letter(letter: "y", ipa: "j", keyword: "yo-yo",    picture: "🪀"),
        Letter(letter: "z", ipa: "z", keyword: "zip",      picture: "🤐")
    ]

    static func letter(_ s: String) -> Letter? { letters.first { $0.letter == s } }

    /// Phonemic awareness — clear single-sound letters, satpin-friendly groups.
    private static let firstSoundGroups: [[String]] = [
        ["s", "a", "t"], ["p", "i", "n"], ["m", "d", "g"], ["o", "c", "k"]
    ]

    /// Letter-sound lessons, chunked in the Letters & Sounds Phase 2/3 order.
    private static let letterChunks: [(String, [String])] = [
        ("Letters: s a t p i n", ["s", "a", "t", "p", "i", "n"]),
        ("Letters: m d g o c k", ["m", "d", "g", "o", "c", "k"]),
        ("Letters: e u r h b f l", ["e", "u", "r", "h", "b", "f", "l"]),
        ("Letters: j v w x y z", ["j", "v", "w", "x", "y", "z"])
    ]

    static let units: [Unit] = {
        let pa: [Lesson] = firstSoundGroups.enumerated().map { i, group in
            Lesson(id: "en-GB_snd_\(i + 1)", title: "First Sounds \(i + 1)", icon: "👂",
                   letters: group.compactMap { letter($0) }, letterActivities: [.firstSound])
        }
        let soundsUnit = Unit(id: "en-GB_snd", title: "First Sounds", colorA: "#FFCD3C", colorB: "#FF9A6B", lessons: pa)
        var letterUnits: [(unit: Unit, letters: [Letter])] = []
        for (gi, chunk) in letterChunks.enumerated() {
            let letters = chunk.1.compactMap { letter($0) }
            let lessons: [Lesson] = letters.map { L in
                Lesson(id: "en-GB_ltr_\(L.letter)", title: "Letter \(L.letter.uppercased())", icon: L.picture,
                       letters: [L],
                       letterActivities: [.meet, .trace, .hearTap, .hearTap, .hearTap])
            }
            letterUnits.append((Unit(id: "en-GB_ltr_\(gi + 1)", title: chunk.0,
                                     colorA: "#67C8FF", colorB: "#A78BFA", lessons: lessons), letters))
        }
        return ReviewLessons.assemble(soundsUnit: soundsUnit, letterUnits: letterUnits,
                                      reviewTitle: "Match the Sounds", idPrefix: "en-GB",
                                      wordUnits: EnglishUKLand.wordUnits,
                                      spellTitle: "Spell it!")
    }()
}

extension LanguagePack {
    static let englishUK = LanguagePack(
        id: "en-GB", name: "English (UK)", nativeName: "English (UK)", flag: "🇬🇧",
        ttsLocale: "en-GB", rtl: false,
        letters: EnglishUKLand.letters,
        // No bare "q" — the UK scheme teaches only the 25 satpin-order letters
        // (qu appears later as a word-unit grapheme), so q can't be traced here.
        reversible: ["b", "d", "p"],
        mnemonics: ["b": "b has its belly out the front; d has its bump round the back.",
                    "d": "d starts with its circle on the left; b has the circle on the right.",
                    "p": "p points its tail down below the line.",
                    "m": "m has three legs; n has only two.",
                    "n": "n has two legs; m has three — m is bigger.",
                    "c": "c is the open mouth of the cat sound: /k/.",
                    "f": "f is the quiet one — v is its buzzy twin.",
                    "v": "v buzzes — feel your throat; quiet f does not."],
        strings: LanguagePack.english.strings
    )
}