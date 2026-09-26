import XCTest
@testable import ReadRocketPhonics

final class GreekLandTests: XCTestCase {

    override func tearDown() {
        Languages.setCurrent("en")   // never leak Greek into other tests
        super.tearDown()
    }

    func testGreekAlphabetIsComplete() {
        XCTAssertEqual(GreekLand.letters.count, 24)
        for L in GreekLand.letters {
            XCTAssertFalse(L.ipa.isEmpty, "\(L.letter) has no IPA")
            XCTAssertFalse(L.picture.isEmpty, "\(L.letter) has no picture")
            XCTAssertFalse(L.keyword.isEmpty, "\(L.letter) has no keyword")
        }
        // Distinct letters (no accidental dupes).
        XCTAssertEqual(Set(GreekLand.letters.map { $0.letter }).count, 24)
    }

    func testGreekUnitsArePlayableAndNamespaced() {
        var ids = Set<String>()
        for u in GreekLand.units {
            XCTAssertFalse(u.lessons.isEmpty, "unit \(u.id) empty")
            for l in u.lessons {
                XCTAssertTrue(l.id.hasPrefix("el_"), "lesson \(l.id) not namespaced")
                // Playable = a letter lesson with activities OR a word/sentence lesson.
                let playable = !l.letterActivities.isEmpty || !l.words.isEmpty || !l.sentences.isEmpty
                XCTAssertTrue(playable, "lesson \(l.id) has nothing to play")
                XCTAssertTrue(ids.insert(l.id).inserted, "duplicate lesson id \(l.id)")
                // Every letter referenced must resolve in the Greek alphabet.
                for L in l.letters { XCTAssertNotNil(GreekLand.letter(L.letter)) }
            }
        }
    }

    func testGreekWordsAreDecodable() {
        for u in GreekLand.wordUnits {
            for l in u.lessons {
                for word in l.words {
                    // graphemes must spell the word exactly…
                    XCTAssertEqual(word.graphemes.map { $0.letters }.joined(), word.text,
                                   "graphemes don't spell \(word.text)")
                    // …and every grapheme must have a known Greek sound.
                    for g in word.graphemes {
                        XCTAssertNotNil(GreekPhonics.map[g.letters], "no sound for '\(g.letters)' in \(word.text)")
                        XCTAssertFalse(word.blendPlan.isEmpty)
                    }
                }
            }
        }
    }

    func testActiveLanguageSwitchesCurriculum() {
        Languages.setCurrent("en")
        let en = Curriculum.lessonOrder
        XCTAssertTrue(en.contains { !$0.hasPrefix("el_") })
        Languages.setCurrent("el")
        let el = Curriculum.lessonOrder
        XCTAssertFalse(el.isEmpty)
        XCTAssertTrue(el.allSatisfy { $0.hasPrefix("el_") }, "Greek curriculum should be all el_ lessons")
        XCTAssertNotEqual(en, el)
    }

    func testGreekAudioResolves() {
        Languages.setCurrent("el")
        // shared sounds reuse the user's English recordings…
        for ipa in ["m", "n", "l", "s", "z", "f", "v", "p", "t", "k", "r", "ks"] {
            XCTAssertNotNil(AudioBank.shared.clip(forIPA: ipa), "no reused English clip for Greek /\(ipa)/")
        }
        // …Greek-specific sounds use the bundled Greek recordings.
        for ipa in ["a", "e", "i", "o", "θ", "ð", "x", "ɣ", "ps"] {
            XCTAssertNotNil(AudioBank.shared.clip(forIPA: ipa), "no Greek recording for /\(ipa)/")
        }
    }

    func testPackRegistry() {
        XCTAssertEqual(Languages.pack("el").nativeName, "Ελληνικά")
        XCTAssertEqual(Languages.pack("el").ttsLocale, "el-GR")
        XCTAssertEqual(Languages.pack("en").id, "en")
        XCTAssertEqual(Languages.pack("zz").id, "en")   // unknown → English fallback
        // Greek immersion strings differ from English.
        XCTAssertNotEqual(Languages.pack("el").t("great_job"), Languages.pack("en").t("great_job"))
    }
}
