import SwiftUI
import UIKit

/// Drives a single lesson's step-by-step state machine and all its side effects
/// (audio, haptics, scoring, progress). Extracted from `WorldLessonView` so the
/// view is pure rendering. Mutations happen on the main thread (user actions +
/// the main-queue `after()` timer), exactly as the old `@State` version did, so
/// no `@MainActor`/concurrency change in behaviour.
///
/// The `ProfileStore` isn't available at `@StateObject` init time, so the view
/// injects it via `start(store:)` from `onAppear` — before any step runs or any
/// store-touching method is reachable.
final class LessonViewModel: ObservableObject {
    let lesson: Lesson
    private var store: ProfileStore!

    enum Step: Equatable {
        case intro(Grapheme)
        case word(PWord)
        case sentence([String])
        case letter(Letter, LetterActivity)
    }
    enum Phase: Equatable {
        case intro, explore, blending, flex, prove, build, sentbuild, advancing, blastoff
        case letterMeet, letterTrace, letterFind, letterHear, letterFirstSound, letterMatch, letterDrag
    }

    @Published var steps: [Step]
    @Published var stepIdx = 0
    @Published var phase: Phase = .explore
    @Published var highlight: Int? = nil
    @Published var fuel = 0
    @Published var blastToken = 0
    @Published var mood: CritterMood = .idle
    @Published var orbX: CGFloat = 0
    @Published var lastSeg = -1
    @Published var placedG: [Int] = []   // grapheme indices placed (spell-the-word)
    @Published var trayG: [Int] = []     // shuffled grapheme order in the tray
    @Published var placedW: [Int] = []   // word indices placed (build-the-sentence)
    @Published var trayW: [Int] = []
    @Published var recorded = false
    // Mosaic-reward celebration inputs (set in recordProgress, read by the overlay).
    @Published var posterCompleted = false
    @Published var celebScene: PosterScene = .rocket
    @Published var celebTilesStart = 0
    // True only on this child's FIRST-ever blast-off → the celebration offers the
    // small grown-ups share button (never set in test mode).
    @Published var offerFirstShare = false
    // Sound→letter drag activity state.
    @Published var dragOffsets: [String: CGSize] = [:]
    @Published var barrelFrame: CGRect = .zero
    @Published var optShuffle = 0   // bumped on a wrong answer to reshuffle options (anti-guess)
    @Published var misses = 0       // total misses this lesson → reset if too many
    @Published var earnedStars = 3  // stars for this lesson, from accuracy
    @Published var stepMisses = 0   // misses on the CURRENT step → model-and-redo after 2
    @Published var showReset = false
    @Published var showModel = false // brief "here's the answer" model after repeated misses
    @Published var cheerPop = false // brief animal cheer animation on each correct answer
    @Published var flexContrast: FlexContrast? = nil  // "flex the sound" step for ambiguous vowel teams

    /// Anti-guessing: after this many wrong taps in a lesson, it restarts so the
    /// child can't brute-force their way through by tapping randomly.
    private let missLimit = 5
    var fast: Bool { AppEnv.uiTesting }

    init(lesson: Lesson) {
        self.lesson = lesson
        var s: [Step] = []
        // Pre-reader letter/sound lessons: one activity-step per letter × activity.
        if lesson.isLetterLesson {
            for L in lesson.letters {
                for a in lesson.letterActivities { s.append(.letter(L, a)) }
            }
        } else {
            if let g = lesson.introGrapheme { s.append(.intro(g)) }
            for w in lesson.words { s.append(.word(w)) }
            for sent in lesson.sentences { s.append(.sentence(sent)) }
        }
        self.steps = s
    }

    var fuelTotal: Int {
        max(1, steps.filter {
            // "meet" and "intro" are teach steps (no challenge) → not fuel.
            switch $0 {
            case .intro: return false
            case .letter(_, .meet): return false
            default: return true
            }
        }.count)
    }
    var currentStep: Step { stepIdx < steps.count ? steps[stepIdx] : .word(PWord(text: "", graphemes: [])) }

    /// Called once from the view's `onAppear` (store now available): seeds spaced/
    /// cumulative warm-up words, then enters the first step.
    func start(store: ProfileStore) {
        self.store = store
        // Spaced + cumulative retrieval (word lessons only). Lead with up to 2 words
        // the child MISSED, plus 1 already-MASTERED word interleaved back in.
        if !fast && !lesson.isLetterLesson {
            let missed = store.reviewWords(limit: 2)
            let mastered = store.masteredSample(limit: 1, excluding: Set(missed))
            let warmups = (missed + mastered)
                .compactMap { Curriculum.word(text: $0) }
                .map { Step.word($0) }
            if !warmups.isEmpty { steps = warmups + steps }
        }
        enterStep(initial: true)
    }

    // MARK: - Option builders (deterministic; reshuffle by optShuffle on wrong answers)

    /// 3 animals: the target letter (correct) + 2 distractors with a different sound.
    func dragChoices(_ L: Letter) -> [(letter: Letter, correct: Bool)] {
        let pool = Languages.active.letters.filter { $0.ipa != L.ipa }
        var picked: [Letter] = []; var seenIPA = Set<String>([L.ipa])
        let rot = stepIdx + optShuffle
        if !pool.isEmpty {
            for i in 0..<(pool.count) where picked.count < 2 {
                let c = pool[(rot + i) % pool.count]
                if seenIPA.insert(c.ipa).inserted { picked.append(c) }
            }
        }
        let all = [(letter: L, correct: true)] + picked.map { (letter: $0, correct: false) }
        return rotated(all)
    }

    func rotated<T>(_ arr: [T]) -> [T] {
        guard !arr.isEmpty else { return arr }
        let r = (stepIdx + optShuffle) % arr.count
        return Array(arr[r...] + arr[..<r])
    }

    /// Target letter + `count` distractors, spread across the whole alphabet
    /// (cumulative discrimination among MANY letters), varied per step.
    func letterOptions(_ L: Letter, count: Int = 3) -> [(text: String, correct: Bool)] {
        let pool = Languages.active.allLetters.filter { $0 != L.letter }
        var seen = Set<String>(); var distract: [String] = []
        let rot = stepIdx + optShuffle
        if !pool.isEmpty {
            for i in 0..<(count * 3) where distract.count < count {
                let c = pool[(rot + i) % pool.count]
                if seen.insert(c).inserted { distract.append(c) }
            }
        }
        let opts = [(text: L.letter, correct: true)] + distract.map { (text: $0, correct: false) }
        return rotated(opts)
    }

    func firstSoundOptions(_ L: Letter) -> [(text: String, correct: Bool)] {
        var distract: [String] = []
        for d in Languages.active.letters where d.ipa != L.ipa && d.picture != L.picture && distract.count < 3 {
            distract.append(d.picture)
        }
        let opts = [(text: L.picture, correct: true)] + distract.map { (text: $0, correct: false) }
        return rotated(opts)
    }

    /// Always cue with the letter's SOUND — never its alphabet name.
    func cue(_ L: Letter) {
        SpeechManager.shared.speakIPA(L.ipa)
    }

    func letterPick(_ L: Letter, _ correct: Bool) {
        if correct {
            Haptics.success(); mood = .cheer
            completeStep()
        } else {
            registerMiss()
            if !fast { SpeechManager.shared.speakIPA(L.ipa) }
        }
    }

    func animalDrop(_ animalLetter: Letter, correct: Bool, target L: Letter, at point: CGPoint) {
        if barrelFrame.contains(point) {
            if correct {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { dragOffsets[animalLetter.letter] = .zero }
                letterPick(L, true); return
            }
            registerMiss(); if !fast { SpeechManager.shared.speakIPA(L.ipa) }
        }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) { dragOffsets[animalLetter.letter] = .zero }
    }

    // MARK: - Per-answer animal cheer

    /// Trigger the cheer animation (called on every correct answer).
    func popCheer() {
        guard !fast else { return }
        cheerPop = false
        withAnimation(.spring(response: 0.35, dampingFraction: 0.55)) { cheerPop = true }
        after(0.9) { withAnimation(.easeOut(duration: 0.25)) { self.cheerPop = false } }
    }

    /// What to reveal in the model overlay for the current step.
    var modelHint: (big: String, sub: String)? {
        switch currentStep {
        case .letter(let L, let act):
            return act == .firstSound ? (L.picture, "\(L.letter.uppercased()) — \(L.keyword)")
                                      : (L.letter, "this one")
        case .word(let w):
            // Reading proof reveals picture + word together (the word also tells a
            // parent what the picture means); the spelling unit shows the word.
            return phase == .prove ? (w.picture ?? w.text, w.text) : (w.text, "spell it")
        case .sentence(let s):
            let next = placedW.count < s.count ? s[placedW.count] : (s.first ?? "")
            return (next, "this word is next")
        default: return nil
        }
    }

    // MARK: - State machine

    /// Pending-work token: bumping it cancels every closure scheduled via after().
    private var epoch = 0

    /// Cancel all pending scheduled work — called when the lesson is dismissed or
    /// restarted, so stale speech/animation closures can't fire into a new screen.
    func invalidate() { epoch += 1 }

    func after(_ delay: Double, _ work: @escaping () -> Void) {
        let e = epoch
        DispatchQueue.main.asyncAfter(deadline: .now() + (fast ? 0 : delay)) { [weak self] in
            guard let self, self.epoch == e else { return }
            work()
        }
    }

    func anim(_ body: () -> Void) {
        if fast { body() } else { withAnimation(.spring(response: 0.4, dampingFraction: 0.85), body) }
    }

    func enterStep(initial: Bool = false) {
        highlight = nil; lastSeg = -1; placedG = []; stepMisses = 0; flexContrast = nil
        anim { orbX = 0 }
        mood = .idle
        switch currentStep {
        case .intro(let g):
            phase = .intro
            if !fast, let ipa = g.ipa { after(0.4) { SpeechManager.shared.speakIPA(ipa) } }
        case .word:
            phase = .explore
        case .sentence(let s):
            placedW = []; trayW = Array(s.indices).shuffled()
            phase = .sentbuild
        case .letter(let L, let act):
            switch act {
            case .meet:       phase = .letterMeet;  if !fast { after(0.4) { SpeechManager.shared.speakIPA(L.ipa) } }
            case .trace:
                phase = .letterTrace
                if !fast {
                    after(0.4) { SpeechManager.shared.speakIPA(L.ipa) }
                    if let m = Languages.active.mnemonic(L.letter) { after(1.2) { SpeechManager.shared.speak(m) } }
                }
            case .find:       phase = .letterFind;  if !fast { after(0.4) { self.cue(L) } }
            case .hearTap:    phase = .letterHear;  if !fast { after(0.4) { SpeechManager.shared.speakIPA(L.ipa) } }
            case .firstSound: phase = .letterFirstSound; if !fast { after(0.4) { SpeechManager.shared.speakIPA(L.ipa) } }
            case .matchCase:  phase = .letterMatch; if !fast { after(0.4) { SpeechManager.shared.speakIPA(L.ipa) } }
            case .soundToLetter:
                phase = .letterDrag; dragOffsets = [:]
                if !fast { after(0.4) { SpeechManager.shared.speakIPA(L.ipa) } }
            }
        }
    }

    /// Anti-guessing: a wrong tap reshuffles the options and counts toward a per-
    /// lesson limit; too many → restart lesson.
    func registerMiss() {
        mood = .oops; Haptics.tap(); SoundFX.shared.retry()
        optShuffle += 1
        misses += 1
        stepMisses += 1
        if misses >= missLimit { restartLesson(); return }
        // Model-and-redo: after 2 misses on the SAME step, briefly SHOW + say the
        // correct answer (a scaffold), then let the child redo it.
        if stepMisses == 2 { modelAnswer() }
    }

    /// Briefly reveal + speak the correct answer for the current step, then hide.
    func modelAnswer() {
        guard !fast else { return }
        switch currentStep {
        case .letter(let L, _): SpeechManager.shared.speakIPA(L.ipa)
        case .word(let w): SpeechManager.shared.playBlend(w, onHighlight: { _ in }, onDone: {})
        default: break
        }
        withAnimation(.easeOut(duration: 0.2)) { showModel = true }
        after(1.6) { withAnimation(.easeOut(duration: 0.2)) { self.showModel = false } }
    }

    func restartLesson() {
        invalidate()   // kill the failed run's pending closures before the reset window
        withAnimation(.easeOut(duration: 0.25)) { showReset = true }
        if !fast { SpeechManager.shared.speak(Languages.active.t("try_again_spoken")) }
        after(1.6) {
            self.misses = 0; self.optShuffle = 0; self.fuel = 0; self.stepIdx = 0; self.stepMisses = 0
            self.placedG = []; self.placedW = []
            withAnimation(.easeOut(duration: 0.25)) { self.showReset = false }
            self.enterStep(initial: true)
        }
    }

    func tapTile(_ w: PWord, _ i: Int) {
        guard phase == .explore, i < w.graphemes.count else { return }
        Haptics.tap(); mood = .happy; highlight = i
        if let ipa = w.graphemes[i].ipa { SpeechManager.shared.speakIPA(ipa) }
        after(0.45) { if self.phase == .explore && self.highlight == i { self.highlight = nil } }
    }

    func startBlend(_ w: PWord) {
        guard phase == .explore else { return }
        Haptics.tap()
        phase = .blending
        lastSeg = -1
        SpeechManager.shared.playBlend(w, onHighlight: { _ in }, onDone: { })
        let sounded = w.soundingIndices
        for (k, gi) in sounded.enumerated() {
            after(Double(k) * 0.42) { if self.phase == .blending { self.highlight = gi } }
        }
        after(Double(sounded.count) * 0.42 + 0.45) { self.finishBlend(w) }
    }

    func finishBlend(_ w: PWord) {
        guard phase == .blending else { return }
        highlight = nil
        // Set-for-variability: if the word has an ambiguous vowel team (oo/ow),
        // first ask which sound it makes in THIS word, then go to spelling.
        if let fc = Flex.contrast(for: w) {
            flexContrast = fc
            anim { phase = .flex }
            if !fast { after(0.4) { SpeechManager.shared.speak(w.text) } }
            return
        }
        proveOrSpell(w)
    }

    /// After blending: the normal proof is READING (pick the picture for the word
    /// you just read). Spelling — much harder encoding — only happens in the
    /// dedicated end-of-curriculum spelling unit (`lesson.spell`).
    func proveOrSpell(_ w: PWord) {
        if lesson.spell { goToSpell(w); return }
        if proveChoices(w).count >= 2 {
            anim { phase = .prove }     // no audio: hearing the word would give it away
        } else {
            completeStep()              // no picture to prove against — blending was the work
        }
    }

    /// Picture options for the reading proof: the word's own picture + 2
    /// same-lesson distractors (fallback: pack keyword pictures). Deterministic,
    /// reshuffled by optShuffle on a wrong answer (anti-guess).
    func proveChoices(_ w: PWord) -> [(pic: String, correct: Bool)] {
        guard let pic = w.picture else { return [] }
        var pool = lesson.words.compactMap { $0.picture }.filter { $0 != pic }
        if pool.count < 2 {
            pool += Languages.active.letters.map(\.picture).filter { $0 != pic && !pool.contains($0) }
        }
        var seen = Set<String>([pic]); var picks: [String] = []
        let rot = stepIdx + optShuffle
        if !pool.isEmpty {
            for i in 0..<pool.count where picks.count < 2 {
                let c = pool[(rot + i) % pool.count]
                if seen.insert(c).inserted { picks.append(c) }
            }
        }
        guard !picks.isEmpty else { return [] }
        return rotated([(pic: pic, correct: true)] + picks.map { (pic: $0, correct: false) })
    }

    func provePick(_ w: PWord, _ correct: Bool) {
        guard phase == .prove else { return }
        if correct {
            Haptics.success(); mood = .cheer
            completeStep()                       // records the word as read correctly
        } else {
            store.recordWordResult(w.text, correct: false)
            registerMiss()
        }
    }

    /// ENCODING: word hidden, child spells it from sound + meaning — recall, not
    /// copying. Dictate the word as the prompt.
    func goToSpell(_ w: PWord) {
        placedG = []; trayG = Array(w.graphemes.indices).shuffled()
        anim { phase = .build }
        if !fast { after(0.45) { SpeechManager.shared.speak(w.text) } }
    }

    /// The child picked which sound the ambiguous team makes in this word.
    func flexPick(_ choseA: Bool) {
        guard phase == .flex, let fc = flexContrast, case .word(let w) = currentStep else { return }
        if choseA == fc.correctIsA {
            Haptics.success(); mood = .cheer
            proveOrSpell(w)
        } else {
            store.recordWordResult(w.text, correct: false)
            registerMiss()
        }
    }

    /// Spell-it: tap a tray letter. Correct → place it; wrong → fail (no advance).
    func buildTap(_ w: PWord, _ gi: Int, correct: Bool) {
        guard phase == .build, !placedG.contains(gi) else { return }
        if correct {
            Haptics.tap()
            placedG.append(gi)
            if placedG.count >= w.graphemes.count { Haptics.success(); mood = .cheer; completeStep() }
        } else {
            store.recordWordResult(w.text, correct: false)
            registerMiss()
        }
    }

    /// Build-the-sentence: tap a tray word in order. Correct → place; wrong → fail.
    func sentTap(_ words: [String], _ wi: Int, correct: Bool) {
        guard phase == .sentbuild, !placedW.contains(wi) else { return }
        if correct {
            Haptics.tap()
            placedW.append(wi)
            if placedW.count >= words.count { Haptics.success(); mood = .cheer; completeStep() }
        } else {
            registerMiss()
        }
    }

    func completeStep() {
        guard phase != .advancing, phase != .blastoff else { return }
        phase = .advancing
        mood = .cheer
        SoundFX.shared.correct()
        popCheer()
        if case .word(let w) = currentStep { store.recordWordResult(w.text, correct: true) }
        anim { fuel = min(fuelTotal, fuel + 1) }
        after(0.9) { self.nextStep() }
    }

    func nextStep() {
        if stepIdx + 1 >= steps.count { blastOff(); return }
        stepIdx += 1
        enterStep()
    }

    func blastOff() {
        blastToken += 1
        mood = .cheer
        SoundFX.shared.blastoff()
        recordProgress()
        if !fast { SpeechManager.shared.speak(Languages.active.t("blast_off_spoken")) }
        anim { phase = .blastoff }
    }

    func recordProgress() {
        guard !recorded else { return }
        recorded = true
        // One-time word-of-mouth moment: this child's FIRST-ever blast-off across
        // ALL language worlds, decided BEFORE the win is recorded. Marked offered
        // immediately so it can stay up for this whole celebration but never
        // returns on a later one.
        if !fast, let pid = store.currentID,
           !store.hasAnyProgress(for: pid),
           !store.firstShareOffered(for: pid) {
            offerFirstShare = true
            store.markFirstShareOffered(for: pid)
        }
        // Stars now reflect accuracy (a real signal), not a flat 3.
        earnedStars = misses == 0 ? 3 : (misses <= 2 ? 2 : 1)
        store.record(lesson.id, stars: earnedStars)
        // Mosaic reward: this win peels one tile of the current poster board.
        celebTilesStart = store.tilesRevealed()
        let beforeIdx = store.currentPosterIndex()
        let scenes = PosterScene.all
        celebScene = scenes.isEmpty ? .rocket : scenes[beforeIdx % scenes.count]
        posterCompleted = store.recordWin()
    }
}
