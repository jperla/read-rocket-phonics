import Foundation

/// One "chunk" of a word the child sees as a single tile: a letter ("c"),
/// a digraph ("sh"), a vowel team ("ai"), etc. `ipa == nil` means it is silent
/// (e.g. the magic-e in "cake").
struct Grapheme: Codable, Hashable {
    let letters: String
    let ipa: String?
    var intentionallySilent: Bool = false

    var isSilent: Bool { ipa == nil || (ipa?.isEmpty ?? true) }
}

/// A decodable word with its grapheme → phoneme segmentation, so the app can
/// (a) show tappable tiles, (b) play each sound accurately, and (c) blend them.
struct PWord: Identifiable, Codable, Hashable {
    let text: String
    let graphemes: [Grapheme]
    var picture: String? = nil      // optional emoji shown as a hint

    var id: String { text }

    /// Indices of graphemes that actually make a sound, in order.
    var soundingIndices: [Int] {
        graphemes.indices.filter { !graphemes[$0].isSilent }
    }

    /// The phonemes spoken when blending, in order (silent graphemes excluded).
    var blendPlan: [String] { soundingIndices.compactMap { graphemes[$0].ipa } }

    /// IPA of the first sounded grapheme — for phonemic-awareness "first sound" games.
    var firstSoundIPA: String? { soundingIndices.first.flatMap { graphemes[$0].ipa } }
}

/// A per-language grapheme→phoneme pack. Conformers only supply `map`; the shared
/// `word()` builder and the default flat-lookup `ipa(for:at:)` live here, so the six
/// language packs no longer each duplicate the same builder. Deep-orthography packs
/// (German/French/Portuguese) override `ipa(for:at:)` to resolve context via `Phonology`.
protocol PhonicsPack {
    static var map: [String: String] { get }
    /// Resolve the IPA for grapheme `index` within a word's full grapheme list.
    /// Default: flat lookup (`""` → silent, missing → the grapheme itself).
    static func ipa(for graphemes: [String], at index: Int) -> String?
}

extension PhonicsPack {
    static func ipa(for graphemes: [String], at index: Int) -> String? {
        let g = graphemes[index]
        if let v = map[g] { return v.isEmpty ? nil : v }
        return g
    }

    /// Build a decodable word. A plain token ("c", "sh") gets its IPA from
    /// `ipa(for:at:)` (flat map or context resolver). A token may carry an inline
    /// override "disp:ipa" so a grapheme shows its real letters but sounds a
    /// non-primary reading ("ow:aʊ" → tile "ow", sound /aʊ/); "disp:" means silent.
    /// (Only flat packs use inline overrides, so the resolver never sees ":" tokens.)
    static func word(_ text: String, _ letters: [String], _ picture: String) -> PWord {
        // DISPLAY graphemes (an inline override "disp:ipa" → "disp") so the context
        // resolver sees clean neighbours — an override token must not corrupt the
        // length/voicing the engine computes for an adjacent grapheme.
        let disps = letters.map { tok -> String in
            if let r = tok.range(of: ":") { return String(tok[..<r.lowerBound]) }
            return tok
        }
        var gs: [Grapheme] = []
        for (i, tok) in letters.enumerated() {
            if let r = tok.range(of: ":") {
                let disp = String(tok[..<r.lowerBound]), ip = String(tok[r.upperBound...])
                gs.append(Grapheme(letters: disp, ipa: ip.isEmpty ? nil : ip, intentionallySilent: ip.isEmpty))
            } else {
                gs.append(Grapheme(letters: tok, ipa: ipa(for: disps, at: i)))
            }
        }
        return PWord(text: text, graphemes: gs, picture: picture)
    }
}

/// Phoneme tables + a compact word builder.
enum Phonics {
    /// Default IPA for a chunk spelling. Custom sounds (long vowels, voiced th,
    /// short oo, …) are passed inline in the builder as "display:ipa".
    static let chunkIPA: [String: String] = [
        // short vowels
        "a": "æ", "e": "ɛ", "i": "ɪ", "o": "ɑ", "u": "ʌ",
        // consonants
        "b": "b", "c": "k", "d": "d", "f": "f", "g": "g", "h": "h", "j": "dʒ",
        "k": "k", "l": "l", "m": "m", "n": "n", "p": "p", "q": "kw", "r": "r",
        "s": "s", "t": "t", "v": "v", "w": "w", "x": "ks", "y": "j", "z": "z",
        // consonant digraphs
        "sh": "ʃ", "ch": "tʃ", "th": "θ", "wh": "w", "ck": "k", "ng": "ŋ",
        "ph": "f", "qu": "kw",
        // doubled consonants → single sound
        "ll": "l", "ss": "s", "ff": "f", "zz": "z", "tt": "t", "dd": "d",
        "gg": "g", "nn": "n", "mm": "m", "pp": "p", "bb": "b", "rr": "r",
        // vowel teams
        "ai": "eɪ", "ay": "eɪ", "ee": "iː", "ea": "iː", "oa": "oʊ", "ow": "oʊ",
        "igh": "aɪ", "oo": "uː", "ew": "uː", "ue": "uː",
        "oi": "ɔɪ", "oy": "ɔɪ", "ou": "aʊ", "au": "ɔ", "aw": "ɔ",
        // r-controlled
        "ar": "ɑɹ", "or": "ɔɹ", "er": "ɝ", "ir": "ɝ", "ur": "ɝ"
    ]

    /// Build a word from chunk tokens.
    ///   "ck"     → looked up in `chunkIPA`
    ///   "a:eɪ"   → display "a", custom sound "eɪ" (long a)
    ///   "e:"     → display "e", silent
    static func word(_ text: String, _ tokens: [String], picture: String? = nil) -> PWord {
        var gs: [Grapheme] = []
        for tok in tokens {
            if let r = tok.range(of: ":") {
                let disp = String(tok[..<r.lowerBound])
                let ipa = String(tok[r.upperBound...])
                if ipa.isEmpty {
                    gs.append(Grapheme(letters: disp, ipa: nil, intentionallySilent: true))
                } else {
                    gs.append(Grapheme(letters: disp, ipa: ipa))
                }
            } else {
                gs.append(Grapheme(letters: tok, ipa: chunkIPA[tok]))
            }
        }
        return PWord(text: text, graphemes: gs, picture: picture)
    }
}
