import SwiftUI

/// Trace‑the‑letter activity. The child drags a finger **down the middle** of each
/// stroke — the path a pencil actually travels — not around the outline of a fat
/// glyph. The letter is drawn as a uniform-width "road" (handwriting style) with a
/// dashed centerline, a green "start here" dot + arrow, and checkpoints along the
/// centerline that light up as they're covered.
///
/// Centerline strokes come from `LetterStrokes`. The stem-side / ascender-descender
/// differences between b/d/p/q are exactly what builds the motor memory that keeps
/// a child from flipping them. Forgiving by design (big hit radius, any stroke
/// order, effort also counts) so a 3‑year‑old always succeeds.
struct TracingView: View {
    let letter: String
    var reps: Int = 1                             // trace it this many times (b/d/p/q: many)
    var onRep: (() -> Void)? = nil               // after each non-final rep (e.g. say the mnemonic)
    var onComplete: () -> Void = {}

    @State private var strokes: [[CGPoint]] = []  // centerline strokes (view space)
    @State private var points: [CGPoint] = []     // checkpoints along the centerlines
    @State private var startPt: CGPoint? = nil
    @State private var startAngle: Double = 0
    @State private var hit: Set<Int> = []
    @State private var trail: [CGPoint] = []
    @State private var done = false               // current rep finished
    @State private var laidOut = CGSize.zero
    @State private var dragDist: CGFloat = 0      // total finger travel (effort)
    @State private var rep = 0
    @State private var allDone = false
    @State private var backstopToken = 0

    @State private var roadWidth: CGFloat = 40

    private let hitRadius: CGFloat = 34
    private let threshold = 0.72                  // forgiving for little hands

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // the letter as a uniform-width "road" to trace along
                ForEach(strokes.indices, id: \.self) { s in
                    strokePath(strokes[s])
                        .stroke(Theme.ink.opacity(0.13),
                                style: StrokeStyle(lineWidth: roadWidth, lineCap: .round, lineJoin: .round))
                    strokePath(strokes[s])
                        .stroke(Theme.ink.opacity(0.35),
                                style: StrokeStyle(lineWidth: 2.5, lineCap: .round, dash: [2, 10]))
                }

                // the child's finger trail
                Path { p in
                    guard let f = trail.first else { return }
                    p.move(to: f); for pt in trail.dropFirst() { p.addLine(to: pt) }
                }
                .stroke(Theme.coral, style: StrokeStyle(lineWidth: roadWidth * 0.62, lineCap: .round, lineJoin: .round))
                .opacity(0.9)

                // checkpoints along the centerline
                ForEach(points.indices, id: \.self) { i in
                    Circle()
                        .fill(hit.contains(i) ? Theme.grass : Color.white)
                        .overlay(Circle().stroke(hit.contains(i) ? Theme.grass : Theme.ink.opacity(0.25), lineWidth: 2))
                        .frame(width: 14, height: 14)
                        .scaleEffect(hit.contains(i) ? 1.25 : 1.0)
                        .position(points[i])
                }

                // "start here" dot + direction arrow
                if let s = startPt, !done {
                    ZStack {
                        Circle().fill(Theme.grass).frame(width: 30, height: 30)
                        Image(systemName: "play.fill")
                            .font(.system(size: 13, weight: .black)).foregroundStyle(.white)
                            .rotationEffect(.degrees(startAngle))
                    }
                    .position(s)
                }

                if reps > 1 {
                    repDots
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        .padding(.top, 6)
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { v in
                        guard !done, !allDone else { return }
                        if let last = trail.last { dragDist += hypot(v.location.x - last.x, v.location.y - last.y) }
                        trail.append(v.location)
                        for (i, p) in points.enumerated() where !hit.contains(i) {
                            if hypot(p.x - v.location.x, p.y - v.location.y) <= hitRadius { hit.insert(i) }
                        }
                        let coverage = points.isEmpty ? 0 : Double(hit.count) / Double(points.count)
                        let enoughEffort = dragDist >= CGFloat(max(20, points.count)) * 45
                        if coverage >= threshold || enoughEffort { finishRep() }
                    }
                    .onEnded { _ in trail.removeAll() }
            )
            .onAppear {
                if AppEnv.uiTesting { DispatchQueue.main.async { onComplete() }; return }
                layout(in: geo.size)
                scheduleBackstop()
            }
            .onChange(of: geo.size) { _, s in layout(in: s) }
        }
    }

    private func strokePath(_ pts: [CGPoint]) -> Path {
        Path { p in
            guard let f = pts.first else { return }
            p.move(to: f); for q in pts.dropFirst() { p.addLine(to: q) }
        }
    }

    private var repDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<reps, id: \.self) { i in
                Image(systemName: i < rep ? "star.fill" : "star")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(i < rep ? Theme.sun : Theme.ink.opacity(0.28))
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 5)
        .background(Capsule().fill(.white.opacity(0.85)))
    }

    private func finishRep() {
        guard !done, !allDone else { return }
        done = true
        hit = Set(points.indices)
        Haptics.success()
        SoundFX.shared.sparkle()
        rep += 1
        if rep < reps {
            onRep?()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { resetForNextRep() }
        } else {
            completeAll()
        }
    }

    private func resetForNextRep() {
        guard !allDone else { return }
        hit = []; trail = []; dragDist = 0; done = false
        scheduleBackstop()
    }

    private func completeAll() {
        guard !allDone else { return }
        allDone = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { onComplete() }
    }

    private func scheduleBackstop() {
        backstopToken += 1
        let tok = backstopToken
        DispatchQueue.main.asyncAfter(deadline: .now() + 16) {
            if tok == backstopToken, !done, !allDone { finishRep() }
        }
    }

    private func layout(in size: CGSize) {
        guard size.width > 0, size != laidOut else { return }
        laidOut = size
        let pad: CGFloat = 28
        let side = max(1, min(size.width, size.height) - 2 * pad)
        let ox = (size.width - side) / 2, oy = (size.height - side) / 2
        let unit = LetterStrokes.strokes(for: letter)
        let mapped = unit.map { stroke in stroke.map { CGPoint(x: ox + $0.x * side, y: oy + $0.y * side) } }
        strokes = mapped
        roadWidth = max(26, side * 0.12)

        // checkpoints: every centerline point, thinned to an even spread
        let all = mapped.flatMap { $0 }
        points = TracingView.thin(all, minGap: 24)
        if let s = mapped.first, let a = s.first {
            startPt = a
            let b = s.count > 1 ? s[1] : a
            startAngle = Double(atan2(b.y - a.y, b.x - a.x)) * 180 / .pi
        } else {
            startPt = nil
        }
        hit = []; trail = []; done = false; dragDist = 0
        if points.isEmpty { completeAll() }   // unknown letter → never dead-end
    }

    private static func thin(_ pts: [CGPoint], minGap: CGFloat) -> [CGPoint] {
        var out: [CGPoint] = []
        for p in pts where !out.contains(where: { hypot($0.x - p.x, $0.y - p.y) < minGap }) { out.append(p) }
        return out
    }
}

#Preview("Trace b") {
    TracingView(letter: "b").frame(width: 320, height: 360).background(.white)
}

/// Debug: all 26 lowercase letterforms (centerline roads) in a grid, for a visual
/// audit of the stroke shapes. Launch with `-strokesheet`.
struct StrokeSheetView: View {
    private var letters: [String] { Languages.active.letters.map { $0.letter } }
    private let cols = [GridItem(.adaptive(minimum: 110), spacing: 6)]
    var body: some View {
        ScrollView {
            LazyVGrid(columns: cols, spacing: 6) {
                ForEach(letters, id: \.self) { ch in
                    VStack(spacing: 2) {
                        GeometryReader { g in
                            let side = min(g.size.width, g.size.height)
                            ZStack {
                                ForEach(Array(LetterStrokes.strokes(for: ch).enumerated()), id: \.offset) { _, st in
                                    Path { p in
                                        let pts = st.map { CGPoint(x: $0.x * side, y: $0.y * side) }
                                        guard let f = pts.first else { return }
                                        p.move(to: f); for q in pts.dropFirst() { p.addLine(to: q) }
                                    }
                                    .stroke(Theme.ink, style: StrokeStyle(lineWidth: side * 0.11, lineCap: .round, lineJoin: .round))
                                }
                                if let s0 = LetterStrokes.start(for: ch) {
                                    Circle().fill(Theme.grass).frame(width: 10, height: 10)
                                        .position(x: s0.x * side, y: s0.y * side)
                                }
                            }
                        }
                        .frame(height: 110)
                        .background(RoundedRectangle(cornerRadius: 10).fill(.white))
                        Text(ch).font(.caption.bold()).foregroundStyle(.white)
                    }
                }
            }
            .padding(10)
        }
        .background(Theme.background(Theme.bgTop, Theme.bgBottom))
    }
}
