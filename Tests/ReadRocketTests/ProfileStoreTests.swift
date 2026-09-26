import XCTest
@testable import ReadRocketPhonics

final class ProfileStoreTests: XCTestCase {

    private func isolated() -> (ProfileStore, UserDefaults, String) {
        let suite = "test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        return (ProfileStore(defaults: defaults, key: "k"), defaults, suite)
    }

    func testDefaultsFreshStore() {
        let (store, defaults, suite) = isolated()
        defer { defaults.removePersistentDomain(forName: suite) }
        XCTAssertEqual(store.profiles.count, ProfileStore.defaultProfiles.count)
        XCTAssertGreaterThanOrEqual(store.profiles.count, 10)
        XCTAssertNil(store.currentID)
        XCTAssertEqual(store.totalStars(), 0)
    }

    func testUnlockProgressionIsStrictlyLinear() {
        let (store, defaults, suite) = isolated()
        defer { defaults.removePersistentDomain(forName: suite) }
        store.select("fox")
        let order = Curriculum.lessonOrder
        // ONE flow, ONE next: only the first incomplete lesson is open ahead.
        XCTAssertTrue(store.isUnlocked(order[0], order: order))
        XCTAssertFalse(store.isUnlocked(order[1], order: order))
        XCTAssertFalse(store.isUnlocked(order[5], order: order))
        // Completing the first opens exactly the second…
        store.record(order[0], stars: 3)
        XCTAssertTrue(store.isUnlocked(order[1], order: order))
        XCTAssertFalse(store.isUnlocked(order[2], order: order))
        // …and finished lessons stay replayable.
        XCTAssertTrue(store.isUnlocked(order[0], order: order))
        XCTAssertEqual(store.currentLessonIndex(order: order), 1)
        // Placement pre-stars move the frontier the same way.
        store.placeThrough(Array(order.prefix(10)))
        XCTAssertTrue(store.isUnlocked(order[10], order: order))
        XCTAssertFalse(store.isUnlocked(order[11], order: order))
    }

    func testWordMasteryAndReviewQueue() {
        let (store, defaults, suite) = isolated()
        defer { defaults.removePersistentDomain(forName: suite) }
        store.select("fox")
        // A miss queues the word for review and it's not mastered.
        store.recordWordResult("cat", correct: false)
        XCTAssertTrue(store.reviewWords(limit: 5).contains("cat"))
        XCTAssertEqual(store.practicingCount(), 1)
        XCTAssertEqual(store.masteredCount(), 0)
        // It takes two clean hits to clear a missed word, then it's mastered.
        store.recordWordResult("cat", correct: true)
        XCTAssertTrue(store.reviewWords(limit: 5).contains("cat"))   // one practice left
        store.recordWordResult("cat", correct: true)
        XCTAssertFalse(store.reviewWords(limit: 5).contains("cat"))  // cleared
        XCTAssertEqual(store.masteredCount(), 1)
        XCTAssertEqual(store.practicingCount(), 0)
        // A first-try-correct word is mastered immediately.
        store.recordWordResult("dog", correct: true)
        XCTAssertEqual(store.masteredCount(), 2)
    }

    func testStarsAreMaxedNotOverwritten() {
        let (store, defaults, suite) = isolated()
        defer { defaults.removePersistentDomain(forName: suite) }
        store.select("fox")
        let id = Curriculum.lessonOrder[0]
        store.record(id, stars: 2)
        store.record(id, stars: 1)
        XCTAssertEqual(store.stars(id), 2)
        store.record(id, stars: 3)
        XCTAssertEqual(store.stars(id), 3)
    }

    func testStarsArePerProfile() {
        let (store, defaults, suite) = isolated()
        defer { defaults.removePersistentDomain(forName: suite) }
        let id = Curriculum.lessonOrder[0]
        store.select("fox"); store.record(id, stars: 3)
        store.select("bunny"); store.record(id, stars: 1)
        XCTAssertEqual(store.totalStars(), 1)        // bunny current
        store.select("fox")
        XCTAssertEqual(store.totalStars(), 3)        // fox current
    }

    func testPersistenceRoundTrip() {
        let suite = "test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        do {
            let s = ProfileStore(defaults: defaults, key: "k")
            s.select("bear")
            s.record(Curriculum.lessonOrder[0], stars: 2)
        }
        let reloaded = ProfileStore(defaults: defaults, key: "k")
        XCTAssertEqual(reloaded.currentID, "bear")
        XCTAssertEqual(reloaded.stars(Curriculum.lessonOrder[0]), 2)
    }

    func testRenameIgnoresEmpty() {
        let (store, defaults, suite) = isolated()
        defer { defaults.removePersistentDomain(forName: suite) }
        store.rename("fox", to: "Zoe")
        XCTAssertEqual(store.profiles.first { $0.id == "fox" }?.name, "Zoe")
        store.rename("fox", to: "")
        XCTAssertEqual(store.profiles.first { $0.id == "fox" }?.name, "Zoe")
    }

    func testMosaicProgress() {
        let (store, defaults, suite) = isolated()
        defer { defaults.removePersistentDomain(forName: suite) }
        store.select("fox")
        XCTAssertEqual(store.totalWins(), 0)
        XCTAssertEqual(store.tilesRevealed(), 0)
        XCTAssertEqual(store.postersCollected(), 0)
        XCTAssertNil(store.justCompletedPosterIndex())

        // First win peels one tile; no poster completed yet.
        XCTAssertFalse(store.recordWin())
        XCTAssertEqual(store.tilesRevealed(), 1)
        XCTAssertEqual(store.postersCollected(), 0)

        // Fill up to the 15th tile…
        for _ in 0..<(ProfileStore.tilesPerPoster - 2) { XCTAssertFalse(store.recordWin()) }
        XCTAssertEqual(store.tilesRevealed(), 15)
        XCTAssertNil(store.justCompletedPosterIndex())

        // …the 16th tile completes the board (a rare, big reward).
        XCTAssertTrue(store.recordWin())
        XCTAssertEqual(store.postersCollected(), 1)
        XCTAssertEqual(store.tilesRevealed(), 0)                 // next board starts fresh
        XCTAssertEqual(store.justCompletedPosterIndex(), 0)
        XCTAssertEqual(store.currentPosterIndex(), 1 % ProfileStore.posterCount)
    }

    func testWinsArePerProfileAndPersist() {
        let suite = "test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        do {
            let s = ProfileStore(defaults: defaults, key: "k")
            s.select("fox"); s.recordWin(); s.recordWin()
            s.select("bunny"); s.recordWin()
        }
        let reloaded = ProfileStore(defaults: defaults, key: "k")
        XCTAssertEqual(reloaded.totalWins(for: "fox"), 2)
        XCTAssertEqual(reloaded.totalWins(for: "bunny"), 1)
        XCTAssertEqual(reloaded.totalWins(for: "bear"), 0)
    }

    func testProgressSeparatesByLanguage() {
        let (store, defaults, suite) = isolated()
        defer { defaults.removePersistentDomain(forName: suite) }
        store.select("fox")
        XCTAssertEqual(store.currentLanguage, "en")          // default
        let id = Curriculum.lessonOrder[0]
        store.record(id, stars: 3); store.recordWin()
        XCTAssertEqual(store.stars(id), 3)
        XCTAssertEqual(store.totalWins(), 1)
        // Switch the SAME child to Greek → a fresh, fully separate world.
        store.setLanguage("el")
        XCTAssertEqual(store.currentLanguage, "el")
        XCTAssertEqual(store.stars(id), 0)                    // Greek progress is its own
        XCTAssertEqual(store.totalWins(), 0)
        store.record(id, stars: 2); store.recordWin(); store.recordWin()
        XCTAssertEqual(store.totalWins(), 2)
        // Back to English → the original progress is intact.
        store.setLanguage("en")
        XCTAssertEqual(store.stars(id), 3)
        XCTAssertEqual(store.totalWins(), 1)
    }

    func testPerProfileSummary() {
        let (store, defaults, suite) = isolated()
        defer { defaults.removePersistentDomain(forName: suite) }
        let order = Curriculum.lessonOrder
        store.select("fox"); store.record(order[0], stars: 3); store.record(order[1], stars: 2)
        store.select("bunny"); store.record(order[0], stars: 1)
        XCTAssertEqual(store.completedCount(for: "fox"), 2)
        XCTAssertEqual(store.totalStars(for: "fox"), 5)
        XCTAssertEqual(store.completedCount(for: "bunny"), 1)
        XCTAssertEqual(store.totalStars(for: "bunny"), 1)
        XCTAssertEqual(store.completedCount(for: "bear"), 0)
        XCTAssertFalse(store.currentUnitTitle(for: "fox").isEmpty)
    }

    func testStreakRule() {
        XCTAssertEqual(ProfileStore.nextStreak(todayDay: 100, lastDay: nil, current: 0), 1)
        XCTAssertEqual(ProfileStore.nextStreak(todayDay: 100, lastDay: 100, current: 3), 3) // same day
        XCTAssertEqual(ProfileStore.nextStreak(todayDay: 101, lastDay: 100, current: 3), 4) // consecutive
        XCTAssertEqual(ProfileStore.nextStreak(todayDay: 103, lastDay: 100, current: 3), 1) // missed a day
    }

    func testStreakThroughRecord() {
        let (store, defaults, suite) = isolated()
        defer { defaults.removePersistentDomain(forName: suite) }
        store.select("fox")
        let order = Curriculum.lessonOrder
        store.record(order[0], stars: 3, today: 100)
        XCTAssertEqual(store.currentStreak(for: "fox", today: 100), 1)
        XCTAssertTrue(store.goalMetToday(for: "fox", today: 100))
        store.record(order[1], stars: 2, today: 101)
        XCTAssertEqual(store.currentStreak(for: "fox", today: 101), 2)
        store.record(order[2], stars: 1, today: 101)                    // same day again: no bump
        XCTAssertEqual(store.currentStreak(for: "fox", today: 101), 2)
        XCTAssertEqual(store.currentStreak(for: "fox", today: 103), 0)  // missed a day → shows 0
        XCTAssertFalse(store.goalMetToday(for: "fox", today: 103))
        store.record(order[3], stars: 1, today: 103)                    // gap → restart at 1
        XCTAssertEqual(store.currentStreak(for: "fox", today: 103), 1)
    }

    /// Old saved data (no streak/lastDay keys) must still decode — never wipe progress.
    func testDecodesOldSaveWithoutStreakFields() {
        let suite = "test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let oldJSON = #"{"profiles":[{"id":"fox","name":"Fox","emoji":"🦊"}],"currentID":"fox","starsByProfile":{"fox":{"u1l1":3}}}"#
        defaults.set(Data(oldJSON.utf8), forKey: "k")
        let store = ProfileStore(defaults: defaults, key: "k")
        XCTAssertEqual(store.currentID, "fox")               // not wiped
        XCTAssertEqual(store.stars("u1l1"), 3)               // stars preserved
        XCTAssertEqual(store.currentStreak(for: "fox", today: 100), 0)  // streak defaults cleanly
        XCTAssertEqual(store.totalWins(for: "fox"), 0)       // new mosaic field defaults to 0
        XCTAssertFalse(store.firstShareOffered(for: "fox"))  // new share flag defaults to false
    }

    /// The one-time "first blast-off" share flag persists, is per child, and is
    /// keyed by the PLAIN profile id — switching languages must not re-offer it.
    func testFirstShareOfferedPersistsPerProfile() {
        let suite = "test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        do {
            let s = ProfileStore(defaults: defaults, key: "k")
            XCTAssertFalse(s.firstShareOffered(for: "fox"))
            s.markFirstShareOffered(for: "fox")
            XCTAssertTrue(s.firstShareOffered(for: "fox"))
        }
        let reloaded = ProfileStore(defaults: defaults, key: "k")
        XCTAssertTrue(reloaded.firstShareOffered(for: "fox"))
        XCTAssertFalse(reloaded.firstShareOffered(for: "bunny"))
        reloaded.select("fox")
        reloaded.setLanguage("el")                           // fresh Greek world…
        XCTAssertTrue(reloaded.firstShareOffered(for: "fox")) // …but the moment stays spent
    }
}
