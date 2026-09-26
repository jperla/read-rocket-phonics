import Foundation

/// The BLENDING BRIDGE between single letters and three-letter words.
///
/// Going straight from "this letter says /s/" to reading "cat" is a cliff — the
/// research sequence puts several rungs in between: blend just TWO sounds first
/// (VC real words like "at", "am"), then read short CVC words that begin with a
/// CONTINUANT (m/s/f), which can be held and gently glided into the vowel so the
/// child blends without pausing (continuous blending). Only after that do the
/// full CVC units begin. Each item is an ordinary `PWord`, so the existing
/// tile → sound-out → spell flow works unchanged; these are just shorter words.
enum Blending {
    private static func w(_ t: String, _ toks: [String], _ pic: String? = nil) -> PWord {
        Phonics.word(t, toks, picture: pic)
    }

    static let units: [Unit] = [
        // Two sounds only — the gentlest possible blend (vowel + one consonant).
        Unit(id: "blend1", title: "Blend Two Sounds", colorA: "#FFCD3C", colorB: "#FF9A6B", lessons: [
            Lesson(id: "bl_vc1", title: "at · am · an", icon: "🔤", words: [
                w("at", ["a","t"]), w("am", ["a","m"]), w("an", ["a","n"]), w("ap", ["a","p"])
            ]),
            Lesson(id: "bl_vc2", title: "it · in · is", icon: "🔡", words: [
                w("it", ["i","t"]), w("in", ["i","n"]), w("is", ["i","s"]), w("if", ["i","f"])
            ]),
            Lesson(id: "bl_vc3", title: "on · up · us", icon: "🆙", words: [
                w("on", ["o","n"]), w("ox", ["o","x"], "🦊"), w("up", ["u","p"]), w("us", ["u","s"])
            ])
        ]),
        // First whole words — continuant onsets (m/s/f) so they blend smoothly.
        Unit(id: "blend2", title: "Your First Words", colorA: "#67C8FF", colorB: "#A78BFA", lessons: [
            Lesson(id: "bl_cvc1", title: "mat · sat · man", icon: "🎉", words: [
                w("mat", ["m","a","t"]), w("sat", ["s","a","t"]),
                w("man", ["m","a","n"], "🧑"), w("fan", ["f","a","n"], "🪭")
            ]),
            Lesson(id: "bl_cvc2", title: "sit · fin · sip", icon: "🐟", words: [
                w("sit", ["s","i","t"], "🪑"), w("fin", ["f","i","n"], "🐟"),
                w("sip", ["s","i","p"]), w("fit", ["f","i","t"])
            ]),
            Lesson(id: "bl_cvc3", title: "sun · fun · mom", icon: "☀️", words: [
                w("sun", ["s","u","n"], "☀️"), w("fun", ["f","u","n"], "🎉"),
                w("mom", ["m","o","m"], "👩"), w("nut", ["n","u","t"], "🥜")
            ])
        ])
    ]

    static let lessonIDs: [String] = units.flatMap { $0.lessons.map { $0.id } }
}
