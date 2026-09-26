import SwiftUI
import UIKit

/// The whole-app 3D lesson player (Mentava-style). Drives ANY curriculum Lesson
/// through one continuous 3D world. Every step is a fail-able challenge — the app
/// never just reads a word aloud and lets the child pass:
///   • optionally teach the new sound,
///   • for each word: tap tiles to hear each sound, slide the comet to SOUND OUT
///     the parts (never the whole word), then prove it — pick the matching picture
///     (4 options) for pictured words, or SPELL it from a shuffled tray,
///   • for each sentence: read it, then BUILD it from scrambled word tiles.
/// Fuel fills with every win; a full tank blasts the rocket off to the next world.
///
/// This view is pure rendering: the step state machine + all side effects live in
/// `LessonViewModel`, injected the ProfileStore via `start(store:)` in onAppear.
struct WorldLessonView: View {
    let lesson: Lesson
    var done: () -> Void = {}
    @EnvironmentObject var store: ProfileStore
    @StateObject private var vm: LessonViewModel

    @State private var started = false
    @State private var showCoach = false
    private let coachKey = "readrocket.seenCoach"

    init(lesson: Lesson, done: @escaping () -> Void = {}) {
        self.lesson = lesson
        self.done = done
        _vm = StateObject(wrappedValue: LessonViewModel(lesson: lesson))
    }

    private var fast: Bool { AppEnv.uiTesting }
    private var mascotKind: CritterKind { critterKind(forProfile: store.currentID ?? "fox") }

    var body: some View {
        ZStack {
            backdrop
            VStack(spacing: 18) {
                fuelGauge
                Spacer(minLength: 0)
                content
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 22)

            if !fast {
                MascotView(kind: mascotKind, mood: vm.mood, size: 124)
                    .accessibilityHidden(true)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                    .padding(.leading, 22).padding(.bottom, 16)
                    .allowsHitTesting(false)
            }

            if vm.cheerPop && !fast { cheerOverlay }
            if vm.phase == .blastoff { celebrationOverlay }
            if vm.showModel { modelOverlay }
            if vm.showReset { resetOverlay }
            if showCoach { coachOverlay }
        }
        .onAppear {
            if !started {
                started = true
                vm.start(store: store)
                if !fast && !lesson.isLetterLesson && !UserDefaults.standard.bool(forKey: coachKey) { showCoach = true }
            }
        }
        .onDisappear {
            // Cancel the VM's pending scheduled work and any in-flight speech so a
            // dismissed lesson can't keep talking/animating into the map.
            vm.invalidate()
            SpeechManager.shared.stop()
        }
    }

    // MARK: - Backdrop

    @ViewBuilder private var backdrop: some View {
        ZStack {
            Theme.spaceGradient().ignoresSafeArea()
            if !fast { SliceSceneView(blastToken: vm.blastToken, theme: worldTheme).ignoresSafeArea() }
        }
    }

    private var worldTheme: SliceSceneView.Theme {
        guard let u = Curriculum.unit(forLesson: lesson.id) else { return .default }
        return .init(planet: UIColor(Color(hex: u.colorA)), accent: UIColor(Color(hex: u.colorB)))
    }

    private var rewardScene: RewardScene {
        if let u = Curriculum.unit(forLesson: lesson.id), u.lessons.last?.id == lesson.id { return .treasure }
        let idx = Curriculum.lessonOrder.firstIndex(of: lesson.id) ?? 0
        let pool: [RewardScene] = [.star, .gem, .fireworks, .balloons]
        return pool[idx % pool.count]
    }

    // MARK: - Fuel gauge

    private var fuelGauge: some View {
        HStack(spacing: 8) {
            Image(systemName: "fuelpump.fill")
                .font(.system(size: 20, weight: .bold)).foregroundStyle(.white.opacity(0.85))
            HStack(spacing: 5) {
                ForEach(0..<vm.fuelTotal, id: \.self) { i in
                    Capsule()
                        .fill(i < vm.fuel ? Theme.sun : Color.white.opacity(0.22))
                        .frame(width: max(10, min(34, 300 / CGFloat(vm.fuelTotal))), height: 15)
                        .overlay(Capsule().stroke(.white.opacity(0.5), lineWidth: 1.5))
                }
            }
            Text("🚀").font(.system(size: 28)).scaleEffect(vm.fuel == vm.fuelTotal ? 1.25 : 1)
                .animation(fast ? nil : .spring(response: 0.3, dampingFraction: 0.5), value: vm.fuel)
        }
        .padding(.horizontal, 16).padding(.vertical, 9)
        .background(Capsule().fill(.white.opacity(0.12)))
        .accessibilityIdentifier("slice_fuel")
    }

    // MARK: - Content router

    @ViewBuilder private var content: some View {
        switch vm.currentStep {
        case .intro(let g): introCard(g)
        case .word(let w): wordCard(w)
        case .sentence(let s): sentenceCard(s)
        case .letter(let L, let act): letterCard(L, act)
        }
    }

    private func card<V: View>(@ViewBuilder _ inner: () -> V) -> some View {
        VStack(spacing: 22) { inner() }
            .padding(26)
            .background(
                RoundedRectangle(cornerRadius: 34, style: .continuous)
                    .fill(.white.opacity(0.10))
                    .overlay(RoundedRectangle(cornerRadius: 34, style: .continuous)
                        .stroke(.white.opacity(0.22), lineWidth: 2))
            )
    }

    // MARK: - Intro (teach a new sound)

    private func introCard(_ g: Grapheme) -> some View {
        card {
            Text(Languages.active.t("new_sound"))
                .font(.system(size: 24, weight: .bold, design: .rounded)).foregroundStyle(.white.opacity(0.85))
            Button { if let ipa = g.ipa { SpeechManager.shared.speakIPA(ipa) } } label: {
                Text(g.letters)
                    .font(.system(size: 130, weight: .black, design: .rounded))
                    .foregroundStyle(Theme.ink)
                    .frame(minWidth: 180)
                    .padding(.horizontal, 24).padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(.white)
                        .shadow(color: .black.opacity(0.15), radius: 8, y: 5))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("slice_hear")
            Text(Languages.active.t("tap_to_hear"))
                .font(.system(size: 18, weight: .semibold, design: .rounded)).foregroundStyle(.white.opacity(0.8))
            bigButton(Languages.active.t("got_it"), id: "Got it!") { vm.nextStep() }
        }
    }

    // MARK: - Letter on-ramp activities

    @ViewBuilder private func letterCard(_ L: Letter, _ act: LetterActivity) -> some View {
        switch act {
        case .meet:       letterMeetCard(L)
        case .trace:      letterTraceCard(L)
        case .find:       letterChoiceCard(L, bySound: false)
        case .hearTap:    letterChoiceCard(L, bySound: true)
        case .firstSound: firstSoundCard(L)
        case .matchCase:  letterMatchCaseCard(L)
        case .soundToLetter: soundDragCard(L)
        }
    }

    /// The word a keyword-picture stands for in the active language (parent aid).
    private func keyword(forPic pic: String) -> String? {
        Languages.active.letters.first { $0.picture == pic }?.keyword
    }

    /// Matching game: show the BIG (uppercase) letter; tap the matching little
    /// (lowercase) one among distractors. Cue is the SOUND (never the letter name).
    private func letterMatchCaseCard(_ L: Letter) -> some View {
        card {
            Text(Languages.active.t("match_big_little"))
                .font(.system(size: 24, weight: .heavy, design: .rounded)).foregroundStyle(.white)
            Button { vm.cue(L) } label: {
                Text(L.letter.uppercased())
                    .font(.system(size: 96, weight: .black, design: .rounded)).foregroundStyle(Theme.ink)
                    .frame(width: 140, height: 140)
                    .background(RoundedRectangle(cornerRadius: 26, style: .continuous).fill(.white)
                        .shadow(color: .black.opacity(0.15), radius: 7, y: 4))
                    .overlay(Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 16, weight: .bold)).foregroundStyle(Theme.ink.opacity(0.55))
                        .padding(9), alignment: .bottomTrailing)
            }
            .buttonStyle(.plain).accessibilityIdentifier("slice_hear")
            Text("Find the little one")
                .font(.system(size: 18, weight: .semibold, design: .rounded)).foregroundStyle(.white.opacity(0.85))
            HStack(spacing: 16) {
                ForEach(vm.letterOptions(L), id: \.text) { opt in
                    Button { vm.letterPick(L, opt.correct) } label: {
                        Text(opt.text)   // lowercase options
                            .font(.system(size: 60, weight: .black, design: .rounded)).foregroundStyle(Theme.ink)
                            .frame(width: 92, height: 104)
                            .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(.white)
                                .shadow(color: .black.opacity(0.16), radius: 7, y: 4))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier(opt.correct ? "slice_pick_correct" : "slice_pick_wrong")
                }
            }
        }
    }

    /// Trace the letter with a finger — forms the shape, which disambiguates the
    /// reversible letters b/d/p/q. Completing the trace counts as a win.
    private func letterTraceCard(_ L: Letter) -> some View {
        let reps = Languages.active.traceReps(L.letter)
        let mnem = Languages.active.mnemonic(L.letter)
        return card {
            Text(reps > 1 ? "Trace the \(L.letter.uppercased()) — \(reps) times!"
                          : "Trace the \(L.letter.uppercased())!")
                .font(.system(size: 22, weight: .heavy, design: .rounded)).foregroundStyle(.white)
            TracingView(letter: L.letter, reps: reps, onRep: {
                guard !fast else { return }
                if let m = mnem { SpeechManager.shared.speak(m) }
                else { SpeechManager.shared.speakIPA(L.ipa) }
            }) {
                if !fast { SpeechManager.shared.speakIPA(L.ipa) }
                vm.completeStep()
            }
            .frame(width: 300, height: 320)
            .background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(.white)
                .shadow(color: .black.opacity(0.15), radius: 8, y: 5))
            if let m = mnem {
                Text("👶 \(m)")
                    .font(.system(size: 19, weight: .heavy, design: .rounded)).foregroundStyle(Theme.sun)
            }
            Text("Use your finger to draw it")
                .font(.system(size: 16, weight: .semibold, design: .rounded)).foregroundStyle(.white.opacity(0.85))
        }
    }

    /// Meet the letter — SOUND-FIRST: big letter (tap to hear /s/) + the mouth cue.
    private func letterMeetCard(_ L: Letter) -> some View {
        card {
            Text(Languages.active.t("new_sound"))
                .font(.system(size: 22, weight: .bold, design: .rounded)).foregroundStyle(.white.opacity(0.85))
            Button { SpeechManager.shared.speakIPA(L.ipa) } label: {
                Text(L.letter)
                    .font(.system(size: 130, weight: .black, design: .rounded)).foregroundStyle(Theme.ink)
                    .frame(width: 190, height: 190)
                    .background(RoundedRectangle(cornerRadius: 30, style: .continuous).fill(.white)
                        .shadow(color: .black.opacity(0.15), radius: 8, y: 5))
                    .overlay(Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 20, weight: .bold)).foregroundStyle(Theme.ink.opacity(0.5))
                        .padding(12), alignment: .bottomTrailing)
            }
            .buttonStyle(.plain).accessibilityIdentifier("slice_hear")
            Text(Languages.active.t("tap_to_hear"))
                .font(.system(size: 18, weight: .semibold, design: .rounded)).foregroundStyle(.white.opacity(0.8))
            SayWithMeMouth(ipa: L.ipa, size: 150)
            if let mnem = MnemonicArt.image(for: L.letter) {
                mnem.scaledToFit().frame(width: 78, height: 78).opacity(0.9)
            }
            bigButton(Languages.active.t("got_it"), id: "Got it!") { SpeechManager.shared.speakIPA(L.ipa); vm.nextStep() }
        }
    }

    /// Find/Hear: tap the target LETTER among distractors. Both cue with the SOUND.
    private func letterChoiceCard(_ L: Letter, bySound: Bool) -> some View {
        card {
            Text(bySound ? Languages.active.t("tap_what_you_hear") : Languages.active.t("find_the_letter"))
                .font(.system(size: 26, weight: .heavy, design: .rounded)).foregroundStyle(.white)
            // ALWAYS cue by ear only — showing the target letter would let the
            // child match letter-to-letter visually without processing the sound.
            // (`bySound` now only picks the title copy.)
            Button { vm.cue(L) } label: {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.system(size: 30, weight: .bold)).foregroundStyle(.white)
                    .padding(14).background(Circle().fill(Theme.bgBottom))
            }
            .buttonStyle(.plain).accessibilityIdentifier("slice_hear")
            HStack(spacing: 16) {
                ForEach(vm.letterOptions(L), id: \.text) { opt in
                    Button { vm.letterPick(L, opt.correct) } label: {
                        Text(opt.text)
                            .font(.system(size: 64, weight: .black, design: .rounded)).foregroundStyle(Theme.ink)
                            .frame(width: 96, height: 110)
                            .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(.white)
                                .shadow(color: .black.opacity(0.16), radius: 7, y: 4))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier(opt.correct ? "slice_pick_correct" : "slice_pick_wrong")
                }
            }
        }
    }

    /// First sound: hear the sound, tap the PICTURE that starts with it. 4 options.
    private func firstSoundCard(_ L: Letter) -> some View {
        card {
            Text(Languages.active.t("which_starts"))
                .font(.system(size: 24, weight: .heavy, design: .rounded)).foregroundStyle(.white)
            Button { SpeechManager.shared.speakIPA(L.ipa) } label: {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.system(size: 30, weight: .bold)).foregroundStyle(.white)
                    .padding(14).background(Circle().fill(Theme.bgBottom))
            }
            .buttonStyle(.plain).accessibilityIdentifier("slice_hear")
            HStack(spacing: 16) {
                ForEach(vm.firstSoundOptions(L), id: \.text) { opt in
                    Button { vm.letterPick(L, opt.correct) } label: {
                        VStack(spacing: 2) {
                            Text(opt.text).font(.system(size: 58))
                            // The word, small, under its picture — so a parent who
                            // doesn't read this language knows what 🦭 stands for.
                            Text(keyword(forPic: opt.text) ?? "")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(Theme.ink.opacity(0.6))
                                .lineLimit(1).minimumScaleFactor(0.6)
                        }
                        .frame(width: 112, height: 112)
                        .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(.white)
                            .shadow(color: .black.opacity(0.18), radius: 8, y: 5))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier(opt.correct ? "slice_pick_correct" : "slice_pick_wrong")
                }
            }
        }
    }

    /// Mentava-style sound→letter: THREE animals each say a different sound; drag
    /// the matching one onto the barrel. (Test mode answers on tap for the autopilot.)
    private func soundDragCard(_ L: Letter) -> some View {
        let choices = vm.dragChoices(L)
        return card {
            Text(Languages.active.t("drag_sound"))
                .font(.system(size: 22, weight: .heavy, design: .rounded)).foregroundStyle(.white)
                .multilineTextAlignment(.center)
            HStack(spacing: 16) {
                ForEach(Array(choices.enumerated()), id: \.element.letter.letter) { idx, ch in
                    dragAnimal(ch.letter, correct: ch.correct, target: L, kindIndex: idx)
                }
            }
            Spacer(minLength: 6)
            barrelView(L)
                .background(GeometryReader { g in
                    Color.clear.preference(key: BarrelFrameKey.self, value: g.frame(in: .named("dragSpace")))
                })
        }
        .coordinateSpace(name: "dragSpace")
        .onPreferenceChange(BarrelFrameKey.self) { vm.barrelFrame = $0 }
    }

    /// One draggable animal that says `animalLetter`'s sound.
    private func dragAnimal(_ animalLetter: Letter, correct: Bool, target L: Letter, kindIndex: Int) -> some View {
        let kinds = CritterKind.allCases
        let kind = kinds[(vm.stepIdx + kindIndex * 3) % kinds.count]
        let off = vm.dragOffsets[animalLetter.letter] ?? .zero
        let animal = ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous).fill(.white.opacity(0.96))
                .frame(width: 102, height: 102).shadow(color: .black.opacity(0.2), radius: 6, y: 4)
            Critter(kind: kind, mood: .happy, size: 74)
            Image(systemName: "speaker.wave.2.fill")
                .font(.system(size: 13, weight: .bold)).foregroundStyle(Theme.ink.opacity(0.5))
                .frame(width: 102, height: 102, alignment: .bottomTrailing).padding(7)
        }
        let pickID = correct ? "slice_pick_correct" : "slice_pick_wrong"
        return Group {
            if fast {
                // Test mode: a real Button (answers on tap) so the e2e autopilot can
                // drive the drag step — a ZStack+onTapGesture isn't found by app.buttons.
                Button { vm.letterPick(L, correct) } label: { animal }
                    .buttonStyle(.plain).accessibilityIdentifier(pickID)
            } else {
                animal
                    .offset(off).scaleEffect(off == .zero ? 1 : 1.1).zIndex(off == .zero ? 0 : 1)
                    .accessibilityElement(children: .combine)
                    .accessibilityIdentifier(pickID).accessibilityAddTraits(.isButton)
                    .onTapGesture { SpeechManager.shared.speakIPA(animalLetter.ipa) }
                    .gesture(DragGesture(coordinateSpace: .named("dragSpace"))
                        .onChanged { v in vm.dragOffsets[animalLetter.letter] = v.translation }
                        .onEnded { v in vm.animalDrop(animalLetter, correct: correct, target: L, at: v.location) })
            }
        }
    }

    /// The barrel showing the target letter — the single drop zone.
    private func barrelView(_ L: Letter) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(LinearGradient(colors: [Color(red: 0.74, green: 0.52, blue: 0.32),
                                              Color(red: 0.54, green: 0.36, blue: 0.20)],
                                     startPoint: .top, endPoint: .bottom))
                .frame(width: 156, height: 124)
                .overlay(VStack {
                    Capsule().fill(.black.opacity(0.16)).frame(height: 9)
                    Spacer()
                    Capsule().fill(.black.opacity(0.16)).frame(height: 9)
                }.padding(.vertical, 16).padding(.horizontal, 6))
            Button { vm.cue(L) } label: {
                Text(L.letter)
                    .font(.system(size: 62, weight: .black, design: .rounded)).foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.35), radius: 2, y: 1)
            }
            .buttonStyle(.plain).accessibilityIdentifier("slice_hear")
        }
    }

    // MARK: - Word (sound out, then prove it)

    private func wordCard(_ w: PWord) -> some View {
        card {
            switch vm.phase {
            case .flex:
                flexInner(w)
            case .prove:
                // READING proof — the word stays on screen; the child reads it and
                // picks its picture. Deliberately silent: hearing the word would
                // turn a decoding check into a listening game.
                Text(w.text)
                    .font(.system(size: 56, weight: .black, design: .rounded)).foregroundStyle(Theme.ink)
                    .padding(.horizontal, 30).padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(.white)
                        .shadow(color: .black.opacity(0.15), radius: 7, y: 4))
                Text(Languages.active.t("which_read"))
                    .font(.system(size: 24, weight: .heavy, design: .rounded)).foregroundStyle(.white)
                HStack(spacing: 16) {
                    ForEach(vm.proveChoices(w), id: \.pic) { opt in
                        Button { vm.provePick(w, opt.correct) } label: {
                            Text(opt.pic).font(.system(size: 64))
                                .frame(width: 108, height: 108)
                                .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(.white)
                                    .shadow(color: .black.opacity(0.18), radius: 8, y: 5))
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier(opt.correct ? "slice_pick_correct" : "slice_pick_wrong")
                    }
                }
            case .build:
                // ENCODING — the word is HIDDEN so the child spells it from the sound
                // + meaning (real encoding), NOT by copying letters off the screen.
                if let pic = w.picture {
                    Text(pic).font(.system(size: 64)).accessibilityHidden(true)
                }
                Text("Spell the word you heard!")
                    .font(.system(size: 26, weight: .heavy, design: .rounded)).foregroundStyle(.white)
                Button { SpeechManager.shared.speak(w.text) } label: {
                    Label("Hear it", systemImage: "speaker.wave.2.fill")
                        .font(.system(size: 18, weight: .heavy, design: .rounded)).foregroundStyle(.white)
                        .padding(.horizontal, 18).padding(.vertical, 10)
                        .background(Capsule().fill(Theme.bgBottom))
                }
                .buttonStyle(.plain).accessibilityIdentifier("slice_hear")
                buildRow(w)
            default:
                // DECODING practice — the word IS shown so the child sounds it out.
                tilesRow(w)
                Text(vm.phase == .blending ? "Sounding out… ☄️" : "Slide the comet to sound it out ☄️")
                    .font(.system(size: 20, weight: .bold, design: .rounded)).foregroundStyle(.white.opacity(0.85))
                blendTrack(w)
                sayItButton(w)
            }
        }
    }

    /// "Flex the sound": which sound does the vowel team make in THIS word?
    @ViewBuilder private func flexInner(_ w: PWord) -> some View {
        if let fc = vm.flexContrast {
            Text("What does \"\(fc.grapheme)\" say here?")
                .font(.system(size: 24, weight: .heavy, design: .rounded)).foregroundStyle(.white)
            Text(w.text).font(.system(size: 72, weight: .black, design: .rounded)).foregroundStyle(Theme.ink)
                .padding(.horizontal, 24).padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(.white))
            HStack(spacing: 22) {
                flexOptionButton(fc.optionA, isA: true)
                flexOptionButton(fc.optionB, isA: false)
            }
        }
    }

    private func flexOptionButton(_ opt: FlexOption, isA: Bool) -> some View {
        Button {
            if !fast { SpeechManager.shared.speakIPA(opt.ipa) }
            vm.flexPick(isA)
        } label: {
            VStack(spacing: 6) {
                Text(opt.picture).font(.system(size: 64))
                Text("like \(opt.keyword)")
                    .font(.system(size: 16, weight: .bold, design: .rounded)).foregroundStyle(Theme.ink)
            }
            .frame(width: 140, height: 150)
            .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(.white)
                .shadow(color: .black.opacity(0.18), radius: 8, y: 5))
        }
        .buttonStyle(.plain)
        // correct/wrong ids let the e2e autopilot drive the flex step
        .accessibilityIdentifier((isA == (vm.flexContrast?.correctIsA ?? true)) ? "flex_correct" : "flex_wrong")
    }

    private func tilesRow(_ w: PWord) -> some View {
        HStack(spacing: 12) {
            ForEach(Array(w.graphemes.enumerated()), id: \.offset) { i, g in
                Button { vm.tapTile(w, i) } label: {
                    LetterTile(text: g.letters, highlighted: vm.highlight == i, silent: g.isSilent)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("slice_tile_\(i)")
            }
        }
    }

    private func blendTrack(_ w: PWord) -> some View {
        GeometryReader { geo in
            let width = geo.size.width
            let maxX = max(0, width - 56)
            let n = max(1, w.soundingIndices.count)
            ZStack(alignment: .leading) {
                Capsule().fill(.white.opacity(0.18)).frame(height: 20)
                    .overlay(HStack(spacing: 0) {
                        ForEach(0..<n, id: \.self) { _ in
                            Circle().fill(.white.opacity(0.35)).frame(width: 8, height: 8).frame(maxWidth: .infinity)
                        }
                    })
                Text("☄️").font(.system(size: 50)).offset(x: vm.orbX)
                    .gesture(DragGesture(minimumDistance: 0)
                        .onChanged { v in
                            guard vm.phase == .explore else { return }
                            let x = min(max(0, v.location.x - 26), maxX)
                            vm.orbX = x
                            let seg = min(n - 1, Int(x / max(1, maxX) * CGFloat(n)))
                            if seg != vm.lastSeg && seg >= 0 {
                                vm.lastSeg = seg
                                let gi = w.soundingIndices[seg]
                                vm.highlight = gi
                                SpeechManager.shared.speakIPA(w.graphemes[gi].ipa ?? "")
                            }
                        }
                        .onEnded { _ in
                            guard vm.phase == .explore else { return }
                            if vm.orbX >= maxX * 0.7 { vm.startBlend(w) }
                            else { vm.anim { vm.orbX = 0 }; vm.highlight = nil; vm.lastSeg = -1 }
                        })
            }
            .frame(height: 56)
        }
        .frame(height: 56).padding(.horizontal, 18)
    }

    private func sayItButton(_ w: PWord) -> some View {
        Button { vm.startBlend(w) } label: {
            Text("Sound it out!")
                .font(.system(size: 30, weight: .heavy, design: .rounded)).foregroundStyle(.white)
                .padding(.horizontal, 40).padding(.vertical, 18)
                .background(Capsule().fill(vm.phase == .blending ? Color.gray : Theme.coral)
                    .shadow(color: Theme.coral.opacity(0.55), radius: 10, y: 6))
                .overlay(Capsule().stroke(.white.opacity(0.6), lineWidth: 3))
        }
        .buttonStyle(.plain).disabled(vm.phase == .blending)
        .accessibilityIdentifier("slice_blend")
    }

    // MARK: - Spell it (the proof of reading a word)

    private func buildRow(_ w: PWord) -> some View {
        let n = w.graphemes.count
        let nextLetter = vm.placedG.count < n ? w.graphemes[vm.placedG.count].letters : nil
        return VStack(spacing: 16) {
            HStack(spacing: 8) {   // slots fill left→right
                ForEach(0..<n, id: \.self) { i in
                    let done = i < vm.placedG.count
                    Text(done ? w.graphemes[vm.placedG[i]].letters : "")
                        .font(.system(size: 40, weight: .black, design: .rounded)).foregroundStyle(Theme.ink)
                        .frame(width: 54, height: 64)
                        .background(RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(done ? Theme.grass.opacity(0.45) : .white.opacity(0.45)))
                }
            }
            HStack(spacing: 10) {  // shuffled letter tray
                ForEach(vm.trayG, id: \.self) { gi in
                    if !vm.placedG.contains(gi) {
                        let correct = nextLetter != nil && w.graphemes[gi].letters == nextLetter
                        Button { vm.buildTap(w, gi, correct: correct) } label: {
                            Text(w.graphemes[gi].letters)
                                .font(.system(size: 40, weight: .black, design: .rounded)).foregroundStyle(Theme.ink)
                                .frame(width: 62, height: 72)
                                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(.white)
                                    .shadow(color: .black.opacity(0.15), radius: 5, y: 3))
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier(correct ? "build_correct" : "build_wrong")
                    }
                }
            }
        }
    }

    // MARK: - Build the sentence (3 visually distinct zones)

    private func sentenceCard(_ words: [String]) -> some View {
        card {
            // 1. READ IT — plain sentence on a cream "book page" (looks like text).
            Text("Read it:")
                .font(.system(size: 18, weight: .bold, design: .rounded)).foregroundStyle(.white.opacity(0.85))
            Text(words.joined(separator: " "))
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 22).padding(.vertical, 16)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color(hex: "#FFF6E2")))

            // 2. ANSWER — underlined gold blanks that fill as words are placed.
            Text("Put it in order:")
                .font(.system(size: 18, weight: .bold, design: .rounded)).foregroundStyle(.white.opacity(0.85))
            VStack(spacing: 10) {
                ForEach(Array(rows(words).enumerated()), id: \.offset) { _, row in
                    HStack(spacing: 12) {
                        ForEach(row, id: \.idx) { item in
                            Text(item.idx < vm.placedW.count ? words[vm.placedW[item.idx]] : " ")
                                .font(.system(size: 24, weight: .heavy, design: .rounded))
                                .foregroundStyle(Theme.sun)
                                .frame(minWidth: 64)
                                .overlay(Rectangle().fill(.white.opacity(0.6)).frame(height: 3), alignment: .bottom)
                        }
                    }
                }
            }
            .padding(.vertical, 4)

            // 3. TILES — raised coral pill buttons (clearly tappable, very different).
            HStack(spacing: 12) {
                ForEach(vm.trayW, id: \.self) { wi in
                    if !vm.placedW.contains(wi) {
                        let correct = vm.placedW.count < words.count && words[wi] == words[vm.placedW.count]
                        Button { vm.sentTap(words, wi, correct: correct) } label: {
                            Text(words[wi])
                                .font(.system(size: 24, weight: .heavy, design: .rounded)).foregroundStyle(.white)
                                .padding(.horizontal, 16).padding(.vertical, 12)
                                .background(Capsule().fill(Theme.coral)
                                    .shadow(color: .black.opacity(0.25), radius: 5, y: 3))
                                .overlay(Capsule().stroke(.white.opacity(0.5), lineWidth: 2))
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier(correct ? "sentbuild_correct" : "sentbuild_wrong")
                    }
                }
            }
        }
    }

    private func rows(_ words: [String]) -> [[(idx: Int, word: String)]] {
        let indexed = words.enumerated().map { (idx: $0.offset, word: $0.element) }
        return stride(from: 0, to: indexed.count, by: 4).map { Array(indexed[$0..<min($0 + 4, indexed.count)]) }
    }

    // MARK: - Per-answer animal cheer

    private var cheerOverlay: some View {
        ZStack {
            ForEach(0..<6, id: \.self) { i in
                Text(["✨","⭐","🌟","💫"][i % 4])
                    .font(.system(size: 30))
                    .offset(x: CGFloat([-90, 80, -60, 100, -110, 60][i]),
                            y: CGFloat([-40, -70, 30, 20, -10, 70][i]))
                    .opacity(vm.cheerPop ? 0 : 1)
                    .scaleEffect(vm.cheerPop ? 1.4 : 0.3)
            }
            Critter(kind: mascotKind, mood: .cheer, size: 150)
                .scaleEffect(vm.cheerPop ? 1.0 : 0.4)
                .offset(y: vm.cheerPop ? -10 : 40)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .transition(.opacity)
    }

    // MARK: - Celebration

    private var celebrationOverlay: some View {
        LessonCelebrationView(stars: vm.earnedStars,
                              scene: vm.celebScene,
                              tilesStart: vm.celebTilesStart,
                              posterCompleted: vm.posterCompleted,
                              shareName: vm.offerFirstShare ? store.current?.name : nil,
                              fast: fast) { done() }
            .transition(.opacity)
    }

    // MARK: - Model-and-redo (scaffold after repeated misses)

    private var modelOverlay: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()
            VStack(spacing: 14) {
                Text("Here it is! 👇")
                    .font(.system(size: 24, weight: .heavy, design: .rounded)).foregroundStyle(.white)
                if let hint = vm.modelHint {
                    Text(hint.big)
                        .font(.system(size: 96, weight: .black, design: .rounded)).foregroundStyle(Theme.ink)
                        .padding(.horizontal, 28).padding(.vertical, 14)
                        .background(RoundedRectangle(cornerRadius: 26, style: .continuous).fill(.white))
                    Text(hint.sub)
                        .font(.system(size: 18, weight: .semibold, design: .rounded)).foregroundStyle(.white.opacity(0.9))
                }
                Text("Now you try!")
                    .font(.system(size: 20, weight: .heavy, design: .rounded)).foregroundStyle(Theme.sun)
            }
            .padding(34)
            .background(RoundedRectangle(cornerRadius: 34, style: .continuous).fill(.ultraThinMaterial))
        }
        .transition(.opacity)
        .accessibilityHidden(true)
    }

    // MARK: - Anti-guess reset

    private var resetOverlay: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()
            VStack(spacing: 16) {
                Critter(kind: mascotKind, mood: .oops, size: 130).accessibilityHidden(true)
                Text("Let's try again!")
                    .font(.system(size: 34, weight: .black, design: .rounded)).foregroundStyle(.white)
                Text("Take your time — listen, then tap.")
                    .font(.system(size: 18, weight: .semibold, design: .rounded)).foregroundStyle(.white.opacity(0.85))
            }
            .padding(36)
            .background(RoundedRectangle(cornerRadius: 36, style: .continuous).fill(.ultraThinMaterial))
        }
        .transition(.opacity)
        .accessibilityIdentifier("lesson_reset")
    }

    // MARK: - First-run coach

    private var coachOverlay: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
            VStack(spacing: 20) {
                Text(Languages.active.t("how_to_play"))
                    .font(.system(size: 30, weight: .black, design: .rounded)).foregroundStyle(.white)
                coachLine("👆", Languages.active.t("coach_tap"))
                coachLine("☄️", Languages.active.t("coach_slide"))
                coachLine("🧠", Languages.active.t("coach_prove"))
                coachLine("🚀", Languages.active.t("coach_blast"))
                bigButton(Languages.active.t("lets_go"), id: "coach_go") {
                    UserDefaults.standard.set(true, forKey: coachKey)
                    withAnimation(.easeOut(duration: 0.25)) { showCoach = false }
                }
            }
            .padding(34)
            .background(RoundedRectangle(cornerRadius: 36, style: .continuous).fill(.ultraThinMaterial))
            .padding(40)
        }
        .transition(.opacity)
    }

    private func coachLine(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 14) {
            Text(icon).font(.system(size: 38))
            Text(text).font(.system(size: 22, weight: .heavy, design: .rounded)).foregroundStyle(.white)
            Spacer(minLength: 0)
        }
    }

    // MARK: - Shared button

    private func bigButton(_ title: String, id: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 28, weight: .heavy, design: .rounded)).foregroundStyle(.white)
                .padding(.horizontal, 38).padding(.vertical, 16)
                .background(Capsule().fill(Theme.coral))
                .overlay(Capsule().stroke(.white.opacity(0.6), lineWidth: 3))
        }
        .buttonStyle(.plain).accessibilityIdentifier(id)
    }
}

/// The barrel's frame (in the drag coordinate space) so a dragged animal can be
/// hit-tested against it.
struct BarrelFrameKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        let n = nextValue(); if n != .zero { value = n }
    }
}

#Preview("World lesson") {
    WorldLessonView(lesson: Curriculum.firstLesson)
        .environmentObject(ProfileStore())
}
