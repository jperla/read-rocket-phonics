import Foundation

/// The Portuguese (Português) language pack — Brazilian pronunciation
/// (j → /ʒ/; x → /ʃ/; word-initial r → /h/; v → /v/; w (foreign) → /w/; c/q/k → /k/;
/// t/d palatalize to /tʃ//dʒ/ before /i/). We omit the silent letter h.
enum PortugueseLand {
    static let letters: [Letter] = [
        Letter(letter: "a", ipa: "a", keyword: "avião",   picture: "✈️"),
        Letter(letter: "o", ipa: "o", keyword: "ovo",     picture: "🥚"),
        Letter(letter: "e", ipa: "e", keyword: "elefante", picture: "🐘"),
        Letter(letter: "m", ipa: "m", keyword: "mão",     picture: "✋"),
        Letter(letter: "s", ipa: "s", keyword: "sol",     picture: "☀️"),
        Letter(letter: "l", ipa: "l", keyword: "lua",     picture: "🌙"),
        Letter(letter: "i", ipa: "i", keyword: "ilha",    picture: "🏝️"),
        Letter(letter: "u", ipa: "u", keyword: "uva",     picture: "🍇"),
        Letter(letter: "n", ipa: "n", keyword: "nariz",   picture: "👃"),
        Letter(letter: "f", ipa: "f", keyword: "foca",    picture: "🦭"),
        Letter(letter: "p", ipa: "p", keyword: "pato",    picture: "🦆"),
        Letter(letter: "t", ipa: "t", keyword: "tatu",    picture: "🦫"),
        Letter(letter: "d", ipa: "d", keyword: "dado",    picture: "🎲"),
        Letter(letter: "r", ipa: "h", keyword: "rato",    picture: "🐀"),
        Letter(letter: "c", ipa: "k", keyword: "casa",    picture: "🏠"),
        Letter(letter: "g", ipa: "g", keyword: "gato",    picture: "🐱"),
        Letter(letter: "b", ipa: "b", keyword: "bola",    picture: "⚽"),
        Letter(letter: "v", ipa: "v", keyword: "vaca",    picture: "🐮"),
        Letter(letter: "j", ipa: "ʒ", keyword: "jacaré",  picture: "🐊"),
        Letter(letter: "z", ipa: "z", keyword: "zebra",   picture: "🦓"),
        Letter(letter: "q", ipa: "k", keyword: "queijo",  picture: "🧀"),
        Letter(letter: "x", ipa: "ʃ", keyword: "xícara",  picture: "☕"),
        Letter(letter: "k", ipa: "k", keyword: "koala",   picture: "🐨"),
        Letter(letter: "w", ipa: "w", keyword: "wifi",    picture: "📶"),
        Letter(letter: "y", ipa: "i", keyword: "hobby",   picture: "🎨")
    ]
    static func letter(_ s: String) -> Letter? { letters.first { $0.letter == s } }
    private static let firstSoundGroups: [[String]] = [
        ["a", "m", "s"], ["o", "l", "p"], ["e", "n", "t"], ["i", "f", "d"]
    ]
    private static let letterChunks: [(String, [String])] = [
        ("Letras: a o e m s l", ["a", "o", "e", "m", "s", "l"]),
        ("Letras: i u n f p t", ["i", "u", "n", "f", "p", "t"]),
        ("Letras: d r c g b v", ["d", "r", "c", "g", "b", "v"]),
        ("Letras: j z q x",     ["j", "z", "q", "x"]),
        ("Letras: k w y",       ["k", "w", "y"])
    ]
    static func makeUnits(_ prefix: String, _ wordUnits: [Unit]) -> [Unit] {
        let pa: [Lesson] = firstSoundGroups.enumerated().map { i, group in
            Lesson(id: "\(prefix)_snd_\(i + 1)", title: "Primeiros Sons \(i + 1)", icon: "👂",
                   letters: group.compactMap { letter($0) }, letterActivities: [.firstSound])
        }
        let soundsUnit = Unit(id: "\(prefix)_snd", title: "Primeiros Sons", colorA: "#FFCD3C", colorB: "#FF9A6B", lessons: pa)
        var letterUnits: [(unit: Unit, letters: [Letter])] = []
        for (gi, chunk) in letterChunks.enumerated() {
            let letters = chunk.1.compactMap { letter($0) }
            let lessons: [Lesson] = letters.map { L in
                Lesson(id: "\(prefix)_ltr_\(L.letter)", title: "Letra \(L.letter.uppercased())", icon: L.picture,
                       letters: [L],
                       letterActivities: [.meet, .trace, .hearTap, .hearTap, .hearTap])
            }
            letterUnits.append((Unit(id: "\(prefix)_ltr_\(gi + 1)", title: chunk.0,
                                     colorA: "#67C8FF", colorB: "#A78BFA", lessons: lessons), letters))
        }
        return ReviewLessons.assemble(soundsUnit: soundsUnit, letterUnits: letterUnits,
                                      reviewTitle: "Combine os Sons", idPrefix: prefix,
                                      wordUnits: wordUnits,
                                      spellTitle: "Vamos escrever!",
                                      practiceTitle: "Praticar!", mixTitle: "Misturar!")
    }
    static let units = makeUnits("pt", wordUnits)            // Brazilian
    static let euUnits = makeUnits("pt-PT", euWordUnits)     // European
}

extension LanguagePack {
    /// Shape mnemonics for the reversible letters — shared by both Portuguese
    /// packs (no register-specific verbs, so tu/você doesn't matter here).
    private static let ptMnemonics: [String: String] = [
        "b": "O b tem a barriga na frente — b de bola!",
        "d": "O d tem a bolinha à esquerda; o b tem à direita — d de dado!",
        "p": "O p tem a perninha para baixo, abaixo da linha.",
        "q": "O q tem o rabinho para baixo e anda sempre com o u: qu!",
    ]
    static let portuguese = LanguagePack(
        id: "pt", name: "Portuguese (Brazilian)", nativeName: "Português (Brasil)", flag: "🇧🇷",
        ttsLocale: "pt-BR", rtl: false,
        letters: PortugueseLand.letters,
        reversible: ["b", "d", "p", "q"],
        mnemonics: ptMnemonics,
        strings: PortugueseStrings.table
    )
    static let portugueseEU = LanguagePack(
        id: "pt-PT", name: "Portuguese (European)", nativeName: "Português (Portugal)", flag: "🇵🇹",
        ttsLocale: "pt-PT", rtl: false,
        letters: PortugueseLand.letters,
        reversible: ["b", "d", "p", "q"],
        mnemonics: ptMnemonics,
        strings: EuropeanPortugueseStrings.table
    )
}

enum PortugueseStrings {
    static let table: [String: String] = [
        "great_job": "Muito bem!",
        "hi_lets_read": "Oi, %@! Vamos ler!",
        "which_read": "Qual você leu?",
        "daily_review": "Revisão de hoje",
        "placement_title": "Por onde começamos?",
        "placement_new": "Leitor novo — desde o início",
        "placement_letters": "Conhece algumas letras",
        "placement_words": "Já lê palavras simples",
        "locked_hint": "Termine o anterior primeiro!",
        "who_reads": "Quem vai ler hoje?",
        "blast_off": "Decolar!",
        "blast_off_spoken": "Decolar! Muito bem!",
        "back_to_map": "Voltar ao mapa",
        "got_it": "Entendi!",
        "lets_go": "Vamos!",
        "try_again_spoken": "Vamos tentar de novo!",
        "which_starts": "Qual começa com…?",
        "find_the_letter": "Encontre a letra",
        "tap_what_you_hear": "Toque no que você ouve",
        "match_big_little": "Una a grande e a pequena",
        "keep_going_uncover": "Continue para descobrir!",
        "you_found": "Você achou o %@!",
        "my_posters": "Meus pôsteres",
        "new_sound": "Som novo!",
        "tap_to_hear": "Toque para ouvir",
        "say_with_me": "Diga comigo!",
        "how_to_play": "Como jogar",
        "coach_tap": "Toque numa letra para ouvir o som dela",
        "coach_slide": "Deslize o foguete para soletrar — depois leia!",
        "coach_prove": "Mostre que leu: escolha a imagem ou escreva",
        "coach_blast": "Acerte para decolar!",
        "trace_it": "Trace!",
        "drag_sound": "Arraste o animal certo até a letra!",
        "library_title": "📚 Biblioteca",
        "library_subtitle": "Leia uma história sozinho!",
        "the_end": "Fim!",
        "you_read": "Você leu %@!",
        "back_to_books": "Voltar aos livros",
    ]
}

/// European Portuguese UI + spoken prompts — the *tu* register (2nd-person singular)
/// and EP vocabulary (descolar, foguetão, cartaz, começa por, até à) that mark the
/// difference from the Brazilian (você) strings.
enum EuropeanPortugueseStrings {
    static let table: [String: String] = [
        "great_job": "Muito bem!",
        "hi_lets_read": "Olá, %@! Vamos ler!",
        "which_read": "Qual é que leste?",
        "daily_review": "Revisão de hoje",
        "placement_title": "Por onde começamos?",
        "placement_new": "Leitor novo — desde o início",
        "placement_letters": "Conhece algumas letras",
        "placement_words": "Já lê palavras simples",
        "locked_hint": "Termina o anterior primeiro!",
        "who_reads": "Quem vai ler hoje?",
        "blast_off": "Descolar!",
        "blast_off_spoken": "Descolar! Muito bem!",
        "back_to_map": "Voltar ao mapa",
        "got_it": "Percebi!",
        "lets_go": "Vamos!",
        "try_again_spoken": "Vamos tentar outra vez!",
        "which_starts": "Qual começa por…?",
        "find_the_letter": "Encontra a letra",
        "tap_what_you_hear": "Toca no que ouves",
        "match_big_little": "Liga a grande à pequena",
        "keep_going_uncover": "Continua para descobrir!",
        "you_found": "Encontraste o %@!",
        "my_posters": "Os meus cartazes",
        "new_sound": "Som novo!",
        "tap_to_hear": "Toca para ouvir",
        "say_with_me": "Diz comigo!",
        "how_to_play": "Como jogar",
        "coach_tap": "Toca numa letra para ouvires o som",
        "coach_slide": "Desliza o foguetão para soletrar — depois lê!",
        "coach_prove": "Mostra que leste: escolhe a imagem ou escreve",
        "coach_blast": "Acerta para descolar!",
        "trace_it": "Traça!",
        "drag_sound": "Arrasta o animal certo até à letra!",
        "library_title": "📚 Biblioteca",
        "library_subtitle": "Lê uma história sozinho!",
        "the_end": "Fim!",
        "you_read": "Leste o %@!",
        "back_to_books": "Voltar aos livros",
    ]
}