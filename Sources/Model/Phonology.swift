import Foundation

/// Context-sensitive grapheme→phoneme resolution for the DEEP-orthography packs
/// (German, French, Brazilian Portuguese), whose spelling is not 1:1 with sound.
///
/// Transparent packs (English, Greek, Spanish) keep the flat `map` lookup — their
/// orthographies are shallow, so a single primary phoneme per grapheme is already
/// correct. For the deep packs we resolve each grapheme's sound from its POSITION
/// and NEIGHBOURS at word-authoring time (inside `word()`), so the rest of the
/// engine still just reads `Grapheme.ipa`. Every grapheme string remains a key in
/// the pack's `map`, so the decodability invariant (graphemes join to the text and
/// each is a known grapheme) is preserved.
enum Phonology {

    /// Letters in the consonant graphemes between index `i` (exclusive) and the next
    /// vowel grapheme or word end — used to judge German vowel length / syllable shape.
    private static func consonantLetters(_ gs: [String], after i: Int, vowels: Set<String>) -> Int {
        var count = 0, j = i + 1
        while j < gs.count {
            if vowels.contains(gs[j]) { break }
            // x=/ks/ and z=/ts/ are single letters but consonant CLUSTERS, so they
            // shorten the preceding vowel (Hexe → /hɛksə/, not /heːksə/).
            count += (gs[j] == "x" || gs[j] == "z") ? 2 : gs[j].count
            j += 1
        }
        return count
    }

    private static func fallback(_ g: String, _ map: [String: String]) -> String? {
        if let v = map[g] { return v.isEmpty ? nil : v }
        return g
    }

    // MARK: - German
    // Voiced/voiceless s, final devoicing of b/d/g, vocalized final -r, schwa in
    // unstressed -e endings, and (long/short) vowel length from syllable shape.
    static let deVowels: Set<String> = ["a","e","i","o","u","ä","ö","ü","y","ei","ai","ie","eu","äu","au"]
    private static let deShort = ["a":"a","e":"ɛ","i":"ɪ","o":"ɔ","u":"ʊ","ä":"ɛ","ö":"œ","ü":"ʏ","y":"ʏ"]
    private static let deLong  = ["a":"aː","e":"eː","i":"iː","o":"oː","u":"uː","ä":"ɛː","ö":"øː","ü":"yː","y":"yː"]

    private static let deFrontV: Set<String> = ["e","i","ä","ö","ü","ie","ei","eu","äu"]
    static func german(_ gs: [String], _ i: Int, map: [String: String]) -> String? {
        let g = gs[i], last = gs.count - 1
        // 'ch' is the ich-Laut /ç/ after a front vowel, the ach-Laut /x/ after a back one
        if g == "ch" { return (i > 0 && deFrontV.contains(gs[i - 1])) ? "ç" : "x" }
        // single 's' → voiced /z/ at a syllable onset before a vowel; else voiceless /s/
        if g == "s" { return (i < last && deVowels.contains(gs[i + 1])) ? "z" : "s" }
        // final devoicing: b/d/g at the end of the word → p/t/k (Auslautverhärtung)
        if i == last, let dev = ["b": "p", "d": "t", "g": "k"][g] { return dev }
        // vocalized final -r after a vowel → /ɐ/ (Tor → /toːɐ/, Eimer → /aɪmɐ/)
        if g == "r", i == last, i > 0, deVowels.contains(gs[i - 1]) { return "ɐ" }
        // single vowels: schwa in unstressed endings, else length from syllable shape
        if let sv = deShort[g], let lv = deLong[g] {
            if g == "e" {                                   // unstressed schwa
                if i == last { return "ə" }                 // Nase, Hose
                if i == last - 1, gs[last] == "r" { return nil }            // -er: the r vocalizes to /ɐ/
                if i == last - 1, ["l","n","m"].contains(gs[last]) { return "ə" } // -el/-en/-em (Igel, atem)
            }
            if i == last { return sv }   // final unstressed vowel is short (Oma, Auto, Ufo)
            // short before a doubled consonant / cluster (≥2 consonant letters); else long
            return consonantLetters(gs, after: i, vowels: deVowels) >= 2 ? sv : lv
        }
        return fallback(g, map)
    }

    // MARK: - French
    // Open/closed o and eu by syllable shape; silent word-final -e (e muet).
    static let frVowels: Set<String> = ["a","e","i","o","u","y","à","â","é","è","ê","ë","î","ï","ô","û","ù","ü",
                                        "ou","ai","ei","au","eau","eu","oi"]
    static func french(_ gs: [String], _ i: Int, map: [String: String]) -> String? {
        let g = gs[i], last = gs.count - 1
        // 'o' → closed /o/ word-final or before a vowel; open /ɔ/ in a closed syllable
        if g == "o" { return (i == last || (i < last && frVowels.contains(gs[i + 1]))) ? "o" : "ɔ" }
        // 'eu' → /ø/ open (final), /œ/ closed (before a pronounced consonant: fleur)
        if g == "eu" { return i == last ? "ø" : "œ" }
        // silent word-final -e in polysyllables (robe, tomate, olive) — but not le/je/ce
        if g == "e", i == last, gs.count > 2 { return nil }
        return fallback(g, map)
    }

    // MARK: - Brazilian Portuguese
    // Intervocalic s→/z/, single r flap/strong, final-l vocalization, and unstressed
    // final vowel reduction (-o→/u/, -e→/i/). (Open/closed é/ê·ó/ô live in the map by accent.)
    static let ptVowels: Set<String> = ["a","e","i","o","u","á","â","ã","à","é","ê","í","ó","ô","õ","ú","ü"]
    static func portuguese(_ gs: [String], _ i: Int, map: [String: String]) -> String? {
        let g = gs[i], last = gs.count - 1
        // single 's' between vowels → voiced /z/ (casa, rosa); else /s/
        if g == "s" {
            return (i > 0 && i < last && ptVowels.contains(gs[i - 1]) && ptVowels.contains(gs[i + 1])) ? "z" : "s"
        }
        // single 'r': flap /ɾ/ between vowels; strong /h/ word-initial or after a consonant
        if g == "r" { return (i > 0 && ptVowels.contains(gs[i - 1])) ? "ɾ" : "h" }
        // Brazilian palatalization: t→/tʃ/, d→/dʒ/ before /i/ — incl. a reduced final -e
        // (tia→/tʃia/, tomate→/tomatʃi/), but NOT before /e/ or other vowels (dedo→/dedu/).
        if g == "t" || g == "d" {
            let beforeI = i < last && (gs[i + 1] == "i" || gs[i + 1] == "í" || (i + 1 == last && gs[i + 1] == "e"))
            if beforeI { return g == "t" ? "tʃ" : "dʒ" }
        }
        // word-final 'l' vocalizes to /w/ (sol, mel, azul)
        if g == "l", i == last, i > 0, ptVowels.contains(gs[i - 1]) { return "w" }
        // unstressed final vowel reduction: -o → /u/, -e → /i/ (pato → /patu/, leite → /lejtʃi/)
        if i == last {
            if g == "o" { return "u" }
            if g == "e" { return "i" }
        }
        return fallback(g, map)
    }

    // MARK: - European Portuguese
    // Differs from Brazilian: strong r is uvular /ʁ/ (not /h/); coda s → /ʃ/ (festa,
    // dois); NO t/d palatalization; dark final-l stays /l/ (no /w/ vocalization);
    // and STRONG unstressed reduction (-a → /ɐ/, -e → /ɨ/, -o → /u/).
    /// A grapheme that begins with a vowel sound (a single vowel, or a vowel-initial
    /// digraph like "ol", "ei", "ão") — so a preceding consonant is an onset.
    private static func ptStartsVowel(_ g: String) -> Bool {
        guard let c = g.first else { return false }
        return "aeiouáàâãéêíóôõúü".contains(c)
    }
    static func portugueseEU(_ gs: [String], _ i: Int, map: [String: String]) -> String? {
        let g = gs[i], last = gs.count - 1
        if g == "s" {
            let nextV = i < last && ptStartsVowel(gs[i + 1])
            if i > 0, ptVowels.contains(gs[i - 1]), nextV { return "z" }   // intervocalic → /z/ (casa)
            if i == last || !nextV { return "ʃ" }                          // coda (final / pre-consonant) → /ʃ/
            return "s"                                                      // onset before a vowel (sol, sapo)
        }
        // single 'r': flap /ɾ/ between vowels; strong uvular /ʁ/ initial or after a consonant
        if g == "r" { return (i > 0 && ptVowels.contains(gs[i - 1])) ? "ɾ" : "ʁ" }
        // unstressed final-vowel reduction (EP): -a → /ɐ/, -e → /ɨ/, -o → /u/
        if i == last {
            if g == "a" { return "ɐ" }
            if g == "e" { return "ɨ" }
            if g == "o" { return "u" }
        }
        return fallback(g, map)
    }
}
