import SwiftUI

/// Grown-ups tool: tap any letter / letter-team to hear the exact sound the app
/// teaches, so a parent can verify every phoneme on the real device. Audio is
/// produced through the same SpeechManager path the lessons use (SSML IPA with
/// the schwa-release for stops + the /j/ glide), so what you hear here is what
/// the child hears. "Play all" walks through every sound in order.
struct SoundCheckView: View {
    var done: () -> Void = {}

    private let groups: [(String, [String])] = [
        ("Short vowels", ["a", "e", "i", "o", "u"]),
        ("Consonants", ["b", "c", "d", "f", "g", "h", "j", "k", "l", "m",
                        "n", "p", "q", "r", "s", "t", "v", "w", "x", "y", "z"]),
        ("Digraphs", ["sh", "ch", "th", "wh", "ck", "ng", "ph", "qu"]),
        ("Vowel teams", ["ai", "ay", "ee", "ea", "oa", "ow", "igh", "oo",
                         "ew", "ue", "oi", "oy", "ou", "au", "aw"]),
        ("R-controlled", ["ar", "or", "er", "ir", "ur"])
    ]

    @State private var current: String? = nil
    @State private var playingAll = false

    private var fast: Bool { AppEnv.uiTesting }
    private var allSpellings: [String] { groups.flatMap { $0.1 } }
    private let cols = [GridItem(.adaptive(minimum: 86), spacing: 14)]

    var body: some View {
        ZStack {
            Theme.background(Theme.bgTop, Theme.bgBottom)
            VStack(spacing: 14) {
                header
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        ForEach(groups, id: \.0) { title, spellings in
                            VStack(alignment: .leading, spacing: 10) {
                                Text(title)
                                    .font(.system(size: 22, weight: .black, design: .rounded))
                                    .foregroundStyle(.white)
                                LazyVGrid(columns: cols, spacing: 14) {
                                    ForEach(spellings, id: \.self) { sp in soundTile(sp) }
                                }
                            }
                        }
                        if SpeechManager.shared.usingBasicVoice {
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "lightbulb.fill").foregroundStyle(Theme.sun)
                                Text("For a clearer voice: iPad Settings → Accessibility → Spoken Content → Voices → English → download an “Enhanced” voice (e.g. Samantha). It’ll be used automatically.")
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.9))
                            }
                            .padding(14)
                            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(.white.opacity(0.12)))
                            .padding(.top, 8)
                        }
                    }
                    .padding(.horizontal, 22).padding(.bottom, 26)
                }
            }
        }
        .onDisappear { SpeechManager.shared.stop() }
    }

    private var header: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Sound Check")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(.white).shadow(radius: 3, y: 2)
                Text("Tap a sound to hear it")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
            }
            Spacer()
            Button { playingAll ? stopAll() : startAll() } label: {
                Label(playingAll ? "Stop" : "Play all",
                      systemImage: playingAll ? "stop.fill" : "play.fill")
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18).padding(.vertical, 10)
                    .background(Capsule().fill(playingAll ? Theme.ink.opacity(0.5) : Theme.coral))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("sound_play_all")
            Button { done() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 34)).foregroundStyle(.white.opacity(0.9))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("sound_close")
        }
        .padding(.horizontal, 24).padding(.top, 22)
    }

    private func soundTile(_ sp: String) -> some View {
        Button { play(sp) } label: {
            Text(sp)
                .font(.system(size: 40, weight: .black, design: .rounded))
                .foregroundStyle(Theme.ink)
                .frame(maxWidth: .infinity, minHeight: 78)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(current == sp ? Theme.sun : .white)
                        .shadow(color: .black.opacity(0.12), radius: 5, y: 3)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(current == sp ? Theme.coral : .clear, lineWidth: 4)
                )
                .scaleEffect(current == sp ? 1.06 : 1)
                .animation(.spring(response: 0.25, dampingFraction: 0.6), value: current)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("sound_\(sp)")
    }

    // MARK: - Playback

    private func play(_ sp: String) {
        stopAll()
        current = sp
        SpeechManager.shared.speakIPA(Phonics.chunkIPA[sp] ?? "")
        if !fast {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                if !playingAll && current == sp { current = nil }
            }
        }
    }

    private func startAll() {
        guard !fast else { return }
        playingAll = true
        step(0)
    }

    private func step(_ i: Int) {
        guard playingAll, i < allSpellings.count else { stopAll(); return }
        let sp = allSpellings[i]
        current = sp
        SpeechManager.shared.speakIPA(Phonics.chunkIPA[sp] ?? "")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.95) {
            if self.playingAll { self.step(i + 1) }
        }
    }

    private func stopAll() {
        playingAll = false
        SpeechManager.shared.stop()
    }
}

#Preview("SoundCheck") {
    SoundCheckView()
}
