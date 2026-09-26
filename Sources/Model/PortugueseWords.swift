import Foundation

enum PortuguesePhonics: PhonicsPack {
    static let map: [String: String] = {
        var m: [String: String] = [:]
        for L in PortugueseLand.letters { m[L.letter] = L.ipa }
        // accented vowels say the base vowel sound
        for (a, b) in [("á", "a"), ("â", "a"), ("ã", "a"), ("à", "a"),
                       ("é", "ɛ"), ("ê", "e"),
                       ("í", "i"),
                       ("ó", "ɔ"), ("ô", "o"), ("õ", "o"),
                       ("ú", "u"), ("ü", "u"),
                       ("ç", "s")] { m[a] = b }
        // DIGRAPHS / multi-letter graphemes (Brazilian)
        m["ch"] = "ʃ"     // chá
        m["lh"] = "ʎ"     // filho
        m["nh"] = "ɲ"     // banho
        m["rr"] = "h"     // carro
        m["ss"] = "s"     // massa
        m["qu"] = "k"     // queijo (before e/i)
        m["gu"] = "g"     // guitarra (before e/i)
        m["ão"] = "ɐ̃w"    // mão (nasal diphthong)
        m["ãe"] = "ɐ̃j"    // mãe (nasal diphthong)
        m["ei"] = "ej"     // queijo (oral diphthong)
        // SOFT C: c before e/i = /s/. We map the WHOLE soft syllable (consonant +
        // vowel) so the vowel is never "consumed"/deleted during decoding — e.g.
        // céu = ["cé","u"] reads /sɛu/, not /su/. (Brazilian: é/ê closed→open ɛ.)
        m["ce"] = "se"
        m["cé"] = "sɛ"
        m["cê"] = "se"
        m["ci"] = "si"
        m["cí"] = "si"
        // SOFT G: g before e/i = /ʒ/. Same whole-syllable mapping so gelo =
        // ["ge","l","o"] reads /ʒelo/, not /ʒlo/.
        m["ge"] = "ʒe"
        m["gé"] = "ʒɛ"
        m["gê"] = "ʒe"
        m["gi"] = "ʒi"
        m["gí"] = "ʒi"
        m["h"] = ""        // silent
        // Brazilian word-final L vocalizes to /w/ (sol→/sɔw/, mel→/mɛw/, azul→/aˈzuw/).
        m["al"] = "aw"; m["el"] = "ɛw"; m["il"] = "iw"; m["ol"] = "ɔw"; m["ul"] = "uw"
        return m
    }()
    static func ipa(for graphemes: [String], at index: Int) -> String? {
        Phonology.portuguese(graphemes, index, map: map)
    }
}

/// European Portuguese — same word corpus, but the EP phonology engine plus a few
/// map overrides (rr → uvular /ʁ/; dark final-l stays /l/, no /w/ vocalization).
enum PortugueseEUPhonics: PhonicsPack {
    static let map: [String: String] = {
        var m = PortuguesePhonics.map
        m["rr"] = "ʁ"
        m["al"] = "al"; m["el"] = "ɛl"; m["il"] = "il"; m["ol"] = "ɔl"; m["ul"] = "ul"
        return m
    }()
    static func ipa(for graphemes: [String], at index: Int) -> String? {
        Phonology.portugueseEU(graphemes, index, map: map)
    }
}

extension PortugueseLand {
    static func makeWordUnits(_ p: String, _ w: (String, [String], String) -> PWord) -> [Unit] {

        // U1 — 2-sound openers: vowel + continuant (easiest blends)
        let u1 = Unit(id: "\(p)_w1", title: "Primeiras Palavras", colorA: "#5BD16B", colorB: "#67C8FF", lessons: [
            Lesson(id: "\(p)_w1_1", title: "eu", icon: "🙋",
                   words: [w("eu", ["e", "u"], "🙋"), w("ai", ["a", "i"], "😣")]),
            Lesson(id: "\(p)_w1_2", title: "lá", icon: "👉",
                   words: [w("lá", ["l", "á"], "👉"), w("má", ["m", "á"], "😠")]),
            Lesson(id: "\(p)_w1_3", title: "fé", icon: "🙏",
                   words: [w("fé", ["f", "é"], "🙏"), w("só", ["s", "ó"], "1️⃣")]),
        ])

        // U2 — CVC: short closed words
        let u2 = Unit(id: "\(p)_w2", title: "Três Sons", colorA: "#FFCD3C", colorB: "#5BD16B", lessons: [
            Lesson(id: "\(p)_w2_1", title: "sol", icon: "☀️",
                   words: [w("sol", ["s", "ol"], "☀️"), w("mel", ["m", "el"], "🍯")]),
            Lesson(id: "\(p)_w2_2", title: "lua", icon: "🌙",
                   words: [w("lua", ["l", "u", "a"], "🌙"), w("céu", ["cé", "u"], "☁️")]),
            Lesson(id: "\(p)_w2_3", title: "pé", icon: "🦶",
                   words: [w("pé", ["p", "é"], "🦶"), w("mãe", ["m", "ãe"], "👩")]),
        ])

        // U3 — CVCV: open two-syllable words (the classic Portuguese first words)
        let u3 = Unit(id: "\(p)_w3", title: "Duas Sílabas", colorA: "#67C8FF", colorB: "#A78BFA", lessons: [
            Lesson(id: "\(p)_w3_1", title: "pato", icon: "🦆",
                   words: [w("pato", ["p", "a", "t", "o"], "🦆"), w("dado", ["d", "a", "d", "o"], "🎲")]),
            Lesson(id: "\(p)_w3_2", title: "bola", icon: "⚽",
                   words: [w("bola", ["b", "o", "l", "a"], "⚽"), w("vela", ["v", "e", "l", "a"], "🕯️")]),
            Lesson(id: "\(p)_w3_3", title: "sapo", icon: "🐸",
                   words: [w("sapo", ["s", "a", "p", "o"], "🐸"), w("fada", ["f", "a", "d", "a"], "🧚")]),
            Lesson(id: "\(p)_w3_4", title: "boca", icon: "👄",
                   words: [w("boca", ["b", "o", "c", "a"], "👄"), w("dedo", ["d", "e", "d", "o"], "👆")]),
        ])

        // U4 — more CVCV with new consonants (b v c g) and the strong rr
        let u4 = Unit(id: "\(p)_w4", title: "Mais Palavras", colorA: "#FF9A6B", colorB: "#FFCD3C", lessons: [
            Lesson(id: "\(p)_w4_1", title: "gato", icon: "🐱",
                   words: [w("gato", ["g", "a", "t", "o"], "🐱"), w("vaca", ["v", "a", "c", "a"], "🐮")]),
            Lesson(id: "\(p)_w4_2", title: "mala", icon: "🧳",
                   words: [w("mala", ["m", "a", "l", "a"], "🧳"), w("fogo", ["f", "o", "g", "o"], "🔥")]),
            Lesson(id: "\(p)_w4_3", title: "carro", icon: "🚗",
                   words: [w("carro", ["c", "a", "rr", "o"], "🚗"), w("gelo", ["ge", "l", "o"], "🧊")]),
            Lesson(id: "\(p)_w4_4", title: "rato", icon: "🐀",
                   words: [w("rato", ["r", "a", "t", "o"], "🐀"), w("bota", ["b", "o", "t", "a"], "👢")]),
        ])

        // U5 — three syllables (CVCVCV)
        let u5 = Unit(id: "\(p)_w5", title: "Três Sílabas", colorA: "#A78BFA", colorB: "#5BD16B", lessons: [
            Lesson(id: "\(p)_w5_1", title: "tomate", icon: "🍅",
                   words: [w("tomate", ["t", "o", "m", "a", "t", "e"], "🍅"),
                           w("banana", ["b", "a", "n", "a", "n", "a"], "🍌")]),
            Lesson(id: "\(p)_w5_2", title: "cavalo", icon: "🐴",
                   words: [w("cavalo", ["c", "a", "v", "a", "l", "o"], "🐴"),
                           w("sapato", ["s", "a", "p", "a", "t", "o"], "👟")]),
            Lesson(id: "\(p)_w5_3", title: "boneca", icon: "🪆",
                   words: [w("boneca", ["b", "o", "n", "e", "c", "a"], "🪆"),
                           w("camelo", ["c", "a", "m", "e", "l", "o"], "🐫")]),
        ])

        // U6 — digraph words: ch, lh, nh, qu, gu
        let u6 = Unit(id: "\(p)_w6", title: "Sons Especiais", colorA: "#FF6B9A", colorB: "#67C8FF", lessons: [
            Lesson(id: "\(p)_w6_1", title: "chave", icon: "🔑",
                   words: [w("chave", ["ch", "a", "v", "e"], "🔑"), w("chá", ["ch", "á"], "🍵")]),
            Lesson(id: "\(p)_w6_2", title: "galinha", icon: "🐔",
                   words: [w("galinha", ["g", "a", "l", "i", "nh", "a"], "🐔"),
                           w("banho", ["b", "a", "nh", "o"], "🛁")]),
            Lesson(id: "\(p)_w6_3", title: "abelha", icon: "🐝",
                   words: [w("abelha", ["a", "b", "e", "lh", "a"], "🐝"),
                           w("folha", ["f", "o", "lh", "a"], "🍃")]),
            Lesson(id: "\(p)_w6_4", title: "queijo", icon: "🧀",
                   words: [w("queijo", ["qu", "ei", "j", "o"], "🧀"),
                           w("foguete", ["f", "o", "gu", "e", "t", "e"], "🚀")]),
        ])

        // U7 — harder: nasal ão words + j/z/x sounds
        let u7 = Unit(id: "\(p)_w7", title: "Palavras Difíceis", colorA: "#FFCD3C", colorB: "#FF6B9A", lessons: [
            Lesson(id: "\(p)_w7_1", title: "mão", icon: "✋",
                   words: [w("mão", ["m", "ão"], "✋"), w("pão", ["p", "ão"], "🍞")]),
            Lesson(id: "\(p)_w7_2", title: "leão", icon: "🦁",
                   words: [w("leão", ["l", "e", "ão"], "🦁"), w("avião", ["a", "v", "i", "ão"], "✈️")]),
            Lesson(id: "\(p)_w7_3", title: "pijama", icon: "👚",
                   words: [w("pijama", ["p", "i", "j", "a", "m", "a"], "👚"),
                           w("azul", ["a", "z", "ul"], "🔵")]),
            Lesson(id: "\(p)_w7_4", title: "uva", icon: "🍇",
                   words: [w("uva", ["u", "v", "a"], "🍇"), w("ovo", ["o", "v", "o"], "🥚")]),
        ])

        // STORIES — original decodable mini-stories using learned words
        let stories = Unit(id: "\(p)_stories", title: "Histórias", colorA: "#FF6B9A", colorB: "#FFCD3C", lessons: [
            Lesson(id: "\(p)_st_1", title: "O gato", icon: "🐱",
                   sentences: [
                       ["o", "gato"],
                       ["o", "gato", "vê", "a", "lua"],
                       ["o", "gato", "vê", "o", "sol"],
                       ["fim"],
                   ]),
            Lesson(id: "\(p)_st_2", title: "A pata", icon: "🦆",
                   sentences: [
                       ["a", "pata"],
                       ["a", "pata", "vê", "a", "bola"],
                       ["a", "bola", "é", "do", "pato"],
                       ["a", "pata", "e", "o", "pato"],
                       ["fim"],
                   ]),
            Lesson(id: "\(p)_st_3", title: "O sapo", icon: "🐸",
                   sentences: [
                       ["o", "sapo", "na", "lua"],
                       ["o", "sapo", "vê", "o", "gato"],
                       ["o", "gato", "vê", "o", "sapo"],
                       ["o", "sapo", "e", "o", "gato"],
                       ["fim"],
                   ]),
            Lesson(id: "\(p)_st_4", title: "A vaca", icon: "🐮",
                   sentences: [
                       ["a", "vaca", "e", "o", "rato"],
                       ["a", "vaca", "vê", "a", "bota"],
                       ["a", "bota", "é", "da", "vaca"],
                       ["o", "rato", "vê", "a", "bota"],
                       ["fim"],
                   ]),
            Lesson(id: "\(p)_st_5", title: "O carro", icon: "🚗",
                   sentences: [
                       ["o", "carro", "do", "tatu"],
                       ["o", "carro", "vai", "lá"],
                       ["o", "gato", "no", "carro"],
                       ["o", "gato", "e", "o", "tatu"],
                       ["fim"],
                   ]),
            Lesson(id: "\(p)_st_6", title: "O pão", icon: "🍞",
                   sentences: [
                       ["o", "pão", "é", "da", "mãe"],
                       ["a", "mãe", "dá", "o", "pão"],
                       ["o", "pato", "come", "o", "pão"],
                       ["que", "bom"],
                       ["fim"],
                   ]),
            Lesson(id: "\(p)_st_7", title: "A fada", icon: "🧚",
                   sentences: [
                       ["a", "fada", "vê", "a", "lua"],
                       ["a", "fada", "vê", "o", "céu"],
                       ["a", "fada", "vai", "lá"],
                       ["a", "fada", "no", "céu"],
                       ["fim"],
                   ]),
            Lesson(id: "\(p)_st_8", title: "O cavalo", icon: "🐴",
                   sentences: [
                       ["o", "cavalo"],
                       ["o", "cavalo", "come", "uva"],
                       ["o", "cavalo", "vê", "a", "vaca"],
                       ["a", "vaca", "come", "uva"],
                       ["o", "cavalo", "e", "a", "vaca"],
                       ["fim"],
                   ]),
            Lesson(id: "\(p)_st_9", title: "O leão", icon: "🦁",
                   sentences: [
                       ["o", "leão", "no", "sol"],
                       ["o", "leão", "vê", "o", "rato"],
                       ["o", "rato", "vai", "lá"],
                       ["o", "leão", "vê", "a", "lua"],
                       ["fim"],
                   ]),
            Lesson(id: "\(p)_st_10", title: "A galinha", icon: "🐔",
                   sentences: [
                       ["a", "galinha"],
                       ["a", "galinha", "vê", "o", "ovo"],
                       ["o", "ovo", "é", "da", "galinha"],
                       ["a", "galinha", "e", "o", "ovo"],
                       ["fim"],
                   ]),
            Lesson(id: "\(p)_st_11", title: "A abelha", icon: "🐝",
                   sentences: [
                       ["a", "abelha", "vai", "lá"],
                       ["a", "abelha", "vê", "a", "folha"],
                       ["a", "abelha", "vê", "a", "vela"],
                       ["a", "abelha", "come", "mel"],
                       ["que", "bom"],
                       ["fim"],
                   ]),
            Lesson(id: "\(p)_st_12", title: "O foguete", icon: "🚀",
                   sentences: [
                       ["o", "foguete", "vai", "lá"],
                       ["o", "foguete", "no", "céu"],
                       ["o", "foguete", "vê", "a", "lua"],
                       ["o", "foguete", "vê", "o", "sol"],
                       ["fim"],
                   ]),
            Lesson(id: "\(p)_st_13", title: "O sapo e o pato", icon: "🐸",
                   sentences: [
                       ["o", "sapo", "vê", "o", "pato"],
                       ["o", "pato", "vê", "o", "sapo"],
                       ["o", "sapo", "vai", "lá"],
                       ["o", "pato", "vai", "lá"],
                       ["o", "sapo", "e", "o", "pato"],
                       ["fim"],
                   ]),
            Lesson(id: "\(p)_st_14", title: "A boneca", icon: "🪆",
                   sentences: [
                       ["a", "boneca"],
                       ["a", "boneca", "é", "da", "mãe"],
                       ["a", "mãe", "dá", "a", "boneca"],
                       ["a", "boneca", "vê", "o", "gato"],
                       ["que", "bom"],
                       ["fim"],
                   ]),
        ])

        return [u1, u2, u3, u4, u5, u6, u7, stories]
    }
    static let wordUnits = makeWordUnits("pt", PortuguesePhonics.word)         // Brazilian
    static let euWordUnits = makeWordUnits("pt-PT", PortugueseEUPhonics.word)  // European
}