import SwiftUI
import UIKit

/// Letter-embedded mnemonic art (the letter drawn AS its keyword object, e.g.
/// 's' as a snake) — a research-backed orthographic-mapping aid (Ehri). Codex
/// generated all 26; only the ones that a Gemini legibility audit confirmed
/// clearly read as their letter are bundled and used. The rest gracefully fall
/// back to the plain letter + keyword emoji, so a muddy image never ships.
enum MnemonicArt {
    /// Letters whose generated mnemonic passed the legibility audit (Gemini +
    /// human eyeball). Round 1 (15) + round 2 (a d j q x) + round 3 (g i r u).
    /// Still muddy → plain-emoji fallback (2): t (reads as a cross) and z
    /// (stripes fragment the letter). 24 of 26 covered.
    static let available: Set<String> = ["a", "b", "c", "d", "e", "f", "g", "h",
                                         "i", "j", "k", "l", "m", "n", "o", "p",
                                         "q", "r", "s", "u", "v", "w", "x", "y"]

    /// The bundled mnemonic image for a letter, or nil to fall back to plain art.
    /// UIImage(named:) uses UIKit's name cache — this is called from view `body`,
    /// so an uncached contentsOfFile decode would re-read the PNG every render.
    static func image(for letter: String) -> Image? {
        guard available.contains(letter),
              let ui = UIImage(named: "mnem_\(letter)") else { return nil }
        return Image(uiImage: ui).resizable()
    }
}
