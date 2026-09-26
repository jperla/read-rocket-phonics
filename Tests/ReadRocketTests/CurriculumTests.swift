import XCTest
@testable import ReadRocketPhonics

final class CurriculumTests: XCTestCase {

    func testLessonIDsAreUnique() {
        let ids = Curriculum.allLessons.map { $0.id }
        XCTAssertEqual(Set(ids).count, ids.count, "Duplicate lesson IDs exist")
    }

    func testLessonOrderMatchesAllLessons() {
        XCTAssertEqual(Curriculum.lessonOrder, Curriculum.allLessons.map { $0.id })
    }

    func testUnitLookup() {
        for unit in Curriculum.units {
            for lesson in unit.lessons {
                XCTAssertEqual(Curriculum.unit(forLesson: lesson.id)?.id, unit.id)
            }
        }
    }

    /// Catches data-entry mistakes where the spelled word and its grapheme tiles disagree.
    func testWordTextMatchesGraphemes() {
        for lesson in Curriculum.allLessons {
            for w in lesson.words {
                let joined = w.graphemes.map { $0.letters }.joined()
                XCTAssertEqual(joined, w.text,
                    "Graphemes spell '\(joined)' but word is '\(w.text)' in lesson \(lesson.id)")
            }
        }
    }

    /// Catches typo'd chunk tokens: any silent grapheme must be *intentionally* silent.
    func testNoAccidentalSilentGraphemes() {
        for lesson in Curriculum.allLessons {
            for w in lesson.words {
                for g in w.graphemes where g.ipa == nil {
                    XCTAssertTrue(g.intentionallySilent,
                        "Unknown grapheme '\(g.letters)' in word '\(w.text)' (lesson \(lesson.id))")
                }
            }
        }
    }

    func testEveryWordHasAtLeastOneSound() {
        for lesson in Curriculum.allLessons {
            for w in lesson.words {
                XCTAssertFalse(w.blendPlan.isEmpty, "Word '\(w.text)' has no sounds")
            }
        }
    }

    func testSentencesAreNonEmptyLowercaseWords() {
        for lesson in Curriculum.allLessons {
            for s in lesson.sentences {
                XCTAssertFalse(s.isEmpty, "Empty sentence in \(lesson.id)")
                for word in s {
                    XCTAssertFalse(word.isEmpty)
                    XCTAssertTrue(word.allSatisfy { $0.isLetter },
                        "Sentence word '\(word)' is not all letters in \(lesson.id)")
                }
            }
        }
    }

    func testIntroDetection() {
        func intro(_ id: String) -> Grapheme? {
            Curriculum.allLessons.first { $0.id == id }?.introGrapheme
        }
        XCTAssertNil(intro("u1l1"), "Short-vowel CVC lessons should have no sound intro")
        XCTAssertEqual(intro("u6l1")?.letters, "sh")   // digraph
        XCTAssertEqual(intro("u9l1")?.letters, "ai")   // vowel team
        XCTAssertEqual(intro("u8l1")?.letters, "a")    // magic-e long vowel
        XCTAssertEqual(intro("u10l1")?.letters, "ar")  // r-controlled
    }

    func testIntroIsNeverADoubledConsonant() {
        for lesson in Curriculum.allLessons {
            if let g = lesson.introGrapheme {
                let doubled = g.letters.count == 2 && Set(g.letters).count == 1
                XCTAssertFalse(doubled,
                    "Lesson \(lesson.id) teaches doubled consonant '\(g.letters)' as a new sound")
            }
        }
    }
}
