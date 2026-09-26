import XCTest
@testable import ReadRocketPhonics

final class SpanishLandTests: XCTestCase {

    override func tearDown() { Languages.setCurrent("en"); super.tearDown() }

    func testSpanishAlphabetIsComplete() {
        XCTAssertEqual(SpanishLand.letters.count, 26)   // a–z minus silent h, plus ñ
        for L in SpanishLand.letters {
            XCTAssertFalse(L.ipa.isEmpty, "\(L.letter) has no IPA")
            XCTAssertFalse(L.picture.isEmpty)
            XCTAssertFalse(L.keyword.isEmpty)
        }
        XCTAssertEqual(Set(SpanishLand.letters.map { $0.letter }).count, 26)
        XCTAssertNotNil(SpanishLand.letter("ñ"))
    }

    func testSpanishUnitsArePlayableAndNamespaced() {
        var ids = Set<String>()
        for u in SpanishLand.units {
            XCTAssertFalse(u.lessons.isEmpty)
            for l in u.lessons {
                XCTAssertTrue(l.id.hasPrefix("es_"), "\(l.id) not namespaced")
                let playable = !l.letterActivities.isEmpty || !l.words.isEmpty || !l.sentences.isEmpty
                XCTAssertTrue(playable, "\(l.id) has nothing to play")
                XCTAssertTrue(ids.insert(l.id).inserted, "duplicate \(l.id)")
                for L in l.letters { XCTAssertNotNil(SpanishLand.letter(L.letter)) }
            }
        }
    }

    func testSpanishWordsAreDecodable() {
        for u in SpanishLand.wordUnits {
            for l in u.lessons where !l.words.isEmpty {
                for word in l.words {
                    XCTAssertEqual(word.graphemes.map { $0.letters }.joined(), word.text)
                    XCTAssertFalse(word.blendPlan.isEmpty)
                    for g in word.graphemes { XCTAssertNotNil(SpanishPhonics.map[g.letters]) }
                }
            }
        }
    }

    func testSpanishAudioReuse() {
        Languages.setCurrent("es")
        // consonants reuse English; pure vowels a/e/i/o reuse Greek; j (/x/) reuses Greek χ;
        // and the 4 Spanish-only sounds (u, ñ, r, y) are now recorded → every letter is voiced.
        for ipa in ["m", "n", "l", "s", "f", "p", "t", "k", "b", "d", "g",
                    "a", "e", "i", "o", "x", "u", "ɲ", "ɾ", "ʝ"] {
            XCTAssertNotNil(AudioBank.shared.clip(forIPA: ipa), "Spanish /\(ipa)/ has no clip")
        }
    }

    func testSpanishCurriculumSwitch() {
        Languages.setCurrent("es")
        let es = Curriculum.lessonOrder
        XCTAssertFalse(es.isEmpty)
        XCTAssertTrue(es.allSatisfy { $0.hasPrefix("es_") })
    }

    func testRegistry() {
        XCTAssertEqual(Languages.pack("es").nativeName, "Español")
        XCTAssertEqual(Languages.pack("es").ttsLocale, "es-MX")
        XCTAssertGreaterThanOrEqual(Languages.all.count, 6)
        XCTAssertNotEqual(Languages.pack("es").t("great_job"), Languages.pack("en").t("great_job"))
    }
}
