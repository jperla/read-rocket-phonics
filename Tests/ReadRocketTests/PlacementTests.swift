import XCTest
@testable import ReadRocketPhonics

/// Starting-point placement: levels skip progressively more, the first
/// unskipped lesson is real reading, and quiz builders produce sane questions.
final class PlacementTests: XCTestCase {

    override func tearDown() { Languages.setCurrent("en"); super.tearDown() }

    func testLevelsSkipProgressivelyMore() {
        for id in ["en", "en-GB", "el", "es", "fr", "pt", "pt-PT", "de"] {
            Languages.setCurrent(id)
            let units = Curriculum.units
            XCTAssertTrue(Placement.lessonsToSkip(level: .newReader, units: units).isEmpty)
            let letters = Placement.lessonsToSkip(level: .knowsLetters, units: units)
            let words = Placement.lessonsToSkip(level: .readsWords, units: units)
            XCTAssertGreaterThan(letters.count, 10, "\(id): letter on-ramp should be substantial")
            XCTAssertGreaterThan(words.count, letters.count, "\(id): readsWords must skip more")
            // After placing out of letters, the next lesson must be real reading.
            let skipped = Set(letters)
            let next = units.flatMap { $0.lessons }.first { !skipped.contains($0.id) }
            XCTAssertNotNil(next, "\(id)")
            XCTAssertTrue(!(next?.words.isEmpty ?? true) || !(next?.sentences.isEmpty ?? true),
                          "\(id): first unskipped lesson should contain reading, got \(next?.id ?? "-")")
        }
    }

    func testQuizQuestionBuilders() {
        for id in ["en", "el", "de"] {
            Languages.setCurrent(id)
            let ls = Placement.letterQuestions(Languages.active)
            XCTAssertEqual(ls.count, 4, id)
            XCTAssertEqual(Set(ls.map(\.letter)).count, 4, "\(id): letters must be distinct")
            let ws = Placement.wordQuestions(units: Curriculum.units)
            XCTAssertEqual(ws.count, 4, id)
            XCTAssertEqual(Set(ws.map(\.text)).count, 4, "\(id): words must be distinct")
            XCTAssertEqual(Set(ws.compactMap(\.picture)).count, 4, "\(id): pictures must be distinct")
        }
    }

    func testPlaceThroughAwardsStarsWithoutStreakOrWins() {
        let d = UserDefaults(suiteName: "placement.test")!
        d.removePersistentDomain(forName: "placement.test")
        let store = ProfileStore(defaults: d, key: "placement.test.key")
        store.select(ProfileStore.defaultProfiles[0].id)
        let ids = ["u1l1", "u1l2"]
        store.placeThrough(ids)
        XCTAssertTrue(ids.allSatisfy { store.isComplete($0) })
        XCTAssertEqual(store.currentStreak(), 0, "placement must not fake a daily streak")
        XCTAssertEqual(store.tilesRevealed(), 0, "placement must not award poster tiles")
        if let pid = store.currentID {
            XCTAssertFalse(store.placementDone(for: pid))
            store.markPlacementDone(for: pid)
            XCTAssertTrue(store.placementDone(for: pid))
        }
    }
}
