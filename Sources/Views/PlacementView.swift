import SwiftUI

/// First entry into a language world: a grown-up picks where to start — or a
/// short check (4 letter questions, then 4 word questions, ≤2 minutes) places
/// the child. Both stages reuse the app's own activity formats, so the check
/// feels like playing, not testing. Misses never scold; placement only decides
/// where the map opens up.
struct PlacementView: View {
    @EnvironmentObject var store: ProfileStore
    /// Called after placement is recorded — the map takes over.
    var done: () -> Void = {}

    private enum Stage {
        case ask
        case letters(q: Int, right: Int, thenWords: Bool)
        case words(q: Int, right: Int, fellBackFromWords: Bool)
    }
    @State private var stage: Stage = .ask
    @State private var letterQs: [Letter] = []
    @State private var wordQs: [PWord] = []

    var body: some View {
        ZStack {
            Theme.background(Theme.bgTop, Theme.bgBottom)
            VStack(spacing: 26) {
                switch stage {
                case .ask: askCard
                case .letters(let q, let right, let thenWords): letterCard(q, right, thenWords)
                case .words(let q, let right, let fellBack): wordCard(q, right, fellBack)
                }
            }
            .padding(30)
        }
        .onAppear {
            letterQs = Placement.letterQuestions(Languages.active)
            wordQs = Placement.wordQuestions(units: Curriculum.units)
        }
    }

    // MARK: - Grown-up choice

    private var askCard: some View {
        VStack(spacing: 18) {
            Text("🚀").font(.system(size: 72))
            Text(Languages.active.t("placement_title"))
                .font(.system(size: 32, weight: .black, design: .rounded))
                .foregroundStyle(.white).multilineTextAlignment(.center)
            choice("placement_new", icon: "🌱", id: "place_new") { finish(.newReader) }
            choice("placement_letters", icon: "🔤", id: "place_letters") {
                stage = .letters(q: 0, right: 0, thenWords: true)
            }
            choice("placement_words", icon: "📖", id: "place_words") {
                if wordQs.count >= 3 { stage = .words(q: 0, right: 0, fellBackFromWords: true) }
                else { finish(.readsWords) }
            }
        }
    }

    private func choice(_ key: String, icon: String, id: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Text(icon).font(.system(size: 34))
                Text(Languages.active.t(key))
                    .font(.system(size: 21, weight: .heavy, design: .rounded))
                    .foregroundStyle(Theme.ink)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 22).padding(.vertical, 16)
            .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(.white)
                .shadow(color: .black.opacity(0.15), radius: 8, y: 4))
        }
        .buttonStyle(.plain)
        .frame(maxWidth: 560)
        .accessibilityIdentifier(id)
    }

    // MARK: - Stage A: letters (hear the sound → tap the letter)

    private func letterCard(_ q: Int, _ right: Int, _ thenWords: Bool) -> some View {
        let L = letterQs[min(q, letterQs.count - 1)]
        return VStack(spacing: 22) {
            progressDots(q, of: letterQs.count)
            Text(Languages.active.t("tap_what_you_hear"))
                .font(.system(size: 26, weight: .heavy, design: .rounded)).foregroundStyle(.white)
            Button { SpeechManager.shared.speakIPA(L.ipa) } label: {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.system(size: 30, weight: .bold)).foregroundStyle(.white)
                    .padding(16).background(Circle().fill(Theme.bgBottom))
            }
            .buttonStyle(.plain).accessibilityIdentifier("slice_hear")
            HStack(spacing: 16) {
                ForEach(letterOptions(L), id: \.text) { opt in
                    Button { answerLetter(opt.correct, q: q, right: right, thenWords: thenWords) } label: {
                        Text(opt.text)
                            .font(.system(size: 56, weight: .black, design: .rounded)).foregroundStyle(Theme.ink)
                            .frame(width: 92, height: 100)
                            .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(.white)
                                .shadow(color: .black.opacity(0.16), radius: 7, y: 4))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier(opt.correct ? "slice_pick_correct" : "slice_pick_wrong")
                }
            }
        }
        .onAppear { if !AppEnv.uiTesting { SpeechManager.shared.speakIPA(L.ipa) } }
    }

    private func letterOptions(_ L: Letter) -> [(text: String, correct: Bool)] {
        var opts: [(String, Bool)] = [(L.letter, true)]
        for d in Languages.active.letters where d.ipa != L.ipa && opts.count < 4 {
            opts.append((d.letter, false))
        }
        // Deterministic spread so the right answer isn't always first.
        let r = L.letter.count + (L.ipa.unicodeScalars.first.map { Int($0.value) } ?? 0)
        let k = r % opts.count
        return Array(opts[k...] + opts[..<k]).map { (text: $0.0, correct: $0.1) }
    }

    private func answerLetter(_ correct: Bool, q: Int, right: Int, thenWords: Bool) {
        if correct { Haptics.success(); SoundFX.shared.correct() } else { Haptics.tap() }
        let newRight = right + (correct ? 1 : 0)
        if q + 1 < letterQs.count {
            stage = .letters(q: q + 1, right: newRight, thenWords: thenWords)
        } else if newRight >= 3 {
            // Letters known: confirm words too (unless there's nothing to test).
            if thenWords && wordQs.count >= 3 { stage = .words(q: 0, right: 0, fellBackFromWords: false) }
            else { finish(.knowsLetters) }
        } else {
            finish(.newReader)
        }
    }

    // MARK: - Stage B: words (read the word → tap its picture)

    private func wordCard(_ q: Int, _ right: Int, _ fellBack: Bool) -> some View {
        let w = wordQs[min(q, wordQs.count - 1)]
        return VStack(spacing: 22) {
            progressDots(q, of: wordQs.count)
            Text(w.text)
                .font(.system(size: 54, weight: .black, design: .rounded)).foregroundStyle(Theme.ink)
                .padding(.horizontal, 28).padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(.white)
                    .shadow(color: .black.opacity(0.15), radius: 7, y: 4))
            Text(Languages.active.t("which_read"))
                .font(.system(size: 24, weight: .heavy, design: .rounded)).foregroundStyle(.white)
            HStack(spacing: 16) {
                ForEach(wordPictureOptions(w), id: \.pic) { opt in
                    Button { answerWord(opt.correct, q: q, right: right, fellBack: fellBack) } label: {
                        Text(opt.pic).font(.system(size: 60))
                            .frame(width: 104, height: 104)
                            .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(.white)
                                .shadow(color: .black.opacity(0.18), radius: 8, y: 5))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier(opt.correct ? "slice_pick_correct" : "slice_pick_wrong")
                }
            }
        }
    }

    private func wordPictureOptions(_ w: PWord) -> [(pic: String, correct: Bool)] {
        guard let pic = w.picture else { return [] }
        var opts: [(String, Bool)] = [(pic, true)]
        for other in wordQs where other.text != w.text && opts.count < 3 {
            if let p = other.picture, p != pic { opts.append((p, false)) }
        }
        for L in Languages.active.letters where opts.count < 3 {
            if L.picture != pic && !opts.contains(where: { $0.0 == L.picture }) {
                opts.append((L.picture, false))
            }
        }
        let k = w.text.count % max(1, opts.count)
        return Array(opts[k...] + opts[..<k]).map { (pic: $0.0, correct: $0.1) }
    }

    private func answerWord(_ correct: Bool, q: Int, right: Int, fellBack: Bool) {
        if correct { Haptics.success(); SoundFX.shared.correct() } else { Haptics.tap() }
        let newRight = right + (correct ? 1 : 0)
        if q + 1 < wordQs.count {
            stage = .words(q: q + 1, right: newRight, fellBackFromWords: fellBack)
        } else if newRight >= 3 {
            finish(.readsWords)
        } else if fellBack {
            // Came straight to words and struggled → check letters before
            // deciding between knowsLetters and newReader.
            stage = .letters(q: 0, right: 0, thenWords: false)
        } else {
            finish(.knowsLetters)
        }
    }

    // MARK: - Finish

    private func progressDots(_ q: Int, of n: Int) -> some View {
        HStack(spacing: 8) {
            ForEach(0 ..< n, id: \.self) { i in
                Circle().fill(.white.opacity(i <= q ? 0.95 : 0.3)).frame(width: 10, height: 10)
            }
        }
    }

    private func finish(_ level: Placement.Level) {
        store.placeThrough(Placement.lessonsToSkip(level: level, units: Curriculum.units))
        if let pid = store.currentID { store.markPlacementDone(for: pid) }
        if !AppEnv.uiTesting { SpeechManager.shared.speak(Languages.active.t("lets_go")) }
        done()
    }
}
