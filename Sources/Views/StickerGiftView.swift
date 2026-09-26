import SwiftUI

/// A big, gift-opening sticker celebration — shown when a child earns a NEW sticker.
///
/// Three beats, Mentava-style, so earning a sticker feels like a real event:
///   1. WRAPPED   — a present bounces in with a bow; the child taps to open it
///                  (agency + anticipation, never a forced wait).
///   2. REVEAL    — the lid flies off, light bursts, confetti rains, and the sticker
///                  pops out HUGE with a spin and a fanfare.
///   3. COLLECT   — the sticker takes a little victory bob, the running total ticks
///                  up ("You have N stickers!"), and the Back-to-map button appears.
///
/// It lingers and keeps the confetti going so the moment is savorable, but every
/// stage can be advanced with a tap, so a 3-year-old is never trapped.
struct StickerGiftCelebration: View {
    let sticker: String
    let total: Int
    var onDone: () -> Void = {}

    private enum Beat { case wrapped, revealed }
    @State private var beat: Beat = .wrapped

    // animation state
    @State private var boxIn = false
    @State private var boxWiggle = false
    @State private var tapHint = false
    @State private var lidOff = false
    @State private var flashOp = 0.0
    @State private var stickerPop = false
    @State private var stickerBob = false
    @State private var showWord = false
    @State private var showCount = false
    @State private var showButton = false
    @State private var confettiToken = 0

    private let boxColor = Color(red: 0.96, green: 0.36, blue: 0.46)
    private let ribbon = Color(red: 1.0, green: 0.86, blue: 0.30)

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.16, green: 0.10, blue: 0.36),
                                    Color(red: 0.33, green: 0.18, blue: 0.55)],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            // bright flash at the instant the gift opens
            Color.white.opacity(flashOp).ignoresSafeArea().allowsHitTesting(false)

            ConfettiBurst(token: confettiToken)
                .allowsHitTesting(false)

            VStack(spacing: 22) {
                Spacer(minLength: 0)

                Text(beat == .wrapped ? "You earned a present!" : "New sticker!")
                    .font(.system(size: 38, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.25), radius: 4, y: 2)
                    .opacity(beat == .wrapped ? (boxIn ? 1 : 0) : (showWord ? 1 : 0))
                    .scaleEffect(showWord && beat == .revealed ? 1.0 : 0.9)

                ZStack {
                    if beat == .wrapped {
                        giftBox
                            .scaleEffect(boxIn ? (boxWiggle ? 1.04 : 1.0) : 0.1)
                            .rotationEffect(.degrees(boxWiggle ? -3 : 3))
                            .onTapGesture { openGift() }
                    } else {
                        Text(sticker)
                            .font(.system(size: 150))
                            .scaleEffect(stickerPop ? (stickerBob ? 1.06 : 1.0) : 0.05)
                            .rotationEffect(.degrees(stickerPop ? 0 : -220))
                            .shadow(color: ribbon.opacity(0.8), radius: 24)
                            .onTapGesture { SoundFX.shared.sparkle(); confettiToken += 1 }
                    }
                }
                .frame(height: 230)

                if beat == .wrapped {
                    Text("Tap to open! 🎁")
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundStyle(ribbon)
                        .opacity(tapHint ? 1 : 0.4)
                        .scaleEffect(tapHint ? 1.08 : 1.0)
                } else {
                    Text("You have \(total) sticker\(total == 1 ? "" : "s")!")
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .opacity(showCount ? 1 : 0)
                        .scaleEffect(showCount ? 1.0 : 0.7)
                }

                Spacer(minLength: 0)

                Button { onDone() } label: {
                    Text("Back to map")
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 44).padding(.vertical, 16)
                        .background(Capsule().fill(boxColor).shadow(color: boxColor.opacity(0.5), radius: 10, y: 6))
                        .overlay(Capsule().stroke(.white.opacity(0.6), lineWidth: 3))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("Back to map")
                .opacity(showButton ? 1 : 0)
                .padding(.bottom, 30)
            }
            .padding(.horizontal, 30)
        }
        .onAppear(perform: start)
    }

    // MARK: - Gift box (SwiftUI)

    private var giftBox: some View {
        ZStack {
            // lid (flies off on open)
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(boxColor)
                .frame(width: 180, height: 42)
                .overlay(Rectangle().fill(ribbon).frame(width: 26))
                .overlay(bow.offset(y: -26))
                .offset(y: lidOff ? -360 : -74)
                .rotationEffect(.degrees(lidOff ? -28 : 0), anchor: .bottomLeading)
                .opacity(lidOff ? 0 : 1)
            // box body
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(boxColor)
                .frame(width: 168, height: 130)
                .overlay(Rectangle().fill(ribbon).frame(width: 26))
                .offset(y: 12)
            // a peek of sparkle from inside as it opens
            Text("✨")
                .font(.system(size: 54))
                .opacity(lidOff ? 1 : 0)
                .offset(y: lidOff ? -40 : 0)
        }
    }

    private var bow: some View {
        HStack(spacing: -6) {
            Circle().fill(ribbon).frame(width: 26, height: 34).rotationEffect(.degrees(-22))
            Circle().fill(ribbon).frame(width: 26, height: 34).rotationEffect(.degrees(22))
        }
        .overlay(Circle().fill(ribbon).frame(width: 14, height: 14))
    }

    // MARK: - Choreography

    private func start() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.55)) { boxIn = true }
        withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) { boxWiggle = true }
        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) { tapHint = true }
        SoundFX.shared.sparkle()
        // auto-open after a generous beat if the child doesn't tap
        DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
            if beat == .wrapped { openGift() }
        }
    }

    private func openGift() {
        guard beat == .wrapped else { return }
        SoundFX.shared.fanfare()
        withAnimation(.easeOut(duration: 0.5)) { lidOff = true }
        flashOp = 0.7
        withAnimation(.easeOut(duration: 0.6)) { flashOp = 0 }
        confettiToken += 1
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            beat = .revealed
            withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) { stickerPop = true; showWord = true }
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) { stickerBob = true }
            // second confetti wave for a fuller party
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { confettiToken += 1 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) { showCount = true }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                confettiToken += 1
                withAnimation(.easeIn(duration: 0.4)) { showButton = true }
            }
        }
    }
}

/// A burst of falling confetti. Bumping `token` fires a fresh wave.
struct ConfettiBurst: View {
    var token: Int
    private let pieces = 64
    private let colors: [Color] = [.pink, .yellow, .green, .blue, .purple, .orange,
                                   Color(red: 1, green: 0.42, blue: 0.55),
                                   Color(red: 0.40, green: 0.78, blue: 1)]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(0..<pieces, id: \.self) { i in
                    ConfettiPiece(color: colors[i % colors.count],
                                  startX: xFor(i, width: geo.size.width),
                                  height: geo.size.height,
                                  delay: Double(i % 8) * 0.04,
                                  token: token)
                }
            }
        }
        .ignoresSafeArea()
    }

    // deterministic spread (no Math.random needed; varies by index)
    private func xFor(_ i: Int, width: CGFloat) -> CGFloat {
        let f = CGFloat((i * 53) % 100) / 100.0
        return f * width
    }
}

private struct ConfettiPiece: View {
    let color: Color
    let startX: CGFloat
    let height: CGFloat
    let delay: Double
    let token: Int

    @State private var fall = false

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(color)
            .frame(width: 10, height: 14)
            .rotationEffect(.degrees(fall ? Double((Int(startX) * 13) % 360) : 0))
            .position(x: startX + (fall ? CGFloat((Int(startX) % 7) - 3) * 18 : 0),
                      y: fall ? height + 30 : -30)
            .opacity(fall ? 0 : 1)
            .onChange(of: token) { _, _ in restart() }
    }

    private func restart() {
        fall = false
        withAnimation(.easeIn(duration: 1.8).delay(delay)) { fall = true }
    }
}
