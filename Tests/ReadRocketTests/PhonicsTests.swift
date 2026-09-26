import XCTest
@testable import ReadRocketPhonics

final class PhonicsTests: XCTestCase {

    func testSimpleCVCBuilder() {
        let w = Phonics.word("cat", ["c", "a", "t"])
        XCTAssertEqual(w.graphemes.map { $0.letters }, ["c", "a", "t"])
        XCTAssertEqual(w.graphemes.compactMap { $0.ipa }, ["k", "æ", "t"])
        XCTAssertFalse(w.graphemes.contains { $0.isSilent })
        XCTAssertEqual(w.blendPlan, ["k", "æ", "t"])
    }

    func testMagicESilentE() {
        let w = Phonics.word("cake", ["c", "a:eɪ", "k", "e:"])
        XCTAssertEqual(w.graphemes.map { $0.letters }, ["c", "a", "k", "e"])
        XCTAssertEqual(w.graphemes[1].ipa, "eɪ")
        XCTAssertNil(w.graphemes[3].ipa)
        XCTAssertTrue(w.graphemes[3].isSilent)
        XCTAssertTrue(w.graphemes[3].intentionallySilent)
        XCTAssertEqual(w.blendPlan, ["k", "eɪ", "k"])   // silent-e excluded
    }

    func testDigraphAndDoubledConsonant() {
        XCTAssertEqual(Phonics.word("ship", ["sh", "i", "p"]).blendPlan, ["ʃ", "ɪ", "p"])
        // /g/ uses plain ASCII "g" (U+0067); Apple's speech engine silently drops
        // the IPA script-ɡ (U+0261), which made the sound inaudible. See SoundCheck.
        XCTAssertEqual(Phonics.word("egg", ["e", "gg"]).blendPlan, ["ɛ", "g"])
    }

    func testVoicedTHInline() {
        XCTAssertEqual(Phonics.word("this", ["th:ð", "i", "s"]).graphemes.first?.ipa, "ð")
    }

    func testUnknownTokenIsNilAndNotIntentional() {
        // A typo'd chunk yields a nil ipa that is NOT intentionallySilent — this is
        // exactly what the curriculum integrity test relies on to catch bad data.
        let w = Phonics.word("zq", ["z", "qqq"])
        XCTAssertEqual(w.graphemes[0].ipa, "z")
        XCTAssertNil(w.graphemes[1].ipa)
        XCTAssertFalse(w.graphemes[1].intentionallySilent)
    }
}
