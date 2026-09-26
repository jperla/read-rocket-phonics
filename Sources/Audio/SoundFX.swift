import Foundation
import AVFoundation

/// Tiny, self-contained game sound effects. The chimes are synthesized to PCM
/// WAV at runtime (no bundled assets, no downloads) and played on cached
/// AVAudioPlayers. Kept short and gentle so they never fight the speech audio,
/// and silent under UI testing.
final class SoundFX {
    static let shared = SoundFX()
    private init() {}

    private static let sr = 22_050.0
    private var players: [String: AVAudioPlayer] = [:]

    enum Effect: String, CaseIterable { case correct, retry, blastoff, sparkle, fanfare }

    // MARK: - Public effects

    func correct() { play(.correct) }                 // happy rising arpeggio
    func retry() { play(.retry, volume: 0.4) }        // gentle two-note, never a buzzer
    func blastoff() { play(.blastoff) }               // rising whoosh
    func sparkle() { play(.sparkle, volume: 0.45) }   // quick magic shimmer (gift wiggle / tap)
    func fanfare() { play(.fanfare, volume: 0.6) }    // triumphant two-chord (gift opens)

    /// The synthesized WAV for an effect (also used by tests to verify validity).
    static func wav(for e: Effect) -> Data {
        switch e {
        case .correct:  return wav(tone([523.25], 0.10) + tone([659.25], 0.10) + tone([783.99, 1046.5], 0.18))
        case .retry:    return wav(tone([392.0], 0.12) + tone([329.63], 0.16))
        case .blastoff: return wav(sweep(from: 220, to: 1100, 0.7))
        case .sparkle:  return wav(tone([1046.5], 0.06) + tone([1318.5], 0.06) + tone([1568.0], 0.06) + tone([2093.0], 0.12))
        case .fanfare:  return wav(tone([523.25, 659.25, 783.99], 0.16) + tone([587.33, 739.99, 880.0], 0.14) + tone([783.99, 1046.5, 1318.5], 0.42))
        }
    }

    // MARK: - Playback

    private func play(_ e: Effect, volume: Float = 0.5) {
        guard !AppEnv.uiTesting else { return }
        if players[e.rawValue] == nil {
            players[e.rawValue] = try? AVAudioPlayer(data: SoundFX.wav(for: e))
        }
        guard let p = players[e.rawValue] else { return }
        p.volume = volume
        p.currentTime = 0
        p.play()
    }

    // MARK: - Synthesis

    private static func tone(_ freqs: [Double], _ dur: Double, amp: Double = 0.55) -> [Int16] {
        let n = Int(dur * sr)
        let attack = max(1.0, 0.008 * sr)
        var out = [Int16](); out.reserveCapacity(n)
        for i in 0..<n {
            let t = Double(i) / sr
            var v = 0.0
            for f in freqs { v += sin(2 * .pi * f * t) }
            v /= Double(max(1, freqs.count))
            let env = min(Double(i) / attack, 1.0) * pow(1.0 - Double(i) / Double(n), 1.4)
            out.append(Int16(max(-1, min(1, v * env * amp)) * 32767))
        }
        return out
    }

    private static func sweep(from f0: Double, to f1: Double, _ dur: Double, amp: Double = 0.5) -> [Int16] {
        let n = Int(dur * sr)
        let attack = max(1.0, 0.01 * sr)
        var out = [Int16](); out.reserveCapacity(n)
        var phase = 0.0
        for i in 0..<n {
            let frac = Double(i) / Double(n)
            phase += 2 * .pi * (f0 + (f1 - f0) * frac) / sr
            let env = min(Double(i) / attack, 1.0) * pow(1.0 - frac, 0.7)
            out.append(Int16(max(-1, min(1, sin(phase) * env * amp)) * 32767))
        }
        return out
    }

    private static func wav(_ samples: [Int16]) -> Data {
        var d = Data()
        let srate = UInt32(sr), channels: UInt16 = 1, bits: UInt16 = 16
        let byteRate = srate * UInt32(channels) * UInt32(bits / 8)
        let dataSize = UInt32(samples.count * 2)
        func ascii(_ s: String) { d.append(s.data(using: .ascii)!) }
        func u32(_ v: UInt32) { withUnsafeBytes(of: v.littleEndian) { d.append(contentsOf: $0) } }
        func u16(_ v: UInt16) { withUnsafeBytes(of: v.littleEndian) { d.append(contentsOf: $0) } }
        ascii("RIFF"); u32(36 + dataSize); ascii("WAVE")
        ascii("fmt "); u32(16); u16(1); u16(channels); u32(srate); u32(byteRate); u16(channels * bits / 8); u16(bits)
        ascii("data"); u32(dataSize)
        for s in samples { withUnsafeBytes(of: s.littleEndian) { d.append(contentsOf: $0) } }
        return d
    }
}
