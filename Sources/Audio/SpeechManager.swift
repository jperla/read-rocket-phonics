import Foundation
import AVFoundation
import Combine

/// Wraps AVSpeechSynthesizer. Uses SSML <phoneme> with IPA so isolated phonemes
/// (the heart of phonics) sound correct, not like letter names.
/// Publishes `isSpeaking` so the mascot can flap its mouth while talking.
///
/// Reliability: a *fresh* AVSpeechSynthesizer is used for each speak operation.
/// Reusing one instance across many stop/speak cycles can wedge on a real device
/// (speech goes silent after the first utterance — the "only hear cat" bug). The
/// audio session is re-activated before each utterance and rebuilt if the media
/// server resets, and `.duckOthers` is avoided (MusicPlayer pauses music itself).
final class SpeechManager: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    static let shared = SpeechManager()

    @Published var isSpeaking = false

    private var synth = AVSpeechSynthesizer()
    private var voiceCache: [String: AVSpeechSynthesisVoice] = [:]

    /// The best installed voice for the ACTIVE language's locale (cached). Greek mode
    /// uses an el-GR voice; English uses en-US. Falls back gracefully if absent.
    /// Only SUCCESSFUL lookups are cached: speechVoices() can be empty/partial right
    /// after boot, and a parent can install a better voice mid-session (the
    /// usingBasicVoice copy directs them to) — a cached nil would never recover.
    private func currentVoice() -> AVSpeechSynthesisVoice? {
        let loc = Languages.active.ttsLocale
        if let cached = voiceCache[loc] { return cached }
        guard let v = SpeechManager.pickVoice(loc) else { return nil }
        voiceCache[loc] = v
        return v
    }

    /// True when only the low-fi "compact" system voice is installed. The parent
    /// can download a clearer voice in Settings → Accessibility → Spoken Content.
    var usingBasicVoice: Bool { (currentVoice()?.quality ?? .default) == .default }

    // Blend sequencing state
    private var blendMap: [ObjectIdentifier: Int] = [:]
    private var blendWordUtterance: AVSpeechUtterance?
    private var blendHighlight: ((Int?) -> Void)?
    private var blendDone: (() -> Void)?

    override init() {
        super.init()
        synth.delegate = self
        configureAudioSession()
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(handleInterruption(_:)),
                       name: AVAudioSession.interruptionNotification, object: nil)
        nc.addObserver(self, selector: #selector(handleMediaReset(_:)),
                       name: AVAudioSession.mediaServicesWereResetNotification, object: nil)
    }

    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        // No `.duckOthers`: our own looping music + `.duckOthers` could leave the
        // synthesizer silent after its first utterance. MusicPlayer fully pauses
        // the music during speech instead.
        try? session.setCategory(.playback, mode: .spokenAudio)
        try? session.setActive(true)
    }

    /// Defensive: make sure the session is live right before speaking.
    private func activate() {
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    @objc private func handleInterruption(_ n: Notification) {
        let t = (n.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt) ?? 99
        if t == 0 { activate() }   // .ended → re-activate
    }

    @objc private func handleMediaReset(_ n: Notification) {
        configureAudioSession()
        synth.stopSpeaking(at: .immediate)   // tell the old instance to stop, not just drop it
        synth = AVSpeechSynthesizer()
        synth.delegate = self
    }

    /// A clean synthesizer for the next operation. Stops + discards the old one.
    private func prepareSynth() {
        synth.stopSpeaking(at: .immediate)
        let s = AVSpeechSynthesizer()
        s.delegate = self
        synth = s
    }

    private static func pickVoice(_ locale: String) -> AVSpeechSynthesisVoice? {
        let lang = String(locale.prefix(2))     // "el-GR" → "el"
        let all = AVSpeechSynthesisVoice.speechVoices()
        let exact = all.filter { $0.language == locale }
        let broad = all.filter { $0.language.hasPrefix(lang) }
        // Region first, then quality WITHIN the region: an en-GB compact voice
        // beats an enhanced en-US one — the pack's IPA is authored for the region
        // (en-GB vs en-US, pt-PT vs pt-BR are separate shipped packs).
        for pool in [exact, broad] {
            if let v = pool.first(where: { $0.quality == .premium })
                    ?? pool.first(where: { $0.quality == .enhanced })
                    ?? pool.first { return v }
        }
        return AVSpeechSynthesisVoice(language: locale) ?? AVSpeechSynthesisVoice(language: lang)
    }

    // MARK: - Simple speech

    func speak(_ text: String, rate: Float = 0.45, pitch: Float = 1.08) {
        if AppEnv.uiTesting { return }
        // Prefer a pre-generated clip for known fixed lines; else live synthesis.
        if let name = AudioBank.shared.clipName(forLine: text), AudioBank.shared.hasClip(name) {
            activate(); clearBlend(); synth.stopSpeaking(at: .immediate)
            setSpeaking(true)
            AudioBank.shared.play(name) { [weak self] in self?.setSpeaking(false) }
            return
        }
        activate()
        clearBlend()
        prepareSynth()
        let u = AVSpeechUtterance(string: text)
        u.voice = currentVoice()
        u.rate = rate
        u.pitchMultiplier = pitch
        u.volume = 1.0
        synth.speak(u)
    }

    /// Greet a child by name in the active language. If the typed name's script
    /// doesn't match the active voice's (a Greek voice spells out "Chloe" as
    /// letter names), the name is spoken mid-sentence by a voice that CAN say it.
    func speakGreeting(_ template: String, name rawName: String) {
        if AppEnv.uiTesting { return }
        // Names display in ALL CAPS, but an all-caps string can be read out as
        // an acronym ("C-H-L-O-E") — speak the capitalized form instead.
        let name = rawName.count > 1 && rawName == rawName.uppercased() ? rawName.capitalized : rawName
        let flat = template.replacingOccurrences(of: "%@", with: name)
        let parts = template.components(separatedBy: "%@")
        guard parts.count == 2,
              let nameLoc = SpeechManager.nameVoiceLocale(for: name, active: Languages.active.ttsLocale),
              let nameVoice = SpeechManager.pickVoice(nameLoc) else {
            speak(flat); return
        }
        activate(); clearBlend(); prepareSynth()
        for (text, voice) in [(parts[0], currentVoice()), (name, nameVoice), (parts[1], currentVoice())] {
            let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !t.isEmpty else { continue }
            let u = AVSpeechUtterance(string: t)
            u.voice = voice
            u.rate = 0.45
            u.pitchMultiplier = 1.08
            u.volume = 1.0
            u.postUtteranceDelay = 0.05
            synth.speak(u)        // queued on the same fresh synthesizer, in order
        }
    }

    /// The locale of a voice that can actually SAY this name, or nil when the
    /// active voice already can. Greek is the only non-Latin pack script today.
    nonisolated static func nameVoiceLocale(for name: String, active: String) -> String? {
        let scalars = name.unicodeScalars
        let hasGreek = scalars.contains { (0x370...0x3FF).contains(Int($0.value)) || (0x1F00...0x1FFF).contains(Int($0.value)) }
        let hasLatin = scalars.contains { (65...90).contains($0.value) || (97...122).contains($0.value) }
        if active.hasPrefix("el"), hasLatin, !hasGreek { return "en-US" }
        if !active.hasPrefix("el"), hasGreek, !hasLatin { return "el-GR" }
        return nil
    }

    func speakIPA(_ ipa: String, rate: Float = 0.38) {
        if AppEnv.uiTesting { return }
        // Prefer a pre-generated, super-clear clip; fall back to live synthesis.
        if let c = AudioBank.shared.clip(forIPA: ipa) {
            activate(); clearBlend(); synth.stopSpeaking(at: .immediate)
            setSpeaking(true)
            AudioBank.shared.play(c.name, url: c.url) { [weak self] in self?.setSpeaking(false) }
            return
        }
        activate()
        clearBlend()
        prepareSynth()
        synth.speak(phonemeUtterance(ipa: ipa, rate: rate))
    }

    /// Stop consonants (and the /j/ glide, /r/, /th/) are nearly inaudible in
    /// isolation — a stop is just a brief burst, isolated /j/ collapses to "ee",
    /// and /r//th/ render faint. A tiny schwa release ("buh","guh","yuh","ruh")
    /// makes them hearable. Verified by rendering each and listening.
    private static let needSchwa: Set<String> = ["p", "b", "t", "d", "k", "g", "tʃ", "dʒ", "j", "r", "θ", "ð"]

    /// Continuant sounds CAN be held — and SHOULD be, so a child hears a long
    /// "sss", "mmm", "fff" and learns to stretch them for blending (vs. the
    /// clipped burst of a stop). The reliable lever is REPEATING the IPA symbol
    /// 3× — measured deterministically with ffprobe (/s/ rendered 0.431610s on
    /// four consecutive runs; 1× = 0.187s, so ~2.3× longer; 6× was WORSE at
    /// 0.33s, so 3× is the peak). Utterance RATE does NOT affect synth.write()
    /// duration (identical 0.187s at default/half/min), so it's not used here.
    /// /r/ is NOT a continuant here — it turns into a vowel when held — so it
    /// gets a schwa release in needSchwa instead.
    private static let continuants: Set<String> = ["s", "m", "f", "n", "l", "v", "z", "ʃ", "ŋ"]
    private static let holdCount = 3

    private func phonemeUtterance(ipa: String, rate: Float) -> AVSpeechUtterance {
        let render: String
        if SpeechManager.continuants.contains(ipa) {
            render = String(repeating: ipa, count: SpeechManager.holdCount)   // hold it: "sss" (deterministic ~0.43s)
        } else if SpeechManager.needSchwa.contains(ipa) {
            render = ipa + "ə"                                                 // release it: "buh"
        } else {
            render = ipa
        }
        let useRate = rate
        let ssml = "<speak><phoneme alphabet=\"ipa\" ph=\"\(xmlEscape(render))\">·</phoneme></speak>"
        let u = AVSpeechUtterance(ssmlRepresentation: ssml) ?? AVSpeechUtterance(string: ipa)
        u.voice = currentVoice()
        u.rate = useRate
        u.pitchMultiplier = 1.08
        u.volume = 1.0
        return u
    }

    private func xmlEscape(_ s: String) -> String {
        s.replacingOccurrences(of: "&", with: "&amp;")
         .replacingOccurrences(of: "<", with: "&lt;")
         .replacingOccurrences(of: ">", with: "&gt;")
         .replacingOccurrences(of: "\"", with: "&quot;")
    }

    // MARK: - Blending

    func playBlend(_ word: PWord,
                   onHighlight: @escaping (Int?) -> Void,
                   onDone: @escaping () -> Void) {
        // Reproduce a device where the synth silently never finishes: produce no
        // sound and never call back. Callers must not depend on these closures.
        if AppEnv.deadBlendAudio { return }
        if AppEnv.uiTesting { DispatchQueue.main.async { onHighlight(nil); onDone() }; return }

        // If every sounded part has a clear pre-generated clip, sequence the clips
        // (clean audio). Otherwise fall back to live synthesis for the whole word.
        let parts: [(Int, String)] = word.soundingIndices.compactMap { idx in
            guard let ipa = word.graphemes[idx].ipa else { return nil }
            return (idx, ipa)
        }
        if !parts.isEmpty,
           parts.allSatisfy({ AudioBank.shared.clip(forIPA: $0.1) != nil }) {
            activate(); clearBlend(); synth.stopSpeaking(at: .immediate)
            playBlendClips(parts, 0, onHighlight: onHighlight, onDone: onDone)
            return
        }

        activate()
        clearBlend()
        prepareSynth()
        blendHighlight = onHighlight
        blendDone = onDone

        // Sound out the PARTS only — never speak the whole word. The child has to
        // blend the sounds and read it themselves, then prove it with a challenge.
        var last: AVSpeechUtterance?
        for idx in word.soundingIndices {
            guard let ipa = word.graphemes[idx].ipa else { continue }
            let u = phonemeUtterance(ipa: ipa, rate: 0.32)
            u.postUtteranceDelay = 0.16
            blendMap[ObjectIdentifier(u)] = idx
            synth.speak(u)
            last = u
        }
        blendWordUtterance = last   // onDone fires after the last sound (no whole word)
    }

    /// Sound out a word using pre-generated clips, one part at a time, highlighting
    /// each segment as it plays. Used when every part has a clean clip.
    private func playBlendClips(_ parts: [(Int, String)], _ i: Int,
                                onHighlight: @escaping (Int?) -> Void,
                                onDone: @escaping () -> Void) {
        if i >= parts.count {
            setSpeaking(false)
            DispatchQueue.main.async { onHighlight(nil); onDone() }
            return
        }
        let (idx, ipa) = parts[i]
        setSpeaking(true)
        DispatchQueue.main.async { onHighlight(idx) }
        guard let c = AudioBank.shared.clip(forIPA: ipa) else {
            playBlendClips(parts, i + 1, onHighlight: onHighlight, onDone: onDone); return
        }
        AudioBank.shared.play(c.name, url: c.url) { [weak self] in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                self?.playBlendClips(parts, i + 1, onHighlight: onHighlight, onDone: onDone)
            }
        }
    }

    func stop() {
        clearBlend()
        AudioBank.shared.stopAll()
        synth.stopSpeaking(at: .immediate)
        DispatchQueue.main.async { self.isSpeaking = false }
    }

    private func clearBlend() {
        blendMap.removeAll()
        blendWordUtterance = nil
        blendHighlight = nil
        blendDone = nil
    }

    private func setSpeaking(_ v: Bool) {
        DispatchQueue.main.async { self.isSpeaking = v }
    }

    // MARK: - AVSpeechSynthesizerDelegate

    // All three guard `s === synth`: prepareSynth()/handleMediaReset() discard old
    // synthesizers whose late didFinish/didCancel callbacks would otherwise clobber
    // isSpeaking (the stale `false` can land AFTER the new synth's didStart `true`).

    func speechSynthesizer(_ s: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        guard s === synth else { return }
        setSpeaking(true)
        guard blendDone != nil else { return }
        let idx = blendMap[ObjectIdentifier(utterance)]   // nil for whole-word utterance
        DispatchQueue.main.async { self.blendHighlight?(idx) }
    }

    func speechSynthesizer(_ s: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        guard s === synth else { return }
        DispatchQueue.main.async { self.isSpeaking = s.isSpeaking }
        guard let wordU = blendWordUtterance, utterance === wordU else { return }
        let done = blendDone
        let hl = blendHighlight
        clearBlend()
        DispatchQueue.main.async { hl?(nil); done?() }
    }

    func speechSynthesizer(_ s: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        guard s === synth else { return }
        DispatchQueue.main.async { self.isSpeaking = s.isSpeaking }
    }
}
