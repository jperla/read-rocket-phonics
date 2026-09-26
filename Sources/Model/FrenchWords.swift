import Foundation

/// French (Français) grapheme→phoneme + decodable first words/stories.
///
/// French is NOT a transparent orthography, so pronunciation is resolved by the
/// context-sensitive engine in `Phonology.swift`: a final mute -e is SILENT in
/// polysyllables ("lune" → /lyn/, "robe" → /ʁɔb/, "île" → /il/); 'o' is open /ɔ/
/// in a closed syllable but closed /o/ word-final or before a vowel ("moto" →
/// /mɔto/); and 'eu' is /ø/ open vs /œ/ closed ("feu" → /fø/, "fleur" → /flœʁ/).
/// The pack still ONLY contains words that decode *correctly*, so we avoid words
/// whose correctness depends on a *silent final consonant* (chat, loup, pont…) or
/// an *intervocalic s* that is really voiced /z/ (maison, oiseau, musique), which
/// the French resolver does not model. Single silent /h/ is mapped to "".
enum FrenchPhonics: PhonicsPack {
    static let map: [String: String] = {
        var m: [String: String] = [:]
        // every single letter → its taught sound
        for L in FrenchLand.letters { m[L.letter] = L.ipa }
        // accented vowels say their base vowel's sound (è/ê/ë add the open /ɛ/)
        for (a, b) in [("à", "a"), ("â", "a"), ("é", "e"), ("è", "ɛ"), ("ê", "ɛ"),
                       ("ë", "ɛ"), ("î", "i"), ("ï", "i"), ("ô", "o"), ("û", "y"),
                       ("ù", "y"), ("ü", "y"), ("ç", "s")] { m[a] = b }
        // DIGRAPHS / vowel teams / nasals (multi-char keys)
        m["ou"] = "u"     // soupe, bouche
        m["ch"] = "ʃ"     // chat, vache
        m["ph"] = "f"     // photo
        m["gn"] = "ɲ"     // ligne, montagne
        m["ai"] = "ɛ"     // balai
        m["ei"] = "ɛ"     // neige
        m["au"] = "o"     // jaune
        m["eau"] = "o"    // bateau, gâteau
        m["eu"] = "ø"     // feu, fleur
        m["oi"] = "wa"    // roi, noix
        m["on"] = "ɔ̃"     // savon, bonbon
        m["an"] = "ɑ̃"     // banque
        m["en"] = "ɑ̃"     // enfant
        m["in"] = "ɛ̃"     // lapin
        m["qu"] = "k"     // casque, banque
        m["h"] = ""       // silent
        m["et"] = "e"     // high-frequency word "et" → /e/ (not /ə/+/t/)
        return m
    }()

    static func ipa(for graphemes: [String], at index: Int) -> String? {
        Phonology.french(graphemes, index, map: map)
    }
}

extension FrenchLand {
    static let wordUnits: [Unit] = {
        func w(_ t: String, _ ls: [String], _ p: String) -> PWord { FrenchPhonics.word(t, ls, p) }

        // MARK: U1 — Premiers Mots (2–3 sounds; French final -e is silent, e.g. île → /il/)
        let u1 = Unit(id: "fr_w1", title: "Premiers Mots", colorA: "#5BD16B", colorB: "#67C8FF", lessons: [
            Lesson(id: "fr_w1_1", title: "ami", icon: "🧒",
                   words: [w("ami", ["a", "m", "i"], "🧒"),
                           w("papa", ["p", "a", "p", "a"], "👨")]),
            Lesson(id: "fr_w1_2", title: "os", icon: "🦴",
                   words: [w("os", ["o", "s"], "🦴"),
                           w("île", ["î", "l", "e"], "🏝️")]),
            Lesson(id: "fr_w1_3", title: "midi", icon: "🕛",
                   words: [w("midi", ["m", "i", "d", "i"], "🕛"),
                           w("sol", ["s", "o", "l"], "🟫")]),
        ])

        // MARK: U2 — Petits Mots (CVC / short words)
        let u2 = Unit(id: "fr_w2", title: "Petits Mots", colorA: "#FFCD3C", colorB: "#5BD16B", lessons: [
            Lesson(id: "fr_w2_1", title: "vélo", icon: "🚲",
                   words: [w("vélo", ["v", "é", "l", "o"], "🚲"),
                           w("moto", ["m", "o", "t", "o"], "🏍️")]),
            Lesson(id: "fr_w2_2", title: "lune", icon: "🌙",
                   words: [w("lune", ["l", "u", "n", "e"], "🌙"),
                           w("robe", ["r", "o", "b", "e"], "👗")]),
            Lesson(id: "fr_w2_3", title: "café", icon: "☕",
                   words: [w("café", ["c", "a", "f", "é"], "☕"),
                           w("domino", ["d", "o", "m", "i", "n", "o"], "🎴")]),
        ])

        // MARK: U3 — Plus de Mots (CVCV / multisyllable; context engine: open/closed o & eu, silent final -e)
        let u3 = Unit(id: "fr_w3", title: "Plus de Mots", colorA: "#FF9A6B", colorB: "#FF6B9A", lessons: [
            Lesson(id: "fr_w3_1", title: "tomate", icon: "🍅",
                   words: [w("tomate", ["t", "o", "m", "a", "t", "e"], "🍅"),
                           w("olive", ["o", "l", "i", "v", "e"], "🫒")]),
            Lesson(id: "fr_w3_2", title: "salade", icon: "🥗",
                   words: [w("salade", ["s", "a", "l", "a", "d", "e"], "🥗"),
                           w("carte", ["c", "a", "r", "t", "e"], "🗺️")]),
            Lesson(id: "fr_w3_3", title: "zèbre", icon: "🦓",
                   words: [w("zèbre", ["z", "è", "b", "r", "e"], "🦓"),
                           w("pyjama", ["p", "y", "j", "a", "m", "a"], "🩳"),
                           w("tortue", ["t", "o", "r", "t", "u", "e"], "🐢")]),
        ])

        // MARK: U4 — Digraphes : ch · ph · ou
        let u4 = Unit(id: "fr_w4", title: "Digraphes : ch · ou", colorA: "#67C8FF", colorB: "#A78BFA", lessons: [
            Lesson(id: "fr_w4_1", title: "vache", icon: "🐮",
                   words: [w("vache", ["v", "a", "ch", "e"], "🐮"),
                           w("niche", ["n", "i", "ch", "e"], "🐕")]),
            Lesson(id: "fr_w4_2", title: "bouche", icon: "👄",
                   words: [w("bouche", ["b", "ou", "ch", "e"], "👄"),
                           w("soupe", ["s", "ou", "p", "e"], "🍲")]),
            Lesson(id: "fr_w4_3", title: "photo", icon: "📷",
                   words: [w("photo", ["ph", "o", "t", "o"], "📷")]),
        ])

        // MARK: U5 — Sons des voyelles : eau · eu · oi · ai
        let u5 = Unit(id: "fr_w5", title: "Voyelles : eau · eu · oi", colorA: "#A78BFA", colorB: "#FF9A6B", lessons: [
            Lesson(id: "fr_w5_1", title: "bateau", icon: "⛵",
                   words: [w("bateau", ["b", "a", "t", "eau"], "⛵"),
                           w("gâteau", ["g", "â", "t", "eau"], "🍰")]),
            Lesson(id: "fr_w5_2", title: "feu", icon: "🔥",
                   words: [w("feu", ["f", "eu"], "🔥"),
                           w("jeu", ["j", "eu"], "🎲"),
                           w("fleur", ["f", "l", "eu", "r"], "🌸")]),
            Lesson(id: "fr_w5_3", title: "roi", icon: "👑",
                   words: [w("roi", ["r", "oi"], "👑"),
                           w("château", ["ch", "â", "t", "eau"], "🏰"),
                           w("balai", ["b", "a", "l", "ai"], "🧹")]),
        ])

        // MARK: U6 — Sons nasals + gn : on · an · in · gn
        let u6 = Unit(id: "fr_w6", title: "Sons nasals : on · an · gn", colorA: "#FF6B9A", colorB: "#FFCD3C", lessons: [
            Lesson(id: "fr_w6_1", title: "savon", icon: "🧼",
                   words: [w("savon", ["s", "a", "v", "on"], "🧼"),
                           w("bonbon", ["b", "on", "b", "on"], "🍬")]),
            Lesson(id: "fr_w6_2", title: "banque", icon: "🏦",
                   words: [w("banque", ["b", "an", "qu", "e"], "🏦"),
                           w("casque", ["c", "a", "s", "qu", "e"], "🪖")]),
            Lesson(id: "fr_w6_3", title: "montagne", icon: "⛰️",
                   words: [w("ligne", ["l", "i", "gn", "e"], "📏"),
                           w("montagne", ["m", "on", "t", "a", "gn", "e"], "⛰️")]),
        ])

        // MARK: Stories — decodable mini-tales (each inner array = ONE page)
        let stories = Unit(id: "fr_stories", title: "Histoires", colorA: "#FF6B9A", colorB: "#FFCD3C", lessons: [
            Lesson(id: "fr_st_1", title: "la lune", icon: "🌙",
                   sentences: [["la", "lune"],
                               ["la", "lune", "et", "le", "vélo"],
                               ["le", "vélo", "va", "à", "la", "lune"],
                               ["fini"]]),
            Lesson(id: "fr_st_2", title: "le bateau", icon: "⛵",
                   sentences: [["le", "bateau"],
                               ["le", "bateau", "et", "le", "roi"],
                               ["le", "roi", "va", "sur", "le", "bateau"],
                               ["le", "bateau", "va", "à", "la", "montagne"],
                               ["fini"]]),
            Lesson(id: "fr_st_3", title: "la vache", icon: "🐮",
                   sentences: [["la", "vache"],
                               ["la", "vache", "et", "la", "salade"],
                               ["la", "vache", "a", "l’olive"],
                               ["la", "vache", "et", "le", "zèbre"],
                               ["fini"]]),
            Lesson(id: "fr_st_4", title: "le château", icon: "🏰",
                   sentences: [["le", "château"],
                               ["le", "château", "sur", "la", "montagne"],
                               ["le", "feu", "et", "la", "fleur"],
                               ["la", "fleur", "et", "le", "balai"],
                               ["fini"]]),
            Lesson(id: "fr_st_5", title: "le café", icon: "☕",
                   sentences: [["le", "café"],
                               ["papa", "et", "le", "café"],
                               ["papa", "a", "la", "tomate"],
                               ["papa", "et", "l’ami", "à", "midi"],
                               ["fini"]]),
            Lesson(id: "fr_st_6", title: "la tortue", icon: "🐢",
                   sentences: [["la", "tortue"],
                               ["la", "tortue", "va", "à", "la", "soupe"],
                               ["la", "tortue", "a", "la", "salade"],
                               ["la", "tortue", "et", "le", "zèbre"],
                               ["fini"]]),
            Lesson(id: "fr_st_7", title: "le jeu", icon: "🎲",
                   sentences: [["le", "jeu"],
                               ["l’ami", "et", "le", "jeu"],
                               ["papa", "a", "le", "domino"],
                               ["le", "jeu", "et", "le", "pyjama"],
                               ["fini"]]),
            Lesson(id: "fr_st_8", title: "la moto", icon: "🏍️",
                   sentences: [["la", "moto"],
                               ["la", "moto", "et", "le", "vélo"],
                               ["la", "moto", "va", "à", "la", "banque"],
                               ["la", "moto", "va", "sur", "la", "montagne"],
                               ["fini"]]),
            Lesson(id: "fr_st_9", title: "la fleur", icon: "🌸",
                   sentences: [["la", "fleur"],
                               ["la", "fleur", "et", "l’olive"],
                               ["l’ami", "a", "la", "fleur"],
                               ["la", "fleur", "sur", "la", "carte"],
                               ["fini"]]),
            Lesson(id: "fr_st_10", title: "le savon", icon: "🧼",
                   sentences: [["le", "savon"],
                               ["le", "savon", "et", "la", "bouche"],
                               ["papa", "a", "le", "savon"],
                               ["le", "savon", "et", "le", "bonbon"],
                               ["fini"]]),
            Lesson(id: "fr_st_11", title: "le bonbon", icon: "🍬",
                   sentences: [["le", "bonbon"],
                               ["l’ami", "a", "le", "bonbon"],
                               ["le", "bonbon", "et", "le", "gâteau"],
                               ["le", "gâteau", "à", "midi"],
                               ["fini"]]),
            Lesson(id: "fr_st_12", title: "le roi", icon: "👑",
                   sentences: [["le", "roi"],
                               ["le", "roi", "et", "le", "château"],
                               ["le", "roi", "a", "le", "gâteau"],
                               ["le", "roi", "va", "à", "la", "montagne"],
                               ["fini"]]),
            Lesson(id: "fr_st_13", title: "la robe", icon: "👗",
                   sentences: [["la", "robe"],
                               ["la", "robe", "et", "la", "fleur"],
                               ["l’ami", "a", "la", "robe"],
                               ["la", "robe", "et", "le", "balai"],
                               ["fini"]]),
            Lesson(id: "fr_st_14", title: "la photo", icon: "📷",
                   sentences: [["la", "photo"],
                               ["la", "photo", "et", "le", "château"],
                               ["la", "photo", "et", "la", "vache"],
                               ["papa", "et", "l’ami", "sur", "la", "photo"],
                               ["fini"]]),
        ])

        return [u1, u2, u3, u4, u5, u6, stories]
    }()
}