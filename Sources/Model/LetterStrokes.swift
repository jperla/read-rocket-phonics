import Foundation
import CoreGraphics

/// Centerline stroke paths for lowercase letters — the path a pencil actually
/// travels, so a child traces *down the middle* of each stroke (natural writing)
/// instead of around the outline of a fat glyph.
///
/// Coordinates are in a unit box (0…1, y-down). Guide lines:
///   ascender top 0.12 · x-height top 0.42 · baseline 0.82 · descender 0.97.
/// Each letter is one or more strokes; each stroke is an ordered polyline. The
/// reversible letters b/d/p/q differ only by stem side + ascender/descender, which
/// is exactly the motor distinction a child needs to learn.
enum LetterStrokes {
    static let aT: CGFloat = 0.12   // ascender top
    static let xT: CGFloat = 0.42   // x-height top
    static let mid: CGFloat = 0.62  // x-height middle (bowl center)
    static let base: CGFloat = 0.82 // baseline
    static let desc: CGFloat = 0.97 // descender bottom

    static let lx: CGFloat = 0.34
    static let cx: CGFloat = 0.50
    static let rx: CGFloat = 0.66
    static let brx: CGFloat = 0.16  // bowl x-radius
    static let bry: CGFloat = 0.20  // bowl y-radius

    private static func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x, y: y) }

    private static func ln(_ a: CGPoint, _ b: CGPoint, _ n: Int = 8) -> [CGPoint] {
        (0...n).map { i in let t = CGFloat(i) / CGFloat(n)
            return CGPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t) }
    }

    /// Ellipse arc. θ in degrees, y-down: 0°=right, 90°=bottom, 180°=left, 270°=top.
    private static func arc(_ cx: CGFloat, _ cy: CGFloat, _ rx: CGFloat, _ ry: CGFloat,
                            _ from: CGFloat, _ to: CGFloat, _ n: Int = 22) -> [CGPoint] {
        (0...n).map { i in
            let t = CGFloat(i) / CGFloat(n)
            let d = (from + (to - from) * t) * CGFloat.pi / 180
            return CGPoint(x: cx + rx * cos(d), y: cy + ry * sin(d))
        }
    }

    /// A top arch (left→over→right) used by h/n/m. Returns the arch plus the
    /// straight leg coming down on the right.
    private static func arch(_ cxc: CGFloat, _ topY: CGFloat, _ r: CGFloat, _ ry: CGFloat, _ legBottom: CGFloat) -> [CGPoint] {
        arc(cxc, topY, r, ry, 180, 360) + ln(p(cxc + r, topY), p(cxc + r, legBottom))
    }

    static func strokes(for letter: String) -> [[CGPoint]] {
        let bowl = arc(cx, mid, brx, bry, 270, 630)     // full bowl, start at top, clockwise
        switch letter.lowercased() {
        case "a": return [bowl, ln(p(cx + brx, xT), p(cx + brx, base))]
        case "b": return [ln(p(lx, aT), p(lx, base)), bowl]
        case "c": return [arc(cx, mid, brx, bry, 315, 45)]
        case "d": return [ln(p(rx, aT), p(rx, base)), bowl]
        case "e": return [ln(p(cx - brx, mid), p(cx + brx, mid)), arc(cx, mid, brx, bry, 0, -315)]
        case "f": return [ln(p(cx, aT + 0.02), p(cx, base)), ln(p(cx - brx, xT), p(cx + brx, xT))]
        case "g": return [bowl, ln(p(cx + brx, xT), p(cx + brx, base)) + arc(cx, base, brx, 0.14, 0, 175)]
        case "h": return [ln(p(lx, aT), p(lx, base)), arch(cx, xT + 0.10, brx, 0.12, base)]
        case "i": return [ln(p(cx, xT), p(cx, base)), arc(cx, aT + 0.06, 0.02, 0.02, 0, 360, 10)]
        case "j": return [ln(p(cx, xT), p(cx, desc - 0.04)) + arc(cx - 0.10, desc - 0.04, 0.10, 0.09, 0, 160),
                          arc(cx, aT + 0.06, 0.02, 0.02, 0, 360, 10)]
        case "k": return [ln(p(lx, aT), p(lx, base)), ln(p(rx, xT), p(lx, mid)), ln(p(lx, mid), p(rx, base))]
        case "l": return [ln(p(cx, aT), p(cx, base))]
        case "m": return [ln(p(0.30, xT), p(0.30, base)),
                          arch(0.40, xT + 0.08, 0.10, 0.09, base),
                          arch(0.60, xT + 0.08, 0.10, 0.09, base)]
        case "n": return [ln(p(lx, xT), p(lx, base)), arch(cx, xT + 0.10, brx, 0.12, base)]
        case "o": return [bowl]
        case "p": return [ln(p(lx, xT), p(lx, desc)), bowl]
        case "q": return [ln(p(rx, xT), p(rx, desc)), bowl]
        case "r": return [ln(p(lx, xT), p(lx, base)), arc(cx - 0.02, xT + 0.08, brx, 0.11, 180, 320)]
        case "s": return [arc(cx, xT + 0.07, brx * 0.82, 0.13, 300, 90)        // smooth top curl…
                            + arc(cx, base - 0.07, brx * 0.82, 0.13, 270, 495)] // …into the bottom curl
        case "t": return [ln(p(cx, aT + 0.08), p(cx, base)), ln(p(cx - brx, xT), p(cx + brx, xT))]
        case "u": return [ln(p(lx, xT), p(lx, base - 0.12)) + arc(cx, base - 0.12, brx, 0.12, 180, 0) + ln(p(rx, base - 0.12), p(rx, xT)),
                          ln(p(rx, xT), p(rx, base))]
        case "v": return [ln(p(lx, xT), p(cx, base)) + ln(p(cx, base), p(rx, xT))]
        case "w": return [ln(p(0.30, xT), p(0.42, base)) + ln(p(0.42, base), p(cx, xT + 0.06))
                            + ln(p(cx, xT + 0.06), p(0.58, base)) + ln(p(0.58, base), p(0.70, xT))]
        case "x": return [ln(p(lx, xT), p(rx, base)), ln(p(rx, xT), p(lx, base))]
        case "y": return [ln(p(lx, xT), p(cx, base)), ln(p(rx, xT), p(0.34, desc))]
        case "z": return [ln(p(lx, xT), p(rx, xT)) + ln(p(rx, xT), p(lx, base)) + ln(p(lx, base), p(rx, base))]
        case "ñ": return [ln(p(lx, xT), p(lx, base)), arch(cx, xT + 0.10, brx, 0.12, base),
                          ln(p(lx + 0.02, xT - 0.13), p(cx, xT - 0.20)) + ln(p(cx, xT - 0.20), p(rx - 0.02, xT - 0.13))]
        // German umlauts = base letter + two dots; ß ≈ tall stem with two right loops.
        case "ä": return [arc(cx, mid, brx, bry, 270, 630), ln(p(cx + brx, xT), p(cx + brx, base)),
                          arc(cx - 0.09, xT - 0.13, 0.028, 0.032, 0, 360, 8), arc(cx + 0.09, xT - 0.13, 0.028, 0.032, 0, 360, 8)]
        case "ö": return [arc(cx, mid, brx, bry, 270, 630),
                          arc(cx - 0.09, xT - 0.13, 0.028, 0.032, 0, 360, 8), arc(cx + 0.09, xT - 0.13, 0.028, 0.032, 0, 360, 8)]
        case "ü": return [ln(p(lx, xT), p(lx, base - 0.12)) + arc(cx, base - 0.12, brx, 0.12, 180, 0) + ln(p(rx, base - 0.12), p(rx, xT)),
                          arc(cx - 0.09, xT - 0.13, 0.028, 0.032, 0, 360, 8), arc(cx + 0.09, xT - 0.13, 0.028, 0.032, 0, 360, 8)]
        case "ß": return [ln(p(lx, base), p(lx, aT + 0.04)) + arc(cx - 0.02, aT + 0.13, 0.15, 0.11, 200, 380),
                          arc(cx - 0.02, mid + 0.02, 0.15, 0.13, 250, 70)]
        default:  return greekStrokes(letter.lowercased())
        }
    }

    /// Centerline skeletons for the 24 Greek lowercase letters (+ final ς). Print
    /// forms, traced down the middle. Approximate but recognizable; audit via
    /// `-lang el -strokesheet`.
    private static func greekStrokes(_ ch: String) -> [[CGPoint]] {
        let bowl = arc(cx, mid, brx, bry, 270, 630)
        switch ch {
        case "α": return [bowl, ln(p(cx + brx, xT + 0.04), p(cx + brx, base))]
        case "β": return [ln(p(lx, aT), p(lx, base)),
                          arc(cx, xT + 0.11, brx * 0.95, 0.11, 270, 630),
                          arc(cx, base - 0.11, brx * 0.95, 0.11, 270, 630)]
        case "γ": return [ln(p(lx, xT), p(cx, base)), ln(p(rx, xT), p(0.30, desc))]
        case "δ": return [arc(cx, mid, brx, bry, 30, 390), ln(p(cx + brx * 0.5, xT + 0.02), p(rx, aT + 0.06))]
        case "ε": return [arc(cx, xT + 0.10, brx * 0.9, 0.10, 330, 90),
                          arc(cx, base - 0.10, brx * 0.9, 0.10, 270, 60)]
        case "ζ": return [ln(p(lx, xT), p(rx, xT)) + ln(p(rx, xT), p(lx, base - 0.06))
                            + ln(p(lx, base - 0.06), p(cx, base)) + arc(cx - 0.06, desc - 0.04, 0.08, 0.07, 0, 150)]
        case "η": return [ln(p(lx, xT), p(lx, base)),
                          arc(cx, xT + 0.10, brx, 0.12, 180, 360) + ln(p(rx, xT + 0.10), p(rx, desc))]
        case "θ": return [bowl, ln(p(cx - brx * 0.7, mid), p(cx + brx * 0.7, mid))]
        case "ι": return [ln(p(cx, xT), p(cx, base)) + arc(cx + 0.05, base - 0.02, 0.05, 0.05, 180, 90)]
        case "κ": return [ln(p(lx, xT), p(lx, base)), ln(p(rx, xT), p(lx, mid)), ln(p(lx, mid), p(rx, base))]
        case "λ": return [ln(p(lx, base), p(cx, aT)) + ln(p(cx, aT), p(rx, base))]
        case "μ": return [ln(p(lx, xT), p(lx, desc)),
                          ln(p(lx, base - 0.10), p(lx, base - 0.10)) + arc(cx, base - 0.10, brx, 0.10, 180, 0) + ln(p(rx, base - 0.10), p(rx, xT))]
        case "ν": return [ln(p(lx, xT), p(cx, base)) + ln(p(cx, base), p(rx, xT))]
        case "ξ": return [arc(cx, xT + 0.06, brx * 0.8, 0.07, 320, 60)
                            + arc(cx, mid + 0.02, brx * 0.8, 0.08, 300, 70)
                            + ln(p(cx + 0.02, base), p(cx, desc - 0.02)) + arc(cx - 0.07, desc - 0.02, 0.07, 0.06, 0, 150)]
        case "ο": return [bowl]
        case "π": return [ln(p(lx - 0.02, xT), p(rx + 0.04, xT)),
                          ln(p(lx + 0.05, xT + 0.02), p(lx + 0.05, base)),
                          ln(p(rx - 0.03, xT + 0.02), p(rx - 0.03, base))]
        case "ρ": return [ln(p(lx, xT), p(lx, desc)), bowl]
        case "σ": return [bowl, ln(p(cx + brx * 0.6, xT + 0.05), p(rx + 0.08, xT + 0.02))]
        case "ς": return [arc(cx, mid, brx, bry, 320, 110) + arc(cx, base, brx * 0.6, 0.12, 270, 150)]
        case "τ": return [ln(p(cx, xT), p(cx, base)), ln(p(lx, xT), p(rx, xT))]
        case "υ": return [ln(p(lx, xT), p(lx, base - 0.12)) + arc(cx, base - 0.12, brx, 0.12, 180, 0) + ln(p(rx, base - 0.12), p(rx, xT))]
        case "φ": return [ln(p(cx, aT), p(cx, desc)), bowl]
        case "χ": return [ln(p(lx, xT), p(rx, base)), ln(p(rx, xT), p(lx, desc))]
        case "ψ": return [ln(p(cx, xT), p(cx, desc)), arc(cx, mid, brx, 0.18, 180, 0)]
        case "ω": return [arc(0.39, base - 0.06, 0.12, 0.13, 180, 0) + arc(0.61, base - 0.06, 0.12, 0.13, 180, 0)]
        default:  return []
        }
    }

    /// The natural starting point (for the green "start here" dot).
    static func start(for letter: String) -> CGPoint? { strokes(for: letter).first?.first }
}
