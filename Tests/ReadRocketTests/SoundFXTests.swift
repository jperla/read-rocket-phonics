import XCTest
@testable import ReadRocketPhonics

/// The game sound effects are synthesized to PCM WAV at runtime. Verify each one
/// is a valid, non-silent WAV so AVAudioPlayer can play it (a malformed header or
/// all-zero buffer would silently produce nothing).
final class SoundFXTests: XCTestCase {

    func testEveryEffectIsValidNonSilentWAV() {
        for effect in SoundFX.Effect.allCases {
            let data = SoundFX.wav(for: effect)
            XCTAssertGreaterThan(data.count, 1000, "\(effect) WAV is too small")

            // RIFF/WAVE header
            XCTAssertEqual(String(decoding: data.prefix(4), as: UTF8.self), "RIFF", "\(effect) missing RIFF")
            let wave = String(decoding: data.subdata(in: 8..<12), as: UTF8.self)
            XCTAssertEqual(wave, "WAVE", "\(effect) missing WAVE")

            // PCM payload (after the 44-byte header) must not be all zero.
            let pcm = data.suffix(from: 44)
            XCTAssertTrue(pcm.contains { $0 != 0 }, "\(effect) is silent (all-zero samples)")
        }
    }
}
