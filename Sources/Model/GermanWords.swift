import Foundation

enum GermanPhonics: PhonicsPack {
    static let map: [String: String] = {
        var m: [String: String] = [:]
        for L in GermanLand.letters { m[L.letter] = L.ipa }
        // umlauts / ß already live in GermanLand.letters; keep them explicit too
        for (a, b) in [("ä", "ɛ"), ("ö", "ø"), ("ü", "y"), ("ß", "s")] { m[a] = b }
        // DIGRAPHS — two/three letters, one sound (one tappable tile)
        m["sch"] = "ʃ"   // schule
        m["ch"]  = "x"   // buch
        m["ei"]  = "aɪ"  // ei
        m["ai"]  = "aɪ"  // mai
        m["ie"]  = "iː"  // liebe (long i)
        m["eu"]  = "ɔɪ"  // heu
        m["au"]  = "aʊ"  // maus
        m["ck"]  = "k"   // socke
        m["ng"]  = "ŋ"   // finger
        m["qu"]  = "kv"  // quark
        m["tz"]  = "ts"  // katze (t+z → one /ts/ tile)
        // DOUBLED CONSONANTS — one sound, one tile; the doubling marks the short
        // vowel before it (German synthetic-phonics convention). ball → b·a·ll.
        m["ll"]  = "l"   // ball, quelle
        return m
    }()
    static func ipa(for graphemes: [String], at index: Int) -> String? {
        Phonology.german(graphemes, index, map: map)
    }
}

extension GermanLand {
    /// Decodable German word units (blend → read), ordered easy→hard:
    /// 2-sound → CVC → CVCV → digraph words → multisyllable, then stories.
    /// Lowercase even for nouns (kids). Every grapheme is a key in GermanPhonics.map
    /// and the joined graphemes equal the word exactly.
    static let wordUnits: [Unit] = {
        func w(_ t: String, _ ls: [String], _ p: String) -> PWord { GermanPhonics.word(t, ls, p) }

        // U1 — Erste Laute: 2-sound blends + first tiny words
        let u1 = Unit(id: "de_w1", title: "Erste Wörter", colorA: "#5BD16B", colorB: "#67C8FF", lessons: [
            Lesson(id: "de_w1_1", title: "am", icon: "🔛",
                   words: [w("am", ["a:a", "m"], "🔛"), w("im", ["i:ɪ", "m"], "📥")]),  // short closed-syllable vowels
            Lesson(id: "de_w1_2", title: "oma", icon: "👵",
                   words: [w("oma", ["o", "m", "a"], "👵"), w("opa", ["o", "p", "a"], "👴")]),
            Lesson(id: "de_w1_3", title: "ufo", icon: "🛸",
                   words: [w("ufo", ["u", "f", "o:o"], "🛸"), w("igel", ["i", "g", "e", "l"], "🦔")]),
        ])

        // U2 — CVC: short closed-syllable words.
        // Only TRULY-regular finals: vowels / l m n r and voiceless t k f z(=ts).
        // No word-final b/d/g (Auslautverhärtung → /t/) and no word-final s
        // (would voice to /z/ by the s→/z/ rule). ll is one tile (short-vowel marker).
        let u2 = Unit(id: "de_w2", title: "Kurze Wörter", colorA: "#FFCD3C", colorB: "#5BD16B", lessons: [
            Lesson(id: "de_w2_1", title: "ball", icon: "⚽",
                   words: [w("ball", ["b", "a", "ll"], "⚽"), w("rot", ["r", "o", "t"], "🟥")]),
            Lesson(id: "de_w2_2", title: "hut", icon: "🎩",
                   words: [w("hut", ["h", "u", "t"], "🎩"), w("tor", ["t", "o", "r"], "🥅")]),
            Lesson(id: "de_w2_3", title: "sofa", icon: "🛋️",
                   words: [w("sofa", ["s", "o", "f", "a"], "🛋️"), w("hof", ["h", "o", "f"], "🏡")]),
            Lesson(id: "de_w2_4", title: "salz", icon: "🧂",
                   words: [w("salz", ["s", "a", "l", "z"], "🧂"), w("ofen", ["o", "f", "e", "n"], "🔥")]),
        ])

        // U3 — CVCV / two-syllable open words
        let u3 = Unit(id: "de_w3", title: "Mehr Wörter", colorA: "#67C8FF", colorB: "#A78BFA", lessons: [
            Lesson(id: "de_w3_1", title: "nase", icon: "👃",
                   words: [w("nase", ["n", "a", "s", "e"], "👃"), w("rose", ["r", "o", "s", "e"], "🌹")]),
            Lesson(id: "de_w3_2", title: "dose", icon: "🥫",
                   words: [w("dose", ["d", "o", "s", "e"], "🥫"), w("hose", ["h", "o", "s", "e"], "👖")]),
            Lesson(id: "de_w3_3", title: "banane", icon: "🍌",
                   words: [w("banane", ["b", "a:a", "n", "a", "n", "e"], "🍌"),       // first a unstressed-short
                           w("tomate", ["t", "o:o", "m", "a", "t", "e"], "🍅")]),     // first o unstressed-short
            Lesson(id: "de_w3_4", title: "gabel", icon: "🍴",
                   words: [w("gabel", ["g", "a", "b", "e", "l"], "🍴"),
                           w("vogel", ["v", "o", "g", "e", "l"], "🐦")]),
        ])

        // U4 — au / ei / ie diphthongs + long-i digraph
        let u4 = Unit(id: "de_w4", title: "au, ei, ie", colorA: "#FF9A6B", colorB: "#FF6B9A", lessons: [
            Lesson(id: "de_w4_1", title: "auge", icon: "👁️",
                   words: [w("auge", ["au", "g", "e"], "👁️"), w("baum", ["b", "au", "m"], "🌳")]),
            Lesson(id: "de_w4_2", title: "auto", icon: "🚗",
                   words: [w("auto", ["au", "t", "o:o"], "🚗"), w("zaun", ["z", "au", "n"], "🚧")]),
            Lesson(id: "de_w4_3", title: "ei", icon: "🥚",
                   words: [w("ei", ["ei"], "🥚"), w("bein", ["b", "ei", "n"], "🦵")]),
            Lesson(id: "de_w4_4", title: "eimer", icon: "🪣",
                   words: [w("eimer", ["ei", "m", "e", "r"], "🪣"), w("mai", ["m", "ai"], "🌷")]),
            Lesson(id: "de_w4_5", title: "biene", icon: "🐝",
                   words: [w("biene", ["b", "ie", "n", "e"], "🐝"),
                           w("wiese", ["w", "ie", "s", "e"], "🌾")]),
        ])

        // U5 — sch / ch / ck consonant digraphs
        let u5 = Unit(id: "de_w5", title: "sch, ch, ck", colorA: "#A78BFA", colorB: "#67C8FF", lessons: [
            Lesson(id: "de_w5_1", title: "schaf", icon: "🐑",
                   words: [w("schaf", ["sch", "a", "f"], "🐑"), w("fisch", ["f", "i", "sch"], "🐟")]),
            Lesson(id: "de_w5_2", title: "schule", icon: "🏫",
                   words: [w("schule", ["sch", "u", "l", "e"], "🏫"),
                           w("tisch", ["t", "i", "sch"], "🪑")]),
            Lesson(id: "de_w5_3", title: "buch", icon: "📕",
                   words: [w("buch", ["b", "u", "ch"], "📕"), w("dach", ["d", "a", "ch"], "🏠")]),
            Lesson(id: "de_w5_4", title: "socke", icon: "🧦",
                   words: [w("socke", ["s", "o", "ck", "e"], "🧦"),
                           w("hexe", ["h", "e", "x", "e"], "🧙")]),
        ])

        // U6 — eu / ä ö ü umlauts
        let u6 = Unit(id: "de_w6", title: "eu, ä, ö, ü", colorA: "#FFCD3C", colorB: "#FF9A6B", lessons: [
            Lesson(id: "de_w6_1", title: "heu", icon: "🌾",
                   words: [w("heu", ["h", "eu"], "🌾"), w("eule", ["eu", "l", "e"], "🦉")]),
            Lesson(id: "de_w6_2", title: "bär", icon: "🐻",
                   words: [w("bär", ["b", "ä", "r"], "🐻"), w("käse", ["k", "ä", "s", "e"], "🧀")]),
            Lesson(id: "de_w6_3", title: "öl", icon: "🛢️",
                   words: [w("öl", ["ö", "l"], "🛢️"), w("löwe", ["l", "ö", "w", "e"], "🦁")]),
            Lesson(id: "de_w6_4", title: "tür", icon: "🚪",
                   words: [w("tür", ["t", "ü", "r"], "🚪"), w("hüte", ["h", "ü", "t", "e"], "🎩")]),
            Lesson(id: "de_w6_5", title: "fuß", icon: "🦶",
                   words: [w("fuß", ["f", "u", "ß"], "🦶"), w("süß", ["s", "ü", "ß"], "🍬")]),
        ])

        // U7 — ng / qu + longer multisyllable words
        let u7 = Unit(id: "de_w7", title: "Lange Wörter", colorA: "#5BD16B", colorB: "#2FB37E", lessons: [
            Lesson(id: "de_w7_1", title: "finger", icon: "👆",
                   words: [w("finger", ["f", "i", "ng", "e", "r"], "👆"),
                           w("ring", ["r", "i", "ng"], "💍")]),
            Lesson(id: "de_w7_2", title: "quark", icon: "🥛",
                   words: [w("quark", ["qu", "a", "r", "k"], "🥛"),
                           w("quelle", ["qu", "e", "ll", "e"], "💧")]),
            Lesson(id: "de_w7_3", title: "tomate", icon: "🍅",
                   words: [w("salat", ["s", "a:a", "l", "a", "t"], "🥗"),
                           w("nudel", ["n", "u", "d", "e", "l"], "🍜")]),
            Lesson(id: "de_w7_4", title: "schokolade", icon: "🍫",
                   words: [w("schokolade", ["sch", "o:o", "k", "o:o", "l", "a", "d", "e"], "🍫"),  // unstressed o's short
                           w("limonade", ["l", "i:i", "m", "o:o", "n", "a", "d", "e"], "🥤")]),  // unstressed i/o short
        ])

        // Stories — original decodable mini-stories from learned words.
        // Each inner array is ONE PAGE; last page is "ende!".
        let stories = Unit(id: "de_stories", title: "Geschichten", colorA: "#FF6B9A", colorB: "#FFCD3C", lessons: [
            Lesson(id: "de_st_1", title: "die maus", icon: "🐭",
                   sentences: [["die", "maus"],
                               ["die", "maus", "im", "haus"],
                               ["die", "maus", "im", "auto"],
                               ["ende!"]]),
            Lesson(id: "de_st_2", title: "das schaf", icon: "🐑",
                   sentences: [["das", "schaf"],
                               ["das", "schaf", "im", "haus"],
                               ["das", "schaf", "und", "die", "maus"],
                               ["das", "schaf", "ist", "süß"],
                               ["ende!"]]),
            Lesson(id: "de_st_3", title: "oma und opa", icon: "👵",
                   sentences: [["oma", "und", "opa"],
                               ["oma", "im", "auto"],
                               ["opa", "und", "die", "maus"],
                               ["die", "maus", "ist", "süß"],
                               ["ende!"]]),
            Lesson(id: "de_st_4", title: "die eule", icon: "🦉",
                   sentences: [["die", "eule"],
                               ["die", "eule", "im", "baum"],
                               ["die", "maus", "und", "die", "eule"],
                               ["die", "eule", "und", "das", "ei"],
                               ["ende!"]]),
            Lesson(id: "de_st_5", title: "der bär", icon: "🐻",
                   sentences: [["der", "bär"],
                               ["der", "bär", "und", "der", "fisch"],
                               ["der", "bär", "und", "die", "biene"],
                               ["der", "bär", "und", "das", "buch"],
                               ["ende!"]]),
            Lesson(id: "de_st_6", title: "in der schule", icon: "🏫",
                   sentences: [["die", "schule"],
                               ["das", "buch", "und", "der", "tisch"],
                               ["die", "maus", "in", "der", "schule"],
                               ["die", "maus", "und", "das", "buch"],
                               ["ende!"]]),
            Lesson(id: "de_st_7", title: "der löwe", icon: "🦁",
                   sentences: [["der", "löwe"],
                               ["der", "löwe", "und", "der", "bär"],
                               ["der", "löwe", "und", "die", "maus"],
                               ["die", "maus", "ist", "süß"],
                               ["ende!"]]),
            Lesson(id: "de_st_8", title: "das auto", icon: "🚗",
                   sentences: [["das", "auto"],
                               ["oma", "im", "auto"],
                               ["opa", "im", "auto"],
                               ["die", "maus", "im", "auto"],
                               ["ende!"]]),
            Lesson(id: "de_st_9", title: "die biene", icon: "🐝",
                   sentences: [["die", "biene"],
                               ["die", "biene", "in", "der", "wiese"],
                               ["die", "biene", "und", "der", "vogel"],
                               ["die", "biene", "und", "die", "rose"],
                               ["ende!"]]),
            Lesson(id: "de_st_10", title: "der fisch", icon: "🐟",
                   sentences: [["der", "fisch"],
                               ["der", "fisch", "und", "die", "quelle"],
                               ["der", "bär", "und", "der", "fisch"],
                               ["der", "fisch", "ist", "süß"],
                               ["ende!"]]),
            Lesson(id: "de_st_11", title: "oma und der käse", icon: "🧀",
                   sentences: [["oma", "und", "der", "käse"],
                               ["der", "käse", "im", "haus"],
                               ["die", "maus", "und", "der", "käse"],
                               ["der", "käse", "ist", "süß"],
                               ["ende!"]]),
            Lesson(id: "de_st_12", title: "der vogel", icon: "🐦",
                   sentences: [["der", "vogel"],
                               ["der", "vogel", "im", "baum"],
                               ["der", "vogel", "und", "die", "eule"],
                               ["der", "vogel", "und", "das", "ei"],
                               ["ende!"]]),
            Lesson(id: "de_st_13", title: "die schokolade", icon: "🍫",
                   sentences: [["die", "schokolade"],
                               ["die", "schokolade", "und", "die", "banane"],
                               ["oma", "und", "die", "schokolade"],
                               ["die", "schokolade", "ist", "süß"],
                               ["ende!"]]),
            Lesson(id: "de_st_14", title: "der igel", icon: "🦔",
                   sentences: [["der", "igel"],
                               ["der", "igel", "und", "die", "maus"],
                               ["der", "igel", "im", "haus"],
                               ["der", "igel", "und", "der", "bär"],
                               ["der", "igel", "ist", "süß"],
                               ["ende!"]]),
        ])

        return [u1, u2, u3, u4, u5, u6, u7, stories]
    }()
}