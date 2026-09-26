import SwiftUI

/// A clear, friendly cartoon mouth that forms the shape of a speech sound — with
/// lips, upper/lower teeth, and (crucially) TONGUE position, the articulation
/// cues children and parents need to copy the sound. Research (Seeing the Mouth,
/// 2023): kids master letter-sounds far faster when cued to watch the mouth, so
/// each new letter shows "Say it with me!" and this mouth forms the sound.
///
/// Each phoneme maps to a distinct, recognizable articulation.
enum MouthShape {
    case closed      // m b p — lips pressed together
    case lipTeeth    // f v — top teeth on bottom lip
    case round       // o w u oo oy ow — rounded lips
    case wide        // a — open wide, tongue low
    case smile       // e i ee — spread, teeth showing
    case tongueTip   // t d n l — tongue tip up behind top teeth
    case teeth       // s z — teeth together, small gap
    case rhotic      // r — tongue bunched / curled
    case open        // h and default — relaxed open

    /// Map an IPA phoneme to its mouth shape.
    static func from(ipa: String) -> MouthShape {
        switch ipa {
        case "m", "b", "p":                       return .closed
        case "f", "v":                            return .lipTeeth
        case "ɑ", "æ", "ʌ", "aʊ", "aɪ":           return .wide
        case "ɛ", "ɪ", "iː", "eɪ":                return .smile
        case "ɔ", "oʊ", "uː", "ʊ", "w", "ɔɪ":     return .round
        case "t", "d", "n", "l":                  return .tongueTip
        case "s", "z":                            return .teeth
        case "ɹ", "r":                            return .rhotic
        default:                                   return .open
        }
    }

    /// Short articulation hint shown under the mouth (for the grown-up too).
    var hint: String {
        switch self {
        case .closed:    return "Lips together"
        case .lipTeeth:  return "Teeth on lip"
        case .round:     return "Round your lips"
        case .wide:      return "Open wide"
        case .smile:     return "Smile — show teeth"
        case .tongueTip: return "Tongue up"
        case .teeth:     return "Teeth together"
        case .rhotic:    return "Curl your tongue"
        case .open:      return "Open"
        }
    }
}

private enum TonguePos { case none, low, tipUp, bunch }

struct MouthView: View {
    var shape: MouthShape
    var talking: Bool
    var size: CGFloat = 160

    // openness: rest is still readable; opens a touch more while talking.
    private var amt: CGFloat { talking ? 1.0 : 0.72 }

    var body: some View {
        Canvas { ctx, c in
            let w = c.width, h = c.height, cx = w / 2, cy = h / 2
            let lipC = Color(hex: "#D9536E")
            let lipHi = Color(hex: "#EC8198")
            let lipDk = Color(hex: "#A8324A")
            let innerC = Color(hex: "#56152A")
            let toothC = Color.white
            let toothLn = Color(hex: "#CBD3DC")
            let tongueC = Color(hex: "#EE8197")
            let tongueDk = Color(hex: "#D45F78")

            func rr(_ r: CGRect, _ cr: CGFloat) -> Path { Path(roundedRect: r, cornerRadius: max(0, cr)) }

            // ── lips pressed together: m b p ──────────────────────────────────
            if shape == .closed {
                let lw = w * 0.60, lh = h * 0.17
                ctx.fill(Path(ellipseIn: CGRect(x: cx - lw/2, y: cy - lh*0.95, width: lw, height: lh)), with: .color(lipC))
                ctx.fill(Path(ellipseIn: CGRect(x: cx - lw/2, y: cy - lh*0.05, width: lw, height: lh)), with: .color(lipC))
                var seam = Path(); seam.move(to: CGPoint(x: cx - lw/2 + 8, y: cy)); seam.addLine(to: CGPoint(x: cx + lw/2 - 8, y: cy))
                ctx.stroke(seam, with: .color(lipDk), style: StrokeStyle(lineWidth: max(2, w*0.022), lineCap: .round))
                return
            }
            // ── top teeth on bottom lip: f v ──────────────────────────────────
            if shape == .lipTeeth {
                let lw = w * 0.52
                ctx.fill(rr(CGRect(x: cx - lw*0.45, y: cy - h*0.08, width: lw*0.9, height: h*0.14), h*0.07), with: .color(innerC))
                ctx.fill(Path(ellipseIn: CGRect(x: cx - lw/2, y: cy + h*0.02, width: lw, height: h*0.18)), with: .color(lipC))
                let tw = lw*0.72, tth = h*0.09
                let tr = CGRect(x: cx - tw/2, y: cy + h*0.02 - tth*0.45, width: tw, height: tth)
                ctx.fill(rr(tr, tth*0.3), with: .color(toothC))
                for i in 1..<4 {
                    let x = tr.minX + tr.width*CGFloat(i)/4
                    var p = Path(); p.move(to: CGPoint(x: x, y: tr.minY+2)); p.addLine(to: CGPoint(x: x, y: tr.maxY-2))
                    ctx.stroke(p, with: .color(toothLn), lineWidth: max(1, w*0.006))
                }
                return
            }

            // ── general opening shapes ────────────────────────────────────────
            var ow = w*0.50, oh = h*0.46, corner = w*0.18, lipT = w*0.07
            var upperTeeth = false, lowerTeeth = false, tongue: TonguePos = .none
            switch shape {
            case .round:     ow = w*0.44; oh = h*0.52; corner = min(ow,oh)/2; lipT = w*0.09
            case .wide:      ow = w*0.58; oh = h*0.62; corner = ow*0.34; lipT = w*0.075; tongue = .low; upperTeeth = true
            case .smile:     ow = w*0.74; oh = h*0.34; corner = oh*0.5;  lipT = w*0.055; upperTeeth = true; lowerTeeth = true
            case .tongueTip: ow = w*0.56; oh = h*0.46; corner = ow*0.32; lipT = w*0.07;  upperTeeth = true; tongue = .tipUp
            case .teeth:     ow = w*0.60; oh = h*0.26; corner = oh*0.5;  lipT = w*0.05;  upperTeeth = true; lowerTeeth = true
            case .rhotic:    ow = w*0.46; oh = h*0.46; corner = ow*0.34; lipT = w*0.085; tongue = .bunch
            case .open:      ow = w*0.50; oh = h*0.48; corner = ow*0.36; lipT = w*0.07;  tongue = .low
            default: break
            }
            oh *= (0.8 + 0.2*amt)

            let outer = CGRect(x: cx - ow/2, y: cy - oh/2, width: ow, height: oh)
            ctx.fill(rr(outer, corner), with: .color(lipC))                            // lips
            ctx.stroke(rr(outer.insetBy(dx: lipT*0.45, dy: lipT*0.45), max(0, corner - lipT*0.45)),
                       with: .color(lipHi), lineWidth: max(1.5, w*0.012))               // lip highlight
            let cav = outer.insetBy(dx: lipT, dy: lipT)
            let cavPath = rr(cav, max(2, corner - lipT))
            ctx.fill(cavPath, with: .color(innerC))                                     // mouth cavity

            var ic = ctx; ic.clip(to: cavPath)
            // tongue (behind teeth)
            switch tongue {
            case .low:
                ic.fill(Path(ellipseIn: CGRect(x: cav.minX+cav.width*0.08, y: cav.maxY-cav.height*0.6,
                                               width: cav.width*0.84, height: cav.height)), with: .color(tongueC))
            case .tipUp:
                ic.fill(Path(ellipseIn: CGRect(x: cav.minX+cav.width*0.14, y: cav.minY+cav.height*0.14,
                                               width: cav.width*0.72, height: cav.height*1.15)), with: .color(tongueC))
                var groove = Path(); groove.move(to: CGPoint(x: cav.midX, y: cav.minY+cav.height*0.5)); groove.addLine(to: CGPoint(x: cav.midX, y: cav.maxY))
                ic.stroke(groove, with: .color(tongueDk), lineWidth: max(1.5, w*0.012))
            case .bunch:
                ic.fill(Path(ellipseIn: CGRect(x: cav.minX+cav.width*0.18, y: cav.minY+cav.height*0.28,
                                               width: cav.width*0.64, height: cav.height*0.68)), with: .color(tongueC))
            case .none: break
            }
            // teeth (front)
            func teeth(top: Bool) {
                let th = min(cav.height*0.42, h*0.16)
                let tr = CGRect(x: cav.minX+cav.width*0.05, y: top ? cav.minY : cav.maxY-th, width: cav.width*0.90, height: th)
                ic.fill(rr(tr, th*0.3), with: .color(toothC))
                for i in 1..<5 {
                    let x = tr.minX + tr.width*CGFloat(i)/5
                    var p = Path(); p.move(to: CGPoint(x: x, y: tr.minY+2)); p.addLine(to: CGPoint(x: x, y: tr.maxY-2))
                    ic.stroke(p, with: .color(toothLn), lineWidth: max(1, w*0.006))
                }
            }
            if upperTeeth { teeth(top: true) }
            if lowerTeeth { teeth(top: false) }
        }
        .frame(width: size, height: size)
        .animation(.easeInOut(duration: 0.25), value: talking)
        .accessibilityHidden(true)
    }
}

/// A mouth that forms `ipa` and animates whenever the app is speaking, with a
/// "Say it with me!" caption and an articulation hint. Tap to replay the sound.
struct SayWithMeMouth: View {
    let ipa: String
    var size: CGFloat = 150
    @ObservedObject private var speech = SpeechManager.shared
    private var shape: MouthShape { MouthShape.from(ipa: ipa) }

    var body: some View {
        VStack(spacing: 8) {
            Button { SpeechManager.shared.speakIPA(ipa) } label: {
                MouthView(shape: shape, talking: speech.isSpeaking, size: size)
                    .padding(14)
                    .background(Circle().fill(.white.opacity(0.95))
                        .shadow(color: .black.opacity(0.18), radius: 8, y: 4))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("slice_mouth")
            Text(Languages.active.t("say_with_me"))
                .font(.system(size: 17, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
            Text(shape.hint)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.82))
        }
    }
}

#Preview("Mouths") {
    ZStack {
        Theme.spaceGradient()
        VStack(spacing: 14) {
            HStack(spacing: 14) {
                MouthView(shape: .closed, talking: true, size: 110)
                MouthView(shape: .lipTeeth, talking: true, size: 110)
                MouthView(shape: .round, talking: true, size: 110)
            }
            HStack(spacing: 14) {
                MouthView(shape: .wide, talking: true, size: 110)
                MouthView(shape: .smile, talking: true, size: 110)
                MouthView(shape: .tongueTip, talking: true, size: 110)
            }
        }
    }
}
