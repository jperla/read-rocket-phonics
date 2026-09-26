import XCTest
@testable import ReadRocketPhonics

/// Integrity for every non-English pack (Greek, Spanish, French, Portuguese,
/// German), driven generically through the registry + active-language curriculum.
final class LanguagePacksTests: XCTestCase {

    override func tearDown() { Languages.setCurrent("en"); super.tearDown() }

    private var packs: [LanguagePack] { Languages.all.filter { $0.id != "en" } }

    func testRegistryHasEightLanguages() {
        XCTAssertEqual(Languages.all.count, 8)
        XCTAssertEqual(Set(Languages.all.map { $0.id }), ["en", "en-GB", "el", "es", "fr", "pt", "pt-PT", "de"])
        for p in packs {
            XCTAssertFalse(p.nativeName.isEmpty)
            XCTAssertFalse(p.ttsLocale.isEmpty)
            // English-family packs (en-GB) legitimately share the English UI strings.
            guard !p.id.hasPrefix("en") else { continue }
            XCTAssertNotEqual(p.t("great_job"), "great_job", "\(p.id) missing great_job string")
            XCTAssertNotEqual(p.t("drag_sound"), Languages.pack("en").t("drag_sound"), "\(p.id) drag_sound not localized")
            XCTAssertNotEqual(p.t("hi_lets_read"), Languages.pack("en").t("hi_lets_read"), "\(p.id) greeting not localized")
            XCTAssertTrue(p.t("hi_lets_read").contains("%@"), "\(p.id) greeting must keep the name placeholder")
        }
    }

    func testAlphabetsComplete() {
        for p in packs {
            XCTAssertGreaterThanOrEqual(p.letters.count, 20, "\(p.id) too few letters")
            XCTAssertEqual(Set(p.letters.map { $0.letter }).count, p.letters.count, "\(p.id) duplicate letters")
            for L in p.letters {
                XCTAssertFalse(L.ipa.isEmpty, "\(p.id)/\(L.letter) no IPA")
                XCTAssertFalse(L.keyword.isEmpty, "\(p.id)/\(L.letter) no keyword")
                XCTAssertFalse(L.picture.isEmpty, "\(p.id)/\(L.letter) no picture")
            }
        }
    }

    func testEachLanguageCurriculumIsPlayableAndNamespaced() {
        for p in packs {
            Languages.setCurrent(p.id)
            var ids = Set<String>()
            let order = Curriculum.lessonOrder
            XCTAssertFalse(order.isEmpty, "\(p.id) empty curriculum")
            XCTAssertTrue(order.allSatisfy { $0.hasPrefix("\(p.id)_") }, "\(p.id) lesson ids not namespaced")
            for u in Curriculum.units {
                for l in u.lessons {
                    XCTAssertTrue(ids.insert(l.id).inserted, "\(p.id) duplicate lesson id \(l.id)")
                    let playable = !l.letterActivities.isEmpty || !l.words.isEmpty || !l.sentences.isEmpty
                    XCTAssertTrue(playable, "\(p.id) lesson \(l.id) has nothing to play")
                }
            }
        }
    }

    /// Mnemonics must be keyed by a SINGLE taught letter — LanguagePack.mnemonic(_:)
    /// is looked up with L.letter, so a compound key like "f / v" is silently dead
    /// data. (Three packs shipped with 100% unreachable mnemonics before this guard.)
    func testMnemonicKeysAreTaughtLettersAndReversiblesCovered() {
        for p in Languages.all {
            let taught = Set(p.letters.map { $0.letter })
            for key in p.mnemonics.keys {
                XCTAssertTrue(taught.contains(key),
                              "\(p.id) mnemonic key '\(key)' is not a single taught letter — it can never play")
            }
            // Every reversible letter gets 5× trace reps specifically for confusion
            // prevention — each one should come with its spoken shape mnemonic.
            for r in p.reversible {
                XCTAssertNotNil(p.mnemonic(r), "\(p.id) reversible letter '\(r)' has no mnemonic")
            }
        }
    }

    /// Generated drill: every word unit gets practice laps (repeat + cumulative
    /// mix), and the curriculum ends with a spelling unit. lapB must actually
    /// interleave EARLIER units' words — that's the whole point of it.
    func testPracticeLapsAndSpellingGenerated() {
        for p in packs where !p.id.hasPrefix("en") {
            Languages.setCurrent(p.id)
            let units = Curriculum.units
            let lapAs = units.flatMap { $0.lessons }.filter { $0.id.contains("_lapA") }
            let lapBs = units.flatMap { $0.lessons }.filter { $0.id.hasSuffix("_lapB") }
            XCTAssertFalse(lapAs.isEmpty, "\(p.id) has no practice laps")
            XCTAssertFalse(lapBs.isEmpty, "\(p.id) has no mix laps")
            XCTAssertTrue(units.contains { $0.id.hasSuffix("_spell") }, "\(p.id) missing spelling unit")
            XCTAssertTrue(units.last?.id.hasSuffix("_spell") ?? false, "\(p.id) spelling unit must be LAST")
            for spell in (units.last?.lessons ?? []) {
                XCTAssertTrue(spell.spell, "\(p.id) spelling lesson \(spell.id) not in spell mode")
            }
            // Cross-unit interleaving: some lapB word must come from outside its unit.
            for u in units where u.lessons.contains(where: { $0.id.hasSuffix("_lapB") }) {
                let own = Set(u.lessons.filter { !$0.id.contains("_lap") }.flatMap { $0.words.map(\.text) })
                let lapB = u.lessons.first { $0.id.hasSuffix("_lapB") }!
                XCTAssertTrue(lapB.words.contains { !own.contains($0.text) },
                              "\(p.id) \(lapB.id) doesn't mix in earlier units' words")
                break   // one unit with a lapB is enough per pack
            }
        }
    }

    /// "Today's Review" builds a lesson from the child's own word history.
    func testDailyReviewLessonGeneration() {
        XCTAssertNil(Curriculum.dailyReview(missed: ["cat"], mastered: []), "needs ≥3 words")
        XCTAssertNil(Curriculum.dailyReview(missed: ["xyzzy", "blorp"], mastered: ["zzz"]),
                     "unknown words must filter out")
        let l = Curriculum.dailyReview(missed: ["cat", "hat"], mastered: ["bat"])
        XCTAssertEqual(l?.id, "daily_review")
        XCTAssertEqual(l?.words.map(\.text), ["cat", "hat", "bat"], "missed words come first")
        XCTAssertFalse(l?.spell ?? true, "review drills reading, not spelling")
    }

    /// A Greek voice spells Latin names letter-by-letter ("c-h-l-o-e"), so the
    /// greeting picks a script-matched voice for the NAME segment only.
    func testGreetingNameVoiceMatchesScript() {
        XCTAssertEqual(SpeechManager.nameVoiceLocale(for: "Chloe", active: "el-GR"), "en-US")
        XCTAssertNil(SpeechManager.nameVoiceLocale(for: "Χλόη", active: "el-GR"))
        XCTAssertEqual(SpeechManager.nameVoiceLocale(for: "Χλόη", active: "en-US"), "el-GR")
        XCTAssertNil(SpeechManager.nameVoiceLocale(for: "Chloe", active: "en-US"))
        XCTAssertNil(SpeechManager.nameVoiceLocale(for: "Chloé", active: "fr-FR"))
    }

    func testEachLanguageWordsAreDecodable() {
        for p in packs {
            Languages.setCurrent(p.id)
            for l in Curriculum.allLessons where !l.words.isEmpty {
                for word in l.words {
                    XCTAssertEqual(word.graphemes.map { $0.letters }.joined(), word.text,
                                   "\(p.id): graphemes don't spell \(word.text)")
                    XCTAssertFalse(word.blendPlan.isEmpty, "\(p.id): \(word.text) has no sounds")
                }
            }
        }
    }
}
