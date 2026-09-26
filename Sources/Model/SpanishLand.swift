import Foundation

/// The Spanish (Español) language pack — Latin-American pronunciation (seseo:
/// c/z/s → /s/; ll/y → /ʝ/; j → /x/; v → /b/). Spanish is beautifully phonetic.
/// v1 covers 26 letters with a teachable sound; silent **h** and the digraphs
/// (ch, ll, rr) are a v2 grapheme layer (see ADDING_A_LANGUAGE.md). We teach the
/// SOUND, never the letter name.
///
/// NOTE on **r**: word-INITIAL r is always trilled /r/ in Spanish, so no real
/// kid word can begin with the single tap /ɾ/. We therefore teach the tap with
/// an intervocalic keyword (**pera**) where the sound is genuinely /ɾ/, and keep
/// all decodable single-r words to intervocalic (tap) position only. The trill
/// lives entirely in the **rr** digraph unit.
enum SpanishLand {
    static let letters: [Letter] = [
        // Group 1 — vowels + easy continuants
        Letter(letter: "a", ipa: "a", keyword: "árbol",    picture: "🌳"),
        Letter(letter: "o", ipa: "o", keyword: "oso",      picture: "🐻"),
        Letter(letter: "e", ipa: "e", keyword: "elefante", picture: "🐘"),
        Letter(letter: "m", ipa: "m", keyword: "mano",     picture: "✋"),
        Letter(letter: "s", ipa: "s", keyword: "sol",      picture: "☀️"),
        Letter(letter: "l", ipa: "l", keyword: "luna",     picture: "🌙"),
        // Group 2
        Letter(letter: "i", ipa: "i", keyword: "iglú",     picture: "🧊"),
        Letter(letter: "u", ipa: "u", keyword: "uvas",     picture: "🍇"),
        Letter(letter: "n", ipa: "n", keyword: "nariz",    picture: "👃"),
        Letter(letter: "f", ipa: "f", keyword: "foca",     picture: "🦭"),
        Letter(letter: "p", ipa: "p", keyword: "pato",     picture: "🦆"),
        Letter(letter: "t", ipa: "t", keyword: "tomate",   picture: "🍅"),
        // Group 3
        Letter(letter: "d", ipa: "d", keyword: "dedo",     picture: "👆"),
        Letter(letter: "r", ipa: "ɾ", keyword: "pera",     picture: "🍐"),
        Letter(letter: "c", ipa: "k", keyword: "casa",     picture: "🏠"),
        Letter(letter: "g", ipa: "g", keyword: "gato",     picture: "🐱"),
        Letter(letter: "b", ipa: "b", keyword: "barco",    picture: "⛵"),
        Letter(letter: "v", ipa: "b", keyword: "vaca",     picture: "🐮"),
        // Group 4
        Letter(letter: "j", ipa: "x", keyword: "jirafa",   picture: "🦒"),
        Letter(letter: "ñ", ipa: "ɲ", keyword: "ñandú",    picture: "🦤"),
        Letter(letter: "q", ipa: "k", keyword: "queso",    picture: "🧀"),
        Letter(letter: "z", ipa: "s", keyword: "zapato",   picture: "👟"),
        Letter(letter: "y", ipa: "ʝ", keyword: "yoyo",     picture: "🪀"),
        // Group 5 — rarer letters
        Letter(letter: "k", ipa: "k", keyword: "koala",      picture: "🐨"),
        Letter(letter: "w", ipa: "w", keyword: "waterpolo",  picture: "🤽"),
        Letter(letter: "x", ipa: "ks", keyword: "taxi",      picture: "🚕")
    ]

    static func letter(_ s: String) -> Letter? { letters.first { $0.letter == s } }

    /// Phonemic awareness — clear word-initial sounds only.
    private static let firstSoundGroups: [[String]] = [
        ["a", "m", "s"], ["o", "l", "p"], ["e", "n", "t"], ["i", "f", "d"]
    ]

    private static let letterChunks: [(String, [String])] = [
        ("Letras: a o e m s l", ["a", "o", "e", "m", "s", "l"]),
        ("Letras: i u n f p t", ["i", "u", "n", "f", "p", "t"]),
        ("Letras: d r c g b v", ["d", "r", "c", "g", "b", "v"]),
        ("Letras: j ñ q z y",   ["j", "ñ", "q", "z", "y"]),
        ("Letras: k w x",       ["k", "w", "x"])
    ]

    static let units: [Unit] = {
        let pa: [Lesson] = firstSoundGroups.enumerated().map { i, group in
            Lesson(id: "es_snd_\(i + 1)", title: "Primeros Sonidos \(i + 1)", icon: "👂",
                   letters: group.compactMap { letter($0) }, letterActivities: [.firstSound])
        }
        let soundsUnit = Unit(id: "es_snd", title: "Primeros Sonidos", colorA: "#FFCD3C", colorB: "#FF9A6B", lessons: pa)
        var letterUnits: [(unit: Unit, letters: [Letter])] = []
        for (gi, chunk) in letterChunks.enumerated() {
            let letters = chunk.1.compactMap { letter($0) }
            let lessons: [Lesson] = letters.map { L in
                Lesson(id: "es_ltr_\(L.letter)", title: "Letra \(L.letter.uppercased())", icon: L.picture,
                       letters: [L],
                       letterActivities: [.meet, .trace, .hearTap, .hearTap, .hearTap])
            }
            letterUnits.append((Unit(id: "es_ltr_\(gi + 1)", title: chunk.0,
                                     colorA: "#67C8FF", colorB: "#A78BFA", lessons: lessons), letters))
        }
        return ReviewLessons.assemble(soundsUnit: soundsUnit, letterUnits: letterUnits,
                                      reviewTitle: "Empareja Sonidos", idPrefix: "es",
                                      wordUnits: SpanishLand.wordUnits,
                                      spellTitle: "¡Escríbelo!",
                                      practiceTitle: "¡A practicar!", mixTitle: "¡Mézclalo!")
    }()
}

extension LanguagePack {
    static let spanish = LanguagePack(
        id: "es", name: "Spanish", nativeName: "Español", flag: "🇪🇸",
        ttsLocale: "es-MX", rtl: false,
        letters: SpanishLand.letters,
        reversible: ["b", "d", "p", "q"],
        // Keyed by SINGLE taught letter (LanguagePack.mnemonic looks up L.letter);
        // contrast pairs duplicate the text under both letters. (The old "ll"/"rr"
        // digraph entries were dropped — neither is a v1 taught letter.)
        mnemonics: [
            "b": "La b tiene barriga; la v tiene valle. ¡Suenan igual: bee!",
            "v": "La v tiene valle; la b tiene barriga. ¡Suenan igual: bee!",
            "p": "La p mira para abajo; la q mira para arriba con su colita.",
            "q": "La q mira para arriba con su colita; la p mira para abajo.",
            "d": "La d empieza con su circulito a la izquierda; la b lo tiene a la derecha.",
            "m": "La m tiene tres montañas; la n tiene solo dos.",
            "n": "La n tiene dos montañas; la m tiene tres.",
            "c": "Antes de e o i, la c suena suave como la s: ce, ci, se, si.",
            "s": "Antes de e o i, la c suena suave como la s: ce, ci, se, si.",
            "g": "Antes de e o i, la g suena como la j: ge, gi, je, ji.",
            "j": "Antes de e o i, la g suena como la j: ge, gi, je, ji.",
            "ñ": "La ñ lleva sombrerito y dice eñe; la n no lo tiene.",
        ],
        strings: SpanishStrings.table
    )
}

enum SpanishStrings {
    static let table: [String: String] = [
        "great_job": "¡Muy bien!",
        "hi_lets_read": "¡Hola, %@! ¡A leer!",
        "which_read": "¿Cuál leíste?",
        "daily_review": "Repaso de hoy",
        "placement_title": "¿Por dónde empezamos?",
        "placement_new": "Lector nuevo — desde el principio",
        "placement_letters": "Conoce algunas letras",
        "placement_words": "Ya lee palabras sencillas",
        "locked_hint": "¡Termina el anterior primero!",
        "who_reads": "¿Quién va a leer hoy?",
        "blast_off": "¡Despegue!",
        "blast_off_spoken": "¡Despegue! ¡Muy bien!",
        "back_to_map": "Volver al mapa",
        "got_it": "¡Lo tengo!",
        "lets_go": "¡Vamos!",
        "try_again_spoken": "¡Intentémoslo otra vez!",
        "which_starts": "¿Cuál empieza con…?",
        "find_the_letter": "Encuentra la letra",
        "tap_what_you_hear": "Toca lo que escuchas",
        "match_big_little": "Une la grande y la pequeña",
        "keep_going_uncover": "¡Sigue para descubrirla!",
        "you_found": "¡Encontraste el %@!",
        "my_posters": "Mis pósters",
        "new_sound": "¡Sonido nuevo!",
        "tap_to_hear": "Toca para escuchar",
        "say_with_me": "¡Dilo conmigo!",
        "how_to_play": "Cómo jugar",
        "coach_tap": "Toca una letra para oír su sonido",
        "coach_slide": "Desliza el cometa para sonarla — ¡luego léela!",
        "coach_prove": "Demuestra que la leíste: elige la imagen o escríbela",
        "coach_blast": "¡Acierta para despegar!",
        "trace_it": "¡Trázala!",
        "drag_sound": "¡Arrastra el animal correcto a la letra!",
    ]
}