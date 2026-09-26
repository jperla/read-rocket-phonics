import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Kinds & moods

enum CritterKind: String, CaseIterable {
    case fox, bunny, bear, kitty, dog, pig, frog, mouse, penguin, owl

    var body: Color {
        switch self {
        case .fox:     return Color(hex: "#FF8A4C")
        case .bunny:   return Color(hex: "#E7DEF6")
        case .bear:    return Color(hex: "#C58B5C")
        case .kitty:   return Color(hex: "#AEB7C2")
        case .dog:     return Color(hex: "#E0A85A")
        case .pig:     return Color(hex: "#F49AC2")
        case .frog:    return Color(hex: "#6FCF77")
        case .mouse:   return Color(hex: "#B7BEC9")
        case .penguin: return Color(hex: "#3C4A66")
        case .owl:     return Color(hex: "#B98A52")
        }
    }
    var inner: Color {
        switch self {
        case .fox:     return Color(hex: "#FFEAD8")
        case .bunny:   return Color(hex: "#FFD9E6")
        case .bear:    return Color(hex: "#EAD3B8")
        case .kitty:   return Color(hex: "#FFD9E6")
        case .dog:     return Color(hex: "#FFF0D8")
        case .pig:     return Color(hex: "#FFE3EF")
        case .frog:    return Color(hex: "#CFF0CF")
        case .mouse:   return Color(hex: "#FFE6EC")
        case .penguin: return Color(hex: "#FFFFFF")
        case .owl:     return Color(hex: "#F0DCC0")
        }
    }
    var earStyle: EarStyle {
        switch self {
        case .fox, .kitty, .dog, .pig, .owl: return .pointy
        case .bear, .frog, .mouse, .penguin: return .round
        case .bunny:                          return .long
        }
    }
    var hasWhiskers: Bool { self == .fox || self == .kitty || self == .mouse }
}

enum EarStyle { case pointy, round, long }
enum CritterMood { case idle, happy, cheer, oops }

func critterKind(forProfile id: String) -> CritterKind {
    CritterKind(rawValue: id) ?? .fox
}

private extension Color {
    /// Lighten (d>0) or darken (d<0) for soft gradients & outlines.
    func adjust(_ d: CGFloat) -> Color {
        #if canImport(UIKit)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a)
        return Color(red: min(max(r + d, 0), 1), green: min(max(g + d, 0), 1),
                     blue: min(max(b + d, 0), 1)).opacity(Double(a))
        #else
        return self
        #endif
    }
}

// MARK: - Helper shapes

private struct Tri: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.midX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

/// Quadratic curve. depth>0 bows down (smile), depth<0 bows up (frown / happy eye).
private struct Curve: Shape {
    var depth: CGFloat
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.midY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.midY),
                       control: CGPoint(x: r.midX, y: r.midY + depth))
        return p
    }
}

// MARK: - Critter

struct Critter: View {
    var kind: CritterKind
    var mood: CritterMood = .idle
    var talking: Bool = false
    var size: CGFloat = 140

    @State private var blink = false
    @State private var breathe = false
    @State private var mouthOpen = false
    @State private var jump = false

    private let ink = Color(hex: "#2B2350")

    var body: some View {
        let s = size
        ZStack {
            // grounding shadow
            Ellipse().fill(.black.opacity(0.10))
                .frame(width: s * 0.50, height: s * 0.09)
                .blur(radius: s * 0.012)
                .position(x: s * 0.5, y: s * 0.93)

            ears(s)

            // body with soft vertical gradient + subtle outline
            Ellipse()
                .fill(LinearGradient(colors: [kind.body.adjust(0.10), kind.body.adjust(-0.07)],
                                     startPoint: .top, endPoint: .bottom))
                .frame(width: s * 0.82, height: s * 0.80)
                .position(x: s * 0.5, y: s * 0.55)
            Ellipse().stroke(kind.body.adjust(-0.16), lineWidth: s * 0.012)
                .frame(width: s * 0.82, height: s * 0.80)
                .position(x: s * 0.5, y: s * 0.55)
            // top sheen
            Ellipse().fill(.white.opacity(0.18))
                .frame(width: s * 0.46, height: s * 0.20)
                .blur(radius: s * 0.02)
                .position(x: s * 0.5, y: s * 0.34)

            // muzzle / belly
            Ellipse()
                .fill(LinearGradient(colors: [kind.inner.adjust(0.05), kind.inner.adjust(-0.05)],
                                     startPoint: .top, endPoint: .bottom))
                .frame(width: s * 0.50, height: s * 0.44)
                .position(x: s * 0.5, y: s * 0.63)

            // front paws
            paw(s, 0.40); paw(s, 0.60)

            // cheeks
            cheek(s, 0.29); cheek(s, 0.71)

            // nose
            ZStack {
                Tri().fill(ink).rotationEffect(.degrees(180))
                    .frame(width: s * 0.10, height: s * 0.075)
                Circle().fill(.white.opacity(0.5)).frame(width: s * 0.02)
                    .offset(x: -s * 0.012, y: -s * 0.012)
            }
            .position(x: s * 0.5, y: s * 0.545)

            if kind.hasWhiskers { whiskers(s) }

            // eyes
            eye(s, 0.36); eye(s, 0.64)

            // mouth
            mouth(s)
        }
        .frame(width: s, height: s)
        .accessibilityHidden(true)   // decorative — keeps the a11y tree (and XCUITest) fast
        .scaleEffect(x: breathe ? 1.03 : 0.99, y: breathe ? 0.97 : 1.01, anchor: .bottom)
        .offset(y: jump ? -s * 0.12 : 0)
        .onAppear {
            if !AppEnv.uiTesting {
                withAnimation(.easeInOut(duration: 1.7).repeatForever(autoreverses: true)) { breathe = true }
            }
        }
        .task { await blinkLoop() }
        .task(id: talking) { await talkLoop() }
        .onChange(of: mood) { _, m in if m == .cheer || m == .happy { doJump() } }
    }

    // MARK: parts

    private func paw(_ s: CGFloat, _ fx: CGFloat) -> some View {
        Ellipse().fill(kind.body.adjust(-0.05))
            .frame(width: s * 0.16, height: s * 0.10)
            .position(x: s * fx, y: s * 0.885)
    }

    private func cheek(_ s: CGFloat, _ fx: CGFloat) -> some View {
        Circle().fill(Color(hex: "#FF9FB2").opacity(0.5))
            .frame(width: s * 0.16)
            .blur(radius: s * 0.012)
            .position(x: s * fx, y: s * 0.62)
    }

    @ViewBuilder private func ears(_ s: CGFloat) -> some View {
        switch kind.earStyle {
        case .pointy:
            Tri().fill(LinearGradient(colors: [kind.body.adjust(0.06), kind.body.adjust(-0.05)],
                                      startPoint: .top, endPoint: .bottom))
                .frame(width: s * 0.27, height: s * 0.30)
                .rotationEffect(.degrees(-10)).position(x: s * 0.30, y: s * 0.15)
            Tri().fill(kind.inner).frame(width: s * 0.12, height: s * 0.15)
                .rotationEffect(.degrees(-10)).position(x: s * 0.30, y: s * 0.18)
            Tri().fill(LinearGradient(colors: [kind.body.adjust(0.06), kind.body.adjust(-0.05)],
                                      startPoint: .top, endPoint: .bottom))
                .frame(width: s * 0.27, height: s * 0.30)
                .rotationEffect(.degrees(10)).position(x: s * 0.70, y: s * 0.15)
            Tri().fill(kind.inner).frame(width: s * 0.12, height: s * 0.15)
                .rotationEffect(.degrees(10)).position(x: s * 0.70, y: s * 0.18)
        case .round:
            Circle().fill(kind.body.adjust(-0.02)).frame(width: s * 0.27).position(x: s * 0.27, y: s * 0.17)
            Circle().fill(kind.inner).frame(width: s * 0.14).position(x: s * 0.27, y: s * 0.17)
            Circle().fill(kind.body.adjust(-0.02)).frame(width: s * 0.27).position(x: s * 0.73, y: s * 0.17)
            Circle().fill(kind.inner).frame(width: s * 0.14).position(x: s * 0.73, y: s * 0.17)
        case .long:
            longEar(s, 0.39, -8); longEar(s, 0.61, 8)
        }
    }

    private func longEar(_ s: CGFloat, _ fx: CGFloat, _ deg: Double) -> some View {
        ZStack {
            Capsule().fill(LinearGradient(colors: [kind.body.adjust(0.06), kind.body.adjust(-0.05)],
                                          startPoint: .top, endPoint: .bottom))
                .frame(width: s * 0.15, height: s * 0.42)
            Capsule().fill(kind.inner).frame(width: s * 0.07, height: s * 0.30)
        }
        .rotationEffect(.degrees(deg)).position(x: s * fx, y: s * 0.11)
    }

    private func whiskers(_ s: CGFloat) -> some View {
        ForEach([-1.0, 1.0], id: \.self) { side in
            ForEach([-0.02, 0.03], id: \.self) { dy in
                Capsule().fill(ink.opacity(0.4))
                    .frame(width: s * 0.18, height: s * 0.012)
                    .position(x: s * (0.5 + side * 0.26), y: s * (0.60 + dy))
            }
        }
    }

    @ViewBuilder private func eye(_ s: CGFloat, _ fx: CGFloat) -> some View {
        if mood == .happy || mood == .cheer {
            Curve(depth: -s * 0.07)
                .stroke(ink, style: StrokeStyle(lineWidth: s * 0.04, lineCap: .round))
                .frame(width: s * 0.16, height: s * 0.09)
                .position(x: s * fx, y: s * 0.46)
        } else {
            ZStack {
                Ellipse().fill(ink)
                    .frame(width: s * 0.13, height: s * 0.16)
                    .scaleEffect(y: blink ? 0.10 : 1)
                Circle().fill(.white).frame(width: s * 0.05)
                    .offset(x: s * 0.018, y: -s * 0.035).opacity(blink ? 0 : 1)
                Circle().fill(.white.opacity(0.85)).frame(width: s * 0.022)
                    .offset(x: -s * 0.02, y: s * 0.025).opacity(blink ? 0 : 1)
            }
            .position(x: s * fx, y: s * 0.46)
        }
    }

    @ViewBuilder private func mouth(_ s: CGFloat) -> some View {
        let open = (talking && mouthOpen) || mood == .cheer
        if open {
            ZStack {
                Ellipse().fill(Color(hex: "#5A2A3A"))
                    .frame(width: s * 0.16, height: s * (mood == .cheer ? 0.16 : 0.11))
                Ellipse().fill(Color(hex: "#FF8FA3"))
                    .frame(width: s * 0.09, height: s * 0.05).offset(y: s * 0.03)
            }
            .position(x: s * 0.5, y: s * 0.66)
        } else if mood == .oops {
            Curve(depth: -s * 0.05)
                .stroke(ink, style: StrokeStyle(lineWidth: s * 0.03, lineCap: .round))
                .frame(width: s * 0.18, height: s * 0.08)
                .position(x: s * 0.5, y: s * 0.68)
        } else {
            Curve(depth: s * 0.06)
                .stroke(ink, style: StrokeStyle(lineWidth: s * 0.03, lineCap: .round))
                .frame(width: s * 0.20, height: s * 0.08)
                .position(x: s * 0.5, y: s * 0.64)
        }
    }

    // MARK: animation loops

    private func blinkLoop() async {
        if AppEnv.uiTesting { return }
        while !Task.isCancelled {
            try? await Task.sleep(nanoseconds: UInt64(Double.random(in: 2.0...4.5) * 1_000_000_000))
            withAnimation(.easeInOut(duration: 0.10)) { blink = true }
            try? await Task.sleep(nanoseconds: 130_000_000)
            withAnimation(.easeInOut(duration: 0.10)) { blink = false }
        }
    }

    private func talkLoop() async {
        guard talking, !AppEnv.uiTesting else { mouthOpen = false; return }
        while !Task.isCancelled && talking {
            withAnimation(.easeInOut(duration: 0.10)) { mouthOpen.toggle() }
            try? await Task.sleep(nanoseconds: 150_000_000)
        }
        mouthOpen = false
    }

    private func doJump() {
        guard !AppEnv.uiTesting else { return }
        withAnimation(.spring(response: 0.28, dampingFraction: 0.45)) { jump = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.6)) { jump = false }
        }
    }
}

// MARK: - Speech bubble + mascot row

struct SpeechBubble: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.system(size: 24, weight: .heavy, design: .rounded))
            .foregroundStyle(Theme.ink)
            .multilineTextAlignment(.leading)
            .padding(.horizontal, 22).padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(.white)
                    .shadow(color: .black.opacity(0.15), radius: 6, y: 3)
            )
            .overlay(alignment: .bottomLeading) {
                Tri().fill(.white)
                    .frame(width: 26, height: 20)
                    .rotationEffect(.degrees(-150))
                    .offset(x: -8, y: 10)
            }
    }
}

/// Guide mascot: an animated critter + a speech bubble. Mouth flaps while the
/// app is talking (observes SpeechManager).
struct MascotView: View {
    var kind: CritterKind
    var mood: CritterMood = .idle
    var line: String? = nil
    var size: CGFloat = 120

    @ObservedObject private var speech = SpeechManager.shared

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            Critter(kind: kind, mood: mood, talking: speech.isSpeaking, size: size)
            if let line {
                SpeechBubble(text: line)
                Spacer(minLength: 0)
            }
        }
    }
}

#Preview("Critters") {
    ZStack {
        Theme.background(Theme.bgTop, Theme.bgBottom)
        VStack(spacing: 24) {
            HStack(spacing: 16) {
                ForEach(CritterKind.allCases, id: \.self) { k in
                    Critter(kind: k, size: 130)
                }
            }
            HStack(spacing: 16) {
                Critter(kind: .fox, mood: .happy, size: 130)
                Critter(kind: .bunny, mood: .cheer, size: 130)
                Critter(kind: .bear, mood: .oops, size: 130)
                Critter(kind: .kitty, mood: .idle, talking: true, size: 130)
            }
        }
    }
}
