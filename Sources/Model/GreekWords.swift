import Foundation

/// Greek grapheme→phoneme + decodable first words/sentences. Modern Greek is highly
/// regular grapheme→phoneme, which is ideal for phonics. The map covers the 24
/// single letters, accented vowels (which say the SAME sound as the base, so they
/// fold to the base ipa), final ς = /s/, and the common multi-letter graphemes that
/// every Greek reader needs: vowel digraphs (ου=u, αι=e, ει/οι=i, αυ=av, ευ=ev),
/// voiced-stop digraphs (μπ=b, ντ=d, γκ=g, γγ=ŋg), the double sigma σσ=s, plus
/// τσ=ts, τζ=dz. We teach the SOUND, never the letter name.
///
/// Decodable words avoid SYNIZESIS (unaccented ι/υ + vowel → glide, e.g. φωτιά
/// /fo.tça/, χιόνι /ço.ni/, ελιά /e.ʎa/): teaching those as flat ι+vowel sequences
/// would drill a pronunciation no native speaker uses, so they are excluded in
/// favour of phonetically "flat" words whose every grapheme = one steady sound.
enum GreekPhonics: PhonicsPack {
    static let map: [String: String] = {
        var m: [String: String] = [:]
        for L in GreekLand.letters { m[L.letter] = L.ipa }     // unaccented letters
        // accented vowels say the same sound as the base
        for (a, b) in [("ά", "a"), ("έ", "e"), ("ή", "i"), ("ί", "i"), ("ό", "o"),
                       ("ύ", "i"), ("ώ", "o"), ("ϊ", "i"), ("ϋ", "i"), ("ΐ", "i"), ("ΰ", "i")] {
            m[a] = b
        }
        m["ς"] = "s"                                           // final sigma
        // DIGRAPHS (multi-letter graphemes) — taught as single tappable sounds.
        // Accented variants (accent on the 2nd letter) say the SAME sound.
        m["ου"] = "u";  m["ού"] = "u"   // vowel digraphs
        m["αι"] = "e";  m["αί"] = "e"
        m["ει"] = "i";  m["εί"] = "i"
        m["οι"] = "i";  m["οί"] = "i"
        m["αυ"] = "av"; m["αύ"] = "av"
        m["ευ"] = "ev"; m["εύ"] = "ev"
        m["μπ"] = "b"   // voiced-stop digraphs
        m["ντ"] = "d"
        m["γκ"] = "g"
        m["γγ"] = "ŋg"  // double gamma = /ŋɡ/, same as γκ (e.g. φεγγάρι)
        m["σσ"] = "s"   // double sigma → single /s/ (e.g. θάλασσα, μέλισσα)
        m["τσ"] = "ts"
        m["τζ"] = "dz"
        return m
    }()

}

extension GreekLand {
    /// Decodable Greek word units (blend → read), ordered easy→harder:
    /// 2-sound → CVC → CVCV → digraph words → multisyllable → stories. Every word is
    /// fully decodable: the graphemes joined equal the exact text, and every grapheme
    /// is a key in `GreekPhonics.map`. All letters are taught in the alphabet on-ramp.
    static let wordUnits: [Unit] = {
        func w(_ t: String, _ ls: [String], _ p: String) -> PWord { GreekPhonics.word(t, ls, p) }

        // U1 — first short words (2 sounds → simple CVCV)
        let u1 = Unit(id: "el_w1", title: "Πρώτες Λέξεις", colorA: "#5BD16B", colorB: "#67C8FF", lessons: [
            Lesson(id: "el_w1_1", title: "να", icon: "👉",
                   words: [w("να", ["ν", "α"], "👉"), w("δε", ["δ", "ε"], "🚫")]),
            Lesson(id: "el_w1_2", title: "μαμά", icon: "👩",
                   words: [w("μαμά", ["μ", "α", "μ", "ά"], "👩"), w("μωρό", ["μ", "ω", "ρ", "ό"], "👶")]),
            Lesson(id: "el_w1_3", title: "νερό", icon: "💧",
                   words: [w("νερό", ["ν", "ε", "ρ", "ό"], "💧"), w("μέλι", ["μ", "έ", "λ", "ι"], "🍯")]),
        ])

        // U2 — CVC and CVCV everyday nouns
        let u2 = Unit(id: "el_w2", title: "Κι Άλλες Λέξεις", colorA: "#FFCD3C", colorB: "#FF9A6B", lessons: [
            Lesson(id: "el_w2_1", title: "γάτα", icon: "🐱",
                   words: [w("γάτα", ["γ", "ά", "τ", "α"], "🐱"), w("κότα", ["κ", "ό", "τ", "α"], "🐔")]),
            Lesson(id: "el_w2_2", title: "ψάρι", icon: "🐟",
                   words: [w("ψάρι", ["ψ", "ά", "ρ", "ι"], "🐟"), w("πόδι", ["π", "ό", "δ", "ι"], "🦶")]),
            Lesson(id: "el_w2_3", title: "τυρί", icon: "🧀",
                   words: [w("τυρί", ["τ", "υ", "ρ", "ί"], "🧀"), w("μύτη", ["μ", "ύ", "τ", "η"], "👃")]),
        ])

        // U3 — three-syllable / longer single-letter words
        let u3 = Unit(id: "el_w3", title: "Μεγάλες Λέξεις", colorA: "#A78BFA", colorB: "#67C8FF", lessons: [
            Lesson(id: "el_w3_1", title: "λεμόνι", icon: "🍋",
                   words: [w("λεμόνι", ["λ", "ε", "μ", "ό", "ν", "ι"], "🍋"),
                           w("πατάτα", ["π", "α", "τ", "ά", "τ", "α"], "🥔")]),
            Lesson(id: "el_w3_2", title: "βάζο", icon: "🏺",
                   words: [w("βάζο", ["β", "ά", "ζ", "ο"], "🏺"),
                           w("ποτήρι", ["π", "ο", "τ", "ή", "ρ", "ι"], "🥛")]),
            Lesson(id: "el_w3_3", title: "θάλασσα", icon: "🌊",
                   words: [w("θάλασσα", ["θ", "ά", "λ", "α", "σσ", "α"], "🌊"),
                           w("τόπι", ["τ", "ό", "π", "ι"], "🏐")]),
        ])

        // U4 — vowel digraphs (ου, αι, ει, αυ, ευ)
        let u4 = Unit(id: "el_w4", title: "Δίψηφα Φωνήεντα", colorA: "#FF6B9A", colorB: "#FFCD3C", lessons: [
            Lesson(id: "el_w4_1", title: "λουλούδι", icon: "🌸",
                   words: [w("λουλούδι", ["λ", "ου", "λ", "ού", "δ", "ι"], "🌸"),
                           w("σούπα", ["σ", "ού", "π", "α"], "🍲")]),
            Lesson(id: "el_w4_2", title: "ουρά", icon: "🐈",
                   words: [w("ουρά", ["ου", "ρ", "ά"], "🐈"), w("μούρο", ["μ", "ού", "ρ", "ο"], "🫐")]),
            Lesson(id: "el_w4_3", title: "αίμα", icon: "🩸",
                   words: [w("αίμα", ["αί", "μ", "α"], "🩸"), w("παιδί", ["π", "αι", "δ", "ί"], "🧒")]),
            Lesson(id: "el_w4_4", title: "αυγό", icon: "🥚",
                   words: [w("αυγό", ["αυ", "γ", "ό"], "🥚"), w("παπί", ["π", "α", "π", "ί"], "🐤")]),
        ])

        // U5 — voiced-stop digraphs (μπ=b, ντ=d, γκ=g) + τσ
        let u5 = Unit(id: "el_w5", title: "Δίψηφα Σύμφωνα", colorA: "#67C8FF", colorB: "#5BD16B", lessons: [
            Lesson(id: "el_w5_1", title: "μπάλα", icon: "⚽",
                   words: [w("μπάλα", ["μπ", "ά", "λ", "α"], "⚽"),
                           w("μπανάνα", ["μπ", "α", "ν", "ά", "ν", "α"], "🍌")]),
            Lesson(id: "el_w5_2", title: "ντομάτα", icon: "🍅",
                   words: [w("ντομάτα", ["ντ", "ο", "μ", "ά", "τ", "α"], "🍅"),
                           w("ντους", ["ντ", "ου", "ς"], "🚿")]),
            Lesson(id: "el_w5_3", title: "γκολ", icon: "🥅",
                   words: [w("γκολ", ["γκ", "ο", "λ"], "🥅"), w("τσάι", ["τσ", "ά", "ι"], "🍵")]),
        ])

        // U6 — putting it together: slightly longer mixed words
        let u6 = Unit(id: "el_w6", title: "Όλα Μαζί", colorA: "#FFCD3C", colorB: "#A78BFA", lessons: [
            Lesson(id: "el_w6_1", title: "ποτάμι", icon: "🏞️",
                   words: [w("ποτάμι", ["π", "ο", "τ", "ά", "μ", "ι"], "🏞️"),
                           w("καλαμάρι", ["κ", "α", "λ", "α", "μ", "ά", "ρ", "ι"], "🦑")]),
            Lesson(id: "el_w6_2", title: "ψωμί", icon: "🍞",
                   words: [w("ψωμί", ["ψ", "ω", "μ", "ί"], "🍞"),
                           w("μέλισσα", ["μ", "έ", "λ", "ι", "σσ", "α"], "🐝")]),
            Lesson(id: "el_w6_3", title: "φεγγάρι", icon: "🌙",
                   words: [w("φεγγάρι", ["φ", "ε", "γγ", "ά", "ρ", "ι"], "🌙"),
                           w("κεράσι", ["κ", "ε", "ρ", "ά", "σ", "ι"], "🍒")]),
        ])

        // STORIES — original decodable mini-stories built from learned words.
        // Each inner array is ONE PAGE; last page is "the end".
        let stories = Unit(id: "el_stories", title: "Ιστορίες", colorA: "#FF6B9A", colorB: "#FFCD3C", lessons: [
            Lesson(id: "el_st_1", title: "Η γάτα", icon: "🐱",
                   sentences: [["να", "η", "γάτα"],
                               ["η", "γάτα", "θέλει", "νερό"],
                               ["να", "το", "ψάρι"],
                               ["η", "γάτα", "και", "το", "ψάρι"],
                               ["τέλος"]]),
            Lesson(id: "el_st_2", title: "Το μωρό", icon: "👶",
                   sentences: [["να", "το", "μωρό"],
                               ["το", "μωρό", "θέλει", "μέλι"],
                               ["η", "μαμά", "και", "το", "μέλι"],
                               ["η", "μαμά", "και", "το", "μωρό"],
                               ["τέλος"]]),
            Lesson(id: "el_st_3", title: "Η μπάλα", icon: "⚽",
                   sentences: [["να", "η", "μπάλα"],
                               ["το", "παιδί", "θέλει", "γκολ"],
                               ["να", "το", "γκολ"],
                               ["γκολ", "και", "γκολ"],
                               ["τέλος"]]),
            Lesson(id: "el_st_4", title: "Η σούπα", icon: "🍲",
                   sentences: [["να", "η", "σούπα"],
                               ["σούπα", "και", "ψωμί"],
                               ["σούπα", "και", "πατάτα"],
                               ["η", "μαμά", "θέλει", "τσάι"],
                               ["τέλος"]]),
            Lesson(id: "el_st_5", title: "Η κότα", icon: "🐔",
                   sentences: [["να", "η", "κότα"],
                               ["η", "κότα", "θέλει", "αυγό"],
                               ["να", "το", "αυγό"],
                               ["η", "κότα", "και", "το", "αυγό"],
                               ["τέλος"]]),
            Lesson(id: "el_st_6", title: "Το ψάρι", icon: "🐟",
                   sentences: [["να", "το", "ψάρι"],
                               ["το", "ψάρι", "θέλει", "νερό"],
                               ["νερό", "και", "θάλασσα"],
                               ["το", "ψάρι", "και", "η", "θάλασσα"],
                               ["τέλος"]]),
            Lesson(id: "el_st_7", title: "Το παιδί", icon: "🧒",
                   sentences: [["να", "το", "παιδί"],
                               ["το", "παιδί", "θέλει", "μπανάνα"],
                               ["μπανάνα", "και", "μούρο"],
                               ["η", "μαμά", "και", "το", "παιδί"],
                               ["τέλος"]]),
            Lesson(id: "el_st_8", title: "Το λουλούδι", icon: "🌸",
                   sentences: [["να", "το", "λουλούδι"],
                               ["το", "λουλούδι", "θέλει", "νερό"],
                               ["να", "η", "μέλισσα"],
                               ["η", "μέλισσα", "και", "το", "λουλούδι"],
                               ["τέλος"]]),
            Lesson(id: "el_st_9", title: "Η ντομάτα", icon: "🍅",
                   sentences: [["να", "η", "ντομάτα"],
                               ["ντομάτα", "και", "πατάτα"],
                               ["ντομάτα", "και", "τυρί"],
                               ["η", "μαμά", "θέλει", "ψωμί"],
                               ["τέλος"]]),
            Lesson(id: "el_st_10", title: "Το φεγγάρι", icon: "🌙",
                   sentences: [["να", "το", "φεγγάρι"],
                               ["το", "μωρό", "θέλει", "το", "φεγγάρι"],
                               ["τόπι", "και", "φεγγάρι"],
                               ["η", "μαμά", "και", "το", "μωρό"],
                               ["τέλος"]]),
            Lesson(id: "el_st_11", title: "Το ποτάμι", icon: "🏞️",
                   sentences: [["να", "το", "ποτάμι"],
                               ["να", "το", "ψάρι"],
                               ["να", "το", "καλαμάρι"],
                               ["το", "ψάρι", "και", "το", "καλαμάρι"],
                               ["τέλος"]]),
            Lesson(id: "el_st_12", title: "Το λεμόνι", icon: "🍋",
                   sentences: [["να", "το", "λεμόνι"],
                               ["λεμόνι", "και", "νερό"],
                               ["η", "μαμά", "θέλει", "τσάι"],
                               ["τσάι", "και", "λεμόνι"],
                               ["τέλος"]]),
            Lesson(id: "el_st_13", title: "Η γάτα και το γκολ", icon: "🥅",
                   sentences: [["να", "η", "γάτα"],
                               ["να", "η", "μπάλα"],
                               ["η", "γάτα", "θέλει", "γκολ"],
                               ["γκολ"],
                               ["τέλος"]]),
            Lesson(id: "el_st_14", title: "Το πρωινό", icon: "🍞",
                   sentences: [["να", "το", "ψωμί"],
                               ["ψωμί", "και", "μέλι"],
                               ["ψωμί", "και", "τυρί"],
                               ["το", "παιδί", "θέλει", "μπανάνα"],
                               ["η", "μαμά", "και", "το", "παιδί"],
                               ["τέλος"]]),
        ])

        return [u1, u2, u3, u4, u5, u6, stories]
    }()
}