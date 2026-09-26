import Foundation

/// The French (Français) language pack — standard metropolitan pronunciation.
/// We teach each letter's most common single sound: r → /ʁ/ (uvular), j → /ʒ/,
/// u → /y/ (front-rounded), e → /ə/, w → /v/, x → /ks/, y → /i/. Silent h is
/// omitted from the alphabet entirely (like the Spanish pack omitted h).
enum FrenchLand {
    static let letters: [Letter] = [
        Letter(letter: "a", ipa: "a", keyword: "avion",    picture: "✈️"),
        Letter(letter: "o", ipa: "ɔ", keyword: "olive",    picture: "🫒"),
        Letter(letter: "e", ipa: "ə", keyword: "cheval",   picture: "🐴"),
        Letter(letter: "m", ipa: "m", keyword: "main",     picture: "✋"),
        Letter(letter: "s", ipa: "s", keyword: "soleil",   picture: "☀️"),
        Letter(letter: "l", ipa: "l", keyword: "lune",     picture: "🌙"),
        Letter(letter: "i", ipa: "i", keyword: "île",      picture: "🏝️"),
        Letter(letter: "u", ipa: "y", keyword: "usine",    picture: "🏭"),
        Letter(letter: "n", ipa: "n", keyword: "nez",      picture: "👃"),
        Letter(letter: "f", ipa: "f", keyword: "fée",      picture: "🧚"),
        Letter(letter: "p", ipa: "p", keyword: "papa",     picture: "👨"),
        Letter(letter: "t", ipa: "t", keyword: "tomate",   picture: "🍅"),
        Letter(letter: "d", ipa: "d", keyword: "doigt",    picture: "👆"),
        Letter(letter: "r", ipa: "ʁ", keyword: "robot",    picture: "🤖"),
        Letter(letter: "c", ipa: "k", keyword: "carotte",  picture: "🥕"),
        Letter(letter: "g", ipa: "g", keyword: "gâteau",   picture: "🍰"),
        Letter(letter: "b", ipa: "b", keyword: "bateau",   picture: "⛵"),
        Letter(letter: "v", ipa: "v", keyword: "vache",    picture: "🐮"),
        Letter(letter: "j", ipa: "ʒ", keyword: "jardin",   picture: "🌷"),
        Letter(letter: "q", ipa: "k", keyword: "coq",      picture: "🐓"),
        Letter(letter: "z", ipa: "z", keyword: "zèbre",    picture: "🦓"),
        Letter(letter: "y", ipa: "i", keyword: "stylo",    picture: "✏️"),
        Letter(letter: "k", ipa: "k", keyword: "koala",    picture: "🐨"),
        Letter(letter: "w", ipa: "v", keyword: "wagon",    picture: "🚃"),
        Letter(letter: "x", ipa: "ks", keyword: "taxi",    picture: "🚕")
    ]
    static func letter(_ s: String) -> Letter? { letters.first { $0.letter == s } }
    private static let firstSoundGroups: [[String]] = [
        ["a", "m", "s"], ["o", "l", "p"], ["i", "n", "t"], ["f", "d", "v"]
    ]
    private static let letterChunks: [(String, [String])] = [
        ("Lettres : a o e m s l", ["a", "o", "e", "m", "s", "l"]),
        ("Lettres : i u n f p t", ["i", "u", "n", "f", "p", "t"]),
        ("Lettres : d r c g b v", ["d", "r", "c", "g", "b", "v"]),
        ("Lettres : j q z y k",   ["j", "q", "z", "y", "k"]),
        ("Lettres : w x",         ["w", "x"])
    ]
    static let units: [Unit] = {
        let pa: [Lesson] = firstSoundGroups.enumerated().map { i, group in
            Lesson(id: "fr_snd_\(i + 1)", title: "Premiers Sons \(i + 1)", icon: "👂",
                   letters: group.compactMap { letter($0) }, letterActivities: [.firstSound])
        }
        let soundsUnit = Unit(id: "fr_snd", title: "Premiers Sons", colorA: "#FFCD3C", colorB: "#FF9A6B", lessons: pa)
        var letterUnits: [(unit: Unit, letters: [Letter])] = []
        for (gi, chunk) in letterChunks.enumerated() {
            let letters = chunk.1.compactMap { letter($0) }
            let lessons: [Lesson] = letters.map { L in
                Lesson(id: "fr_ltr_\(L.letter)", title: "Lettre \(L.letter.uppercased())", icon: L.picture,
                       letters: [L],
                       letterActivities: [.meet, .trace, .hearTap, .hearTap, .hearTap])
            }
            letterUnits.append((Unit(id: "fr_ltr_\(gi + 1)", title: chunk.0,
                                     colorA: "#67C8FF", colorB: "#A78BFA", lessons: lessons), letters))
        }
        return ReviewLessons.assemble(soundsUnit: soundsUnit, letterUnits: letterUnits,
                                      reviewTitle: "Associe les Sons", idPrefix: "fr",
                                      wordUnits: FrenchLand.wordUnits,
                                      spellTitle: "Écris-le !",
                                      practiceTitle: "Entraînement !", mixTitle: "Mélange !")
    }()
}

extension LanguagePack {
    static let french = LanguagePack(
        id: "fr", name: "French", nativeName: "Français", flag: "🇫🇷",
        ttsLocale: "fr-FR", rtl: false,
        letters: FrenchLand.letters,
        reversible: ["b", "d", "p", "q"],
        mnemonics: ["b": "Le b a son ballon DEVANT son bâton.", "d": "Le d a son dos rond DERRIÈRE — d comme « dos ».", "p": "Le p plonge sa patte SOUS la ligne.", "q": "Le q a sa queue qui descend en bas.", "n": "Le n a deux pattes, comme un petit pont.", "m": "Le m a trois pattes — « mmm », la montagne.", "u": "Le u est une tasse en haut — « uuu ».", "i": "Le i a un point sur la tête, tout petit."],
        strings: FrenchStrings.table
    )
}

enum FrenchStrings {
    static let table: [String: String] = [
        "great_job": "Bravo !",
        "hi_lets_read": "Bonjour %@ ! On va lire !",
        "which_read": "Qu'as-tu lu ?",
        "daily_review": "Révision du jour",
        "placement_title": "On commence où ?",
        "placement_new": "Tout nouveau lecteur — depuis le début",
        "placement_letters": "Connaît quelques lettres",
        "placement_words": "Lit déjà des mots simples",
        "locked_hint": "Termine d'abord le précédent !",
        "who_reads": "Qui va lire aujourd'hui ?",
        "blast_off": "Décollage !",
        "blast_off_spoken": "Décollage ! Bravo !",
        "back_to_map": "Retour à la carte",
        "got_it": "Compris !",
        "lets_go": "Allons-y !",
        "try_again_spoken": "On réessaie !",
        "which_starts": "Lequel commence par… ?",
        "find_the_letter": "Trouve la lettre",
        "tap_what_you_hear": "Touche ce que tu entends",
        "match_big_little": "Relie la grande et la petite",
        "keep_going_uncover": "Continue pour la découvrir !",
        "you_found": "Tu as trouvé le %@ !",
        "my_posters": "Mes affiches",
        "new_sound": "Nouveau son !",
        "tap_to_hear": "Touche pour écouter",
        "say_with_me": "Dis-le avec moi !",
        "how_to_play": "Comment jouer",
        "coach_tap": "Touche une lettre pour entendre son son",
        "coach_slide": "Fais glisser le cerf-volant pour la sonoriser — puis lis-la !",
        "coach_prove": "Montre que tu l'as lue : choisis l'image ou écris-la",
        "coach_blast": "Réussis pour décoller !",
        "trace_it": "Trace-la !",
        "drag_sound": "Fais glisser le bon animal vers la lettre !",
    ]
}