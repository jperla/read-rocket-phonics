import Foundation

/// The German (Deutsch) language pack — standard High German pronunciation.
/// Letter sounds: h/h/ is pronounced, j/j/ is a y-glide, v→/f/, w→/v/, s→/z/,
/// z→/ts/, c/q→/k/, r→/ʁ/ (uvular), y→/y/, x→/ks/; vowels a e i o u are pure;
/// ä→/ɛ/, ö→/ø/, ü→/y/, ß→/s/. German is highly phonetic.
enum GermanLand {
    static let letters: [Letter] = [
        Letter(letter: "a", ipa: "a", keyword: "Affe",   picture: "🐵"),
        Letter(letter: "o", ipa: "o", keyword: "Ohr",    picture: "👂"),
        Letter(letter: "e", ipa: "e", keyword: "Esel",   picture: "🫏"),
        Letter(letter: "m", ipa: "m", keyword: "Maus",   picture: "🐭"),
        Letter(letter: "s", ipa: "z", keyword: "Sonne",  picture: "☀️"),
        Letter(letter: "l", ipa: "l", keyword: "Löwe",   picture: "🦁"),
        Letter(letter: "i", ipa: "i", keyword: "Igel",   picture: "🦔"),
        Letter(letter: "u", ipa: "u", keyword: "Uhr",    picture: "🕐"),
        Letter(letter: "n", ipa: "n", keyword: "Nase",   picture: "👃"),
        Letter(letter: "f", ipa: "f", keyword: "Fisch",  picture: "🐟"),
        Letter(letter: "p", ipa: "p", keyword: "Pilz",   picture: "🍄"),
        Letter(letter: "t", ipa: "t", keyword: "Tisch",  picture: "🪑"),
        Letter(letter: "d", ipa: "d", keyword: "Dose",   picture: "🥫"),
        Letter(letter: "r", ipa: "ʁ", keyword: "Rose",   picture: "🌹"),
        Letter(letter: "h", ipa: "h", keyword: "Hand",   picture: "✋"),
        Letter(letter: "k", ipa: "k", keyword: "Katze",  picture: "🐱"),
        Letter(letter: "g", ipa: "g", keyword: "Gabel",  picture: "🍴"),
        Letter(letter: "b", ipa: "b", keyword: "Ball",   picture: "⚽"),
        Letter(letter: "j", ipa: "j", keyword: "Jacke",  picture: "🧥"),
        Letter(letter: "v", ipa: "f", keyword: "Vogel",  picture: "🐦"),
        Letter(letter: "w", ipa: "v", keyword: "Wolke",  picture: "☁️"),
        Letter(letter: "z", ipa: "ts", keyword: "Zebra", picture: "🦓"),
        Letter(letter: "c", ipa: "k", keyword: "Computer", picture: "💻"),
        Letter(letter: "q", ipa: "kv", keyword: "Qualle", picture: "🪼"),
        Letter(letter: "y", ipa: "y", keyword: "Ypsilon", picture: "🔤"),
        Letter(letter: "x", ipa: "ks", keyword: "Xylofon", picture: "🎹"),
        Letter(letter: "ä", ipa: "ɛ", keyword: "Ärztin", picture: "🧑‍⚕️"),
        Letter(letter: "ö", ipa: "ø", keyword: "Öl",     picture: "🛢️"),
        Letter(letter: "ü", ipa: "y", keyword: "Übung",  picture: "🤸"),
        Letter(letter: "ß", ipa: "s", keyword: "Fuß",    picture: "🦶")
    ]
    static func letter(_ s: String) -> Letter? { letters.first { $0.letter == s } }
    private static let firstSoundGroups: [[String]] = [
        ["a", "m", "s"], ["o", "l", "n"], ["e", "f", "t"], ["i", "p", "d"]
    ]
    private static let letterChunks: [(String, [String])] = [
        ("Buchstaben: a o e m s l", ["a", "o", "e", "m", "s", "l"]),
        ("Buchstaben: i u n f p t", ["i", "u", "n", "f", "p", "t"]),
        ("Buchstaben: d r h k g b", ["d", "r", "h", "k", "g", "b"]),
        ("Buchstaben: j v w z c q", ["j", "v", "w", "z", "c", "q"]),
        ("Buchstaben: y x ä ö ü ß", ["y", "x", "ä", "ö", "ü", "ß"])
    ]
    static let units: [Unit] = {
        let pa: [Lesson] = firstSoundGroups.enumerated().map { i, group in
            Lesson(id: "de_snd_\(i + 1)", title: "Erste Laute \(i + 1)", icon: "👂",
                   letters: group.compactMap { letter($0) }, letterActivities: [.firstSound])
        }
        let soundsUnit = Unit(id: "de_snd", title: "Erste Laute", colorA: "#FFCD3C", colorB: "#FF9A6B", lessons: pa)
        var letterUnits: [(unit: Unit, letters: [Letter])] = []
        for (gi, chunk) in letterChunks.enumerated() {
            let letters = chunk.1.compactMap { letter($0) }
            let lessons: [Lesson] = letters.map { L in
                Lesson(id: "de_ltr_\(L.letter)", title: "Buchstabe \(L.letter.uppercased())", icon: L.picture,
                       letters: [L],
                       letterActivities: [.meet, .trace, .hearTap, .hearTap, .hearTap])
            }
            letterUnits.append((Unit(id: "de_ltr_\(gi + 1)", title: chunk.0,
                                     colorA: "#67C8FF", colorB: "#A78BFA", lessons: lessons), letters))
        }
        return ReviewLessons.assemble(soundsUnit: soundsUnit, letterUnits: letterUnits,
                                      reviewTitle: "Laute Zuordnen", idPrefix: "de",
                                      wordUnits: GermanLand.wordUnits,
                                      spellTitle: "Schreib es!",
                                      practiceTitle: "Üben!", mixTitle: "Gemischt!")
    }()
}

extension LanguagePack {
    static let german = LanguagePack(
        id: "de", name: "German", nativeName: "Deutsch", flag: "🇩🇪",
        ttsLocale: "de-DE", rtl: false,
        letters: GermanLand.letters,
        reversible: ["b", "d", "p", "q"],
        // Keyed by single TAUGHT letters only (mnemonic lookup uses L.letter).
        // The old "ei"/"ie"/"eu" entries were dead data — those digraphs are
        // introduced as word-unit graphemes, never as traceable letters.
        mnemonics: [
            "b": "b hat den bauch hinten — wie ein bauch nach rechts.",
            "d": "d hat den bauch vorne, links — wie ein dicker bauch.",
            "p": "p hat den bauch oben und das bein hängt nach unten.",
            "q": "q hat den bauch oben links und ein schwänzchen nach unten — q kommt mit u: qu.",
            "m": "m hat zwei berge — mmm, der mund macht zwei hügel.",
            "n": "n hat nur einen berg — ein hügel weniger als m.",
            "ä": "ä ist ein helles e mit zwei punkten — der bär brummt: bäär.",
            "ü": "ü spitz den mund wie zum pfeifen und sag i — die tür.",
            "ß": "ß ist ein scharfes s — der fuß, ganz scharf gezischt: ssss.",
        ],
        strings: GermanStrings.table
    )
}

enum GermanStrings {
    static let table: [String: String] = [
        "great_job": "Sehr gut!",
        "hi_lets_read": "Hallo %@! Lass uns lesen!",
        "which_read": "Was hast du gelesen?",
        "daily_review": "Heute üben",
        "placement_title": "Wo fangen wir an?",
        "placement_new": "Ganz neu — von Anfang an",
        "placement_letters": "Kennt schon einige Buchstaben",
        "placement_words": "Liest schon einfache Wörter",
        "locked_hint": "Mach zuerst das davor fertig!",
        "who_reads": "Wer liest heute?",
        "blast_off": "Abheben!",
        "blast_off_spoken": "Abheben! Sehr gut!",
        "back_to_map": "Zurück zur Karte",
        "got_it": "Ich hab's!",
        "lets_go": "Los geht's!",
        "try_again_spoken": "Versuchen wir es noch einmal!",
        "which_starts": "Was beginnt mit…?",
        "find_the_letter": "Finde den Buchstaben",
        "tap_what_you_hear": "Tippe, was du hörst",
        "match_big_little": "Verbinde groß und klein",
        "keep_going_uncover": "Mach weiter, um es zu entdecken!",
        "you_found": "Du hast %@ gefunden!",
        "my_posters": "Meine Poster",
        "new_sound": "Neuer Laut!",
        "tap_to_hear": "Tippe zum Hören",
        "say_with_me": "Sag es mit mir!",
        "how_to_play": "So wird gespielt",
        "coach_tap": "Tippe einen Buchstaben, um seinen Laut zu hören",
        "coach_slide": "Zieh den Kometen, um ihn zu lauten — dann lies ihn!",
        "coach_prove": "Zeig, dass du es gelesen hast: wähle das Bild oder schreib es",
        "coach_blast": "Triff richtig, um abzuheben!",
        "trace_it": "Zeichne ihn nach!",
        "drag_sound": "Zieh das richtige Tier auf den Buchstaben!",
    ]
}