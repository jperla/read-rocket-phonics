import SwiftUI
import UIKit

/// A critter that bobs and sways forever — the "dancing" in the dance party.
struct DancingCritter: View {
    let kind: CritterKind
    let size: CGFloat
    var phase: Double = 0
    @State private var up = false

    var body: some View {
        Critter(kind: kind, mood: .cheer, size: size)
            .offset(y: up ? -size * 0.16 : size * 0.02)
            .rotationEffect(.degrees(up ? 8 : -8))
            .onAppear {
                withAnimation(.easeInOut(duration: 0.42).repeatForever(autoreverses: true).delay(phase)) {
                    up = true
                }
            }
    }
}

/// End-of-lesson celebration.
///
/// • Medium (every lesson): the newly-earned mosaic tile peels away over the
///   hidden scene, stars pop, a few critters dance and a confetti burst falls.
/// • Huge (when a 16-tile poster completes): the final tile fills, the whole
///   scene BLOOMS, a row of critters dances, confetti waves keep coming and the
///   music swells — for about a minute. "Back to map" is always tappable, so a
///   3-year-old is never trapped.
struct LessonCelebrationView: View {
    let stars: Int
    let scene: PosterScene
    let tilesStart: Int          // tiles revealed BEFORE this win (0…15)
    let posterCompleted: Bool
    /// Non-nil = this is the child's FIRST-ever blast-off → offer the small
    /// grown-ups share button (parental-gated; never auto-presents anything).
    var shareName: String? = nil
    var fast: Bool = false
    var onDone: () -> Void = {}

    @State private var revealed = 0
    @State private var bloom = false
    @State private var showTitle = false
    @State private var confetti = 0
    @State private var shareGate: ParentalGate? = nil
    @State private var gatePassed = false
    @State private var showShare = false

    private var party: Bool { posterCompleted }
    private var boardSide: CGFloat { party ? 340 : 300 }

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.13, green: 0.09, blue: 0.32),
                                    Color(red: 0.30, green: 0.16, blue: 0.52)],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            if !fast { ConfettiBurst(token: confetti).allowsHitTesting(false) }

            VStack(spacing: 14) {
                Spacer(minLength: 6)

                Text(party && showTitle ? String(format: Languages.active.t("you_found"), scene.name) : Languages.active.t("blast_off"))
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .shadow(color: .black.opacity(0.3), radius: 3, y: 2)
                    .padding(.horizontal, 8)

                ZStack {
                    if bloom {
                        scene.illustration
                            .frame(width: boardSide, height: boardSide)
                            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous)
                                .stroke(.white.opacity(0.7), lineWidth: 4))
                            .transition(.scale.combined(with: .opacity))
                    } else {
                        MosaicBoard(scene: scene, revealed: revealed)
                            .frame(width: boardSide, height: boardSide)
                    }
                }
                .frame(width: boardSide, height: boardSide)

                StarRow(count: stars, size: 38)

                Text(Languages.active.t("great_job"))
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundStyle(Theme.sun)

                if !fast {
                    let n = party ? 6 : 3
                    HStack(spacing: party ? -4 : 12) {
                        ForEach(0..<n, id: \.self) { i in
                            DancingCritter(kind: CritterKind.allCases[i % CritterKind.allCases.count],
                                           size: party ? 60 : 48,
                                           phase: Double(i) * 0.11)
                        }
                    }
                    .frame(height: party ? 72 : 56)
                }

                Spacer(minLength: 6)

                VStack(spacing: 12) {
                    Button { onDone() } label: {
                        Text(Languages.active.t("back_to_map"))
                            .font(.system(size: 26, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 40).padding(.vertical, 15)
                            .background(Capsule().fill(Theme.coral))
                            .overlay(Capsule().stroke(.white.opacity(0.6), lineWidth: 3))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("Back to map")

                    if shareName != nil && !fast { shareButton }
                }
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 24)
        }
        // Both sheets are strictly button-triggered: the gate opens from the share
        // button, the system share sheet only after the gate is passed (Kids
        // category requires gating external shares).
        .sheet(item: $shareGate, onDismiss: {
            if gatePassed { gatePassed = false; showShare = true }
        }) { g in
            ParentalGateView(gate: g) { passed in
                gatePassed = passed
                shareGate = nil
            }
        }
        .sheet(isPresented: $showShare) {
            ShareSheet(text: shareText)
        }
        .onAppear(perform: start)
    }

    /// Small, unobtrusive word-of-mouth button — only on the FIRST-ever blast-off.
    private var shareButton: some View {
        Button { shareGate = ParentalGate() } label: {
            Label("Grown-ups: share this moment ⭐", systemImage: "square.and.arrow.up")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.85))
                .padding(.horizontal, 16).padding(.vertical, 8)
                .background(Capsule().fill(.white.opacity(0.12)))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("share_first_blastoff")
    }

    private var shareText: String {
        "🚀 \(shareName ?? "Our little reader") just sounded out their first words — all by themselves! "
        + "We're learning to read with Read Rocket: https://read.lorehex.co"
    }

    private func start() {
        guard !fast else {
            // Static, XCUITest-safe: no looping animations, no audio.
            revealed = min(tilesStart + 1, ProfileStore.tilesPerPoster)
            if party { bloom = true; showTitle = true }
            return
        }
        revealed = tilesStart
        confetti += 1
        SoundFX.shared.sparkle()
        MusicPlayer.shared.celebrate(seconds: party ? 56 : 18)

        // peel the freshly-earned tile
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation { revealed = tilesStart + 1 }
        }

        if party {
            // last tile fills → the whole scene blooms into a big party
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                SoundFX.shared.fanfare()
                withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) { bloom = true }
                confetti += 1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeOut(duration: 0.4)) { showTitle = true }
                SpeechManager.shared.speak(String(format: Languages.active.t("you_found"), scene.name))
            }
            // confetti keeps coming through the minute-long party
            for (i, t) in [2.5, 4.5, 7.0, 10.0, 14.0, 20.0, 30.0, 42.0].enumerated() {
                DispatchQueue.main.asyncAfter(deadline: .now() + t) {
                    confetti += 1
                    if i % 2 == 0 { SoundFX.shared.sparkle() }
                }
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { confetti += 1 }
        }
    }
}

/// UIActivityViewController wrapped for SwiftUI — presented as a sheet, which is
/// iPad-safe (no popover anchor needed). Sharing is user-initiated and handled
/// entirely by the system; the app itself makes no network calls.
private struct ShareSheet: UIViewControllerRepresentable {
    let text: String
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [text], applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview("Medium") {
    LessonCelebrationView(stars: 3, scene: .ocean, tilesStart: 6, posterCompleted: false)
}
#Preview("Huge party") {
    LessonCelebrationView(stars: 3, scene: .rocket, tilesStart: 15, posterCompleted: true)
}
#Preview("First blast-off share") {
    LessonCelebrationView(stars: 3, scene: .ocean, tilesStart: 0, posterCompleted: false, shareName: "Zoe")
}
