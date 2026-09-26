import Foundation
import AVFoundation

/// Plays pre-generated, super-clear audio clips bundled with the app.
///
/// The clips are made ahead of time with Gemini TTS (`tools/gen_audio.py`) and
/// audited for clarity, then bundled as `Resources/Audio/*.wav`. This replaces the
/// mushy/short live `AVSpeechSynthesizer` rendering for the sounds we have clips
/// for. Anything without a clip falls back to live synthesis, so the app always
/// makes a sound even before every clip exists.
final class AudioBank {
    static let shared = AudioBank()
    private init() {}

    private var players: [String: AVAudioPlayer] = [:]

    /// IPA phoneme -> clip filename stem. MUST match `IPA_KEY` in tools/gen_audio.py.
    static let ipaKey: [String: String] = [
        "s": "s", "æ": "a", "m": "m", "f": "f", "ɪ": "i", "n": "n", "t": "t",
        "ɑ": "o", "d": "d", "l": "l", "h": "h", "ɛ": "e", "g": "g", "ʌ": "u",
        "k": "k", "r": "r", "b": "b", "p": "p", "dʒ": "j", "v": "v", "w": "w",
        "j": "y", "z": "z", "kw": "qu", "ks": "x"
    ]

    /// GLOBAL phoneme registry: exact IPA → bundled clip stem. Any language reuses
    /// ANY existing recording with the same sound — English consonants, the Greek
    /// pure vowels /a/e/i/o/ and /x/, etc. A new language only records the sounds no
    /// prior language has. Entries whose wav isn't bundled yet fall through to TTS.
    static let recordedClip: [String: String] = {
        var m: [String: String] = [:]
        for (ipa, key) in ipaKey { m[ipa] = "phoneme_\(key)" }      // English (æ→phoneme_a, s→phoneme_s, …)
        // Greek recordings (the user's voice)
        m["a"] = "phoneme_el_a"; m["e"] = "phoneme_el_e"; m["i"] = "phoneme_el_i"; m["o"] = "phoneme_el_o"
        m["θ"] = "phoneme_el_th"; m["ð"] = "phoneme_el_dh"; m["ɣ"] = "phoneme_el_gh"
        m["x"] = "phoneme_el_x"; m["ps"] = "phoneme_el_ps"
        // Spanish-specific recordings (added when recorded; TTS until then)
        m["u"] = "phoneme_es_u"; m["ɲ"] = "phoneme_es_ny"; m["ɾ"] = "phoneme_es_r"; m["ʝ"] = "phoneme_es_y"
        // French / Portuguese / German shared new sounds (one recording per IPA;
        // French u + German ü/y are the same /y/). TTS until recorded.
        m["ʁ"] = "phoneme_rr"; m["ʒ"] = "phoneme_zh"; m["y"] = "phoneme_ue"; m["ə"] = "phoneme_schwa"
        m["ʃ"] = "phoneme_sh"; m["ø"] = "phoneme_oe"; m["ts"] = "phoneme_ts"
        // Context-engine + British RP recordings (user's voice, 2026-06-09)
        m["ɔ"] = "phoneme_aw"; m["kv"] = "phoneme_kv"
        m["ɑ̃"] = "phoneme_fr_an"; m["ɔ̃"] = "phoneme_fr_on"; m["ɛ̃"] = "phoneme_fr_in"
        m["œ"] = "phoneme_fr_oe"; m["wa"] = "phoneme_fr_wa"
        m["ɐ̃w"] = "phoneme_pt_aow"; m["ɐ̃j"] = "phoneme_pt_aej"
        // British English (RP): LOT /ɒ/ + non-rhotic long vowels & centring diphthongs
        m["ɒ"] = "phoneme_uk_o"; m["ɑː"] = "phoneme_uk_ar"; m["ɔː"] = "phoneme_uk_or"
        m["ɜː"] = "phoneme_uk_er"; m["əʊ"] = "phoneme_uk_oa"; m["eə"] = "phoneme_uk_air"
        m["ɪə"] = "phoneme_uk_ear"; m["ʊə"] = "phoneme_uk_ure"
        // German vowel length (long/short) + vocalized -r
        m["aː"] = "phoneme_de_a_long"; m["eː"] = "phoneme_de_e_long"; m["iː"] = "phoneme_de_i_long"
        m["oː"] = "phoneme_de_o_long"; m["uː"] = "phoneme_de_u_long"
        m["ʊ"] = "phoneme_de_u_short"; m["ɐ"] = "phoneme_de_er"
        // long umlauts reuse the nearest recorded clip
        m["ɛː"] = "phoneme_e"; m["øː"] = "phoneme_oe"; m["yː"] = "phoneme_ue"
        return m
    }()

    private func bundled(_ stem: String) -> URL? {
        Bundle.main.url(forResource: stem, withExtension: "wav", subdirectory: "Audio")
            ?? Bundle.main.url(forResource: stem, withExtension: "wav")
    }

    /// Resolve the recorded clip for an IPA by exact match against the global
    /// registry, reused across every language. nil → caller falls back to TTS.
    func clip(forIPA ipa: String) -> (name: String, url: URL)? {
        guard let stem = AudioBank.recordedClip[ipa], let u = bundled(stem) else { return nil }
        return (stem, u)
    }

    /// Fixed spoken UI lines -> clip stem. Keyed by the normalized phrase.
    static let lineKey: [String: String] = [
        "great job!": "ui_greatjob",
        "blast off! great job!": "ui_blastoff",
        "let's try again!": "ui_tryagain",
        "say it with me!": "ui_sayitwithme",
        "who is reading today?": "ui_whoreading",
        "b is for belly!": "ui_belly",
        "d is for diaper!": "ui_diaper"
    ]

    func clipName(forLine text: String) -> String? {
        AudioBank.lineKey[text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()]
    }

    func hasClip(_ name: String?) -> Bool { url(name) != nil }

    private func url(_ name: String?) -> URL? {
        guard let name else { return nil }
        return bundled(name)
    }

    func stopAll() {
        for p in players.values { p.stop() }
    }

    /// Play a bundled clip. `onDone` fires when it finishes. Returns the clip's
    /// duration, or nil if the clip wasn't found (caller should then fall back).
    @discardableResult
    func play(_ name: String, volume: Float = 1.0, onDone: (() -> Void)? = nil) -> TimeInterval? {
        guard let u = url(name) else { return nil }
        let p: AVAudioPlayer
        if let cached = players[name] {
            p = cached
        } else if let np = try? AVAudioPlayer(contentsOf: u) {
            np.prepareToPlay(); players[name] = np; p = np
        } else {
            return nil
        }
        stopAll()
        p.volume = volume
        p.currentTime = 0
        p.play()
        let dur = p.duration
        if let onDone {
            DispatchQueue.main.asyncAfter(deadline: .now() + dur + 0.03) { onDone() }
        }
        return dur
    }

    /// Play a clip resolved to a specific URL (used by `clip(forIPA:)`), cached by name.
    @discardableResult
    func play(_ name: String, url u: URL, volume: Float = 1.0, onDone: (() -> Void)? = nil) -> TimeInterval? {
        let p: AVAudioPlayer
        if let cached = players[name] { p = cached }
        else if let np = try? AVAudioPlayer(contentsOf: u) { np.prepareToPlay(); players[name] = np; p = np }
        else { return nil }
        stopAll(); p.volume = volume; p.currentTime = 0; p.play()
        let dur = p.duration
        if let onDone { DispatchQueue.main.asyncAfter(deadline: .now() + dur + 0.03) { onDone() } }
        return dur
    }
}
