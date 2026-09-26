import Foundation
import Combine

/// A child's profile. Picked by tapping a friendly animal — no reading required.
struct Profile: Codable, Identifiable, Hashable {
    var id: String
    var name: String
    var emoji: String
}

/// Per-profile progress + persistence (UserDefaults JSON).
final class ProfileStore: ObservableObject {
    @Published var profiles: [Profile]
    @Published var currentID: String?
    /// profileID → (lessonID → stars 1...3)
    @Published private var starsByProfile: [String: [String: Int]]
    @Published private var streakByProfile: [String: Int]
    @Published private var lastDayByProfile: [String: Int]
    /// word → outstanding practice count (spaced repetition); higher = practice more.
    @Published private var reviewByProfile: [String: [String: Int]]
    /// words read correctly with no outstanding review — i.e. mastered.
    @Published private var masteredByProfile: [String: [String]]
    /// Cumulative lesson-completion "wins" per profile (counts replays too, so a
    /// child always makes visible progress). Drives the mosaic poster reveal:
    /// one 4×4 tile per win, a finished 16-tile board = one collected poster.
    @Published private var winsByProfile: [String: Int]
    /// profileID → the language code that profile is currently learning ("en", "el", …).
    /// A child can switch languages; each language is a fully separate world (its own
    /// stars, streak, review queue, and poster gallery — see `sid`).
    @Published private var languageByProfile: [String: String]
    /// profileID → whether the one-time "first blast-off" share moment was offered.
    /// Keyed by the PLAIN profile id (not `sid`): once per child, across languages.
    @Published private var firstShareByProfile: [String: Bool]
    /// sid → whether starting-point placement was handled for that language world.
    @Published private var placementByProfile: [String: Bool]

    private let key: String
    private let defaults: UserDefaults

    struct Saved: Codable {
        var profiles: [Profile]
        var currentID: String?
        var starsByProfile: [String: [String: Int]]
        var streakByProfile: [String: Int]?   // optional → old saves decode fine
        var lastDayByProfile: [String: Int]?
        var reviewByProfile: [String: [String: Int]]?
        var masteredByProfile: [String: [String]]?
        var winsByProfile: [String: Int]?     // optional → old saves decode fine
        var languageByProfile: [String: String]?
        var firstShareByProfile: [String: Bool]?  // optional → old saves decode fine
        var placementByProfile: [String: Bool]?
    }

    init(defaults: UserDefaults = .standard, key: String = "readrocket.store.v1") {
        if AppEnv.uiTesting {
            // Fresh, volatile store on every launch so UI tests always start at
            // the profile picker (no carry-over from a previous run).
            let suite = "readrocket.uitest"
            let d = UserDefaults(suiteName: suite) ?? .standard
            d.removePersistentDomain(forName: suite)
            self.defaults = d
            self.key = key
            profiles = ProfileStore.defaultProfiles
            currentID = nil
            starsByProfile = [:]
            streakByProfile = [:]
            lastDayByProfile = [:]
            reviewByProfile = [:]
            masteredByProfile = [:]
            winsByProfile = [:]
            languageByProfile = [:]
            firstShareByProfile = [:]
            placementByProfile = [:]
            if let n = AppEnv.mosaicWins { profiles.forEach { winsByProfile[$0.id] = n } }
            if let l = AppEnv.forceLanguage { profiles.forEach { languageByProfile[$0.id] = l } }
            return
        }
        self.defaults = defaults
        self.key = key
        if let data = defaults.data(forKey: key),
           let saved = try? JSONDecoder().decode(Saved.self, from: data) {
            profiles = saved.profiles
            currentID = saved.currentID
            starsByProfile = saved.starsByProfile
            streakByProfile = saved.streakByProfile ?? [:]
            lastDayByProfile = saved.lastDayByProfile ?? [:]
            reviewByProfile = saved.reviewByProfile ?? [:]
            masteredByProfile = saved.masteredByProfile ?? [:]
            winsByProfile = saved.winsByProfile ?? [:]
            languageByProfile = saved.languageByProfile ?? [:]
            firstShareByProfile = saved.firstShareByProfile ?? [:]
            placementByProfile = saved.placementByProfile ?? [:]
        } else {
            profiles = ProfileStore.defaultProfiles
            currentID = nil
            starsByProfile = [:]
            streakByProfile = [:]
            lastDayByProfile = [:]
            reviewByProfile = [:]
            masteredByProfile = [:]
            winsByProfile = [:]
            languageByProfile = [:]
            firstShareByProfile = [:]
            placementByProfile = [:]
        }
        if let n = AppEnv.mosaicWins { profiles.forEach { winsByProfile[$0.id] = n } }
        if let l = AppEnv.forceLanguage { profiles.forEach { languageByProfile[$0.id] = l } }
        Languages.setCurrent(AppEnv.forceLanguage ?? currentLanguage)
    }

    static let defaultProfiles: [Profile] = [
        Profile(id: "fox",     name: "Fox",     emoji: "🦊"),
        Profile(id: "bunny",   name: "Bunny",   emoji: "🐰"),
        Profile(id: "bear",    name: "Bear",    emoji: "🐻"),
        Profile(id: "kitty",   name: "Kitty",   emoji: "🐱"),
        Profile(id: "dog",     name: "Dog",     emoji: "🐶"),
        Profile(id: "pig",     name: "Pig",     emoji: "🐷"),
        Profile(id: "frog",    name: "Frog",    emoji: "🐸"),
        Profile(id: "mouse",   name: "Mouse",   emoji: "🐭"),
        Profile(id: "penguin", name: "Penguin", emoji: "🐧"),
        Profile(id: "owl",     name: "Owl",     emoji: "🦉")
    ]

    var current: Profile? { profiles.first { $0.id == currentID } }

    private func save() {
        let saved = Saved(profiles: profiles, currentID: currentID, starsByProfile: starsByProfile,
                          streakByProfile: streakByProfile, lastDayByProfile: lastDayByProfile,
                          reviewByProfile: reviewByProfile, masteredByProfile: masteredByProfile,
                          winsByProfile: winsByProfile, languageByProfile: languageByProfile,
                          firstShareByProfile: firstShareByProfile,
                          placementByProfile: placementByProfile)
        if let data = try? JSONEncoder().encode(saved) {
            defaults.set(data, forKey: key)
        }
    }

    func select(_ id: String) { currentID = id; Languages.setCurrent(currentLanguage); save() }

    // MARK: - Language (a child can learn multiple languages, each fully separate)

    /// The language the given profile is currently learning.
    func language(for pid: String) -> String { languageByProfile[pid] ?? "en" }
    /// The active profile's current language ("en" if none chosen).
    var currentLanguage: String { currentID.map { language(for: $0) } ?? "en" }
    /// Switch the active profile to another language — its own separate stars, streak,
    /// review queue, and poster gallery.
    func setLanguage(_ code: String) {
        guard let pid = currentID else { return }
        languageByProfile[pid] = code
        Languages.setCurrent(code)
        save()
    }

    /// Storage id that namespaces a profile's progress by its active language, so each
    /// language is an independent world. English keeps the bare profile id (preserves
    /// existing saves); other languages get a "pid#lang" bucket.
    private func sid(_ pid: String) -> String {
        let l = languageByProfile[pid] ?? "en"
        return l == "en" ? pid : "\(pid)#\(l)"
    }
    func rename(_ id: String, to name: String) {
        if let i = profiles.firstIndex(where: { $0.id == id }) {
            profiles[i].name = name.isEmpty ? profiles[i].name : name
            save()
        }
    }

    // MARK: - Progress

    func stars(_ lessonID: String) -> Int {
        guard let pid = currentID else { return 0 }
        return starsByProfile[sid(pid)]?[lessonID] ?? 0
    }

    func isComplete(_ lessonID: String) -> Bool { stars(lessonID) > 0 }

    func record(_ lessonID: String, stars: Int, today: Int = ProfileStore.dayNumber(Date())) {
        guard let pid = currentID else { return }
        var map = starsByProfile[sid(pid)] ?? [:]
        map[lessonID] = max(map[lessonID] ?? 0, stars)
        starsByProfile[sid(pid)] = map
        // Daily streak: bump on the first play each day; reset after a missed day.
        streakByProfile[sid(pid)] = ProfileStore.nextStreak(todayDay: today,
                                                       lastDay: lastDayByProfile[sid(pid)],
                                                       current: streakByProfile[sid(pid)] ?? 0)
        lastDayByProfile[sid(pid)] = today
        save()
    }

    // MARK: - Word mastery (spaced repetition)

    /// Record one word attempt. A miss queues the word for review (and un-masters
    /// it); a hit reduces its review need and, once cleared, marks it mastered.
    func recordWordResult(_ word: String, correct: Bool) {
        guard let pid = currentID else { return }
        var review = reviewByProfile[sid(pid)] ?? [:]
        var mastered = Set(masteredByProfile[sid(pid)] ?? [])
        if correct {
            if let c = review[word] {
                let n = c - 1
                if n <= 0 { review[word] = nil; mastered.insert(word) } else { review[word] = n }
            } else {
                mastered.insert(word)
            }
        } else {
            mastered.remove(word)
            review[word] = min(3, (review[word] ?? 0) + 2)
        }
        reviewByProfile[sid(pid)] = review
        masteredByProfile[sid(pid)] = Array(mastered)
        save()
    }

    /// Up to `limit` words currently due for review, most-needed first.
    func reviewWords(limit: Int) -> [String] {
        guard let pid = currentID, let review = reviewByProfile[sid(pid)] else { return [] }
        return review.sorted { $0.value > $1.value }.prefix(limit).map { $0.key }
    }

    /// A small random sample of ALREADY-MASTERED items (letters/words), excluding
    /// anything currently in the review queue — for cumulative, interleaved
    /// retrieval warm-ups (research: spaced + cumulative practice of learned items,
    /// not only the missed ones). Empty under UI testing (fresh volatile store).
    func masteredSample(limit: Int, excluding: Set<String> = []) -> [String] {
        guard let pid = currentID else { return [] }
        let due = Set((reviewByProfile[sid(pid)] ?? [:]).keys)
        let pool = (masteredByProfile[sid(pid)] ?? []).filter { !due.contains($0) && !excluding.contains($0) }
        return Array(pool.shuffled().prefix(limit))
    }

    func masteredCount(for pid: String) -> Int { (masteredByProfile[sid(pid)] ?? []).count }
    func masteredCount() -> Int { currentID.map { masteredCount(for: $0) } ?? 0 }
    func practicingCount(for pid: String) -> Int { (reviewByProfile[sid(pid)] ?? [:]).count }
    func practicingCount() -> Int { currentID.map { practicingCount(for: $0) } ?? 0 }

    /// ONE flow, ONE next: everything up to and including the first not-yet-
    /// completed lesson is open (so finished lessons can always be replayed),
    /// and everything past it stays locked. No daily what-should-we-do choice —
    /// the single highlighted next lesson IS the plan.
    func isUnlocked(_ lessonID: String, order: [String]) -> Bool {
        if AppEnv.uiTesting { return true }   // e2e can open any lesson directly
        guard let i = order.firstIndex(of: lessonID) else { return false }
        return i <= currentLessonIndex(order: order)
    }

    /// The index of the lesson the child should play next (first not-complete).
    func currentLessonIndex(order: [String]) -> Int {
        order.firstIndex { !isComplete($0) } ?? max(0, order.count - 1)
    }

    func totalStars(for pid: String) -> Int {
        (starsByProfile[sid(pid)] ?? [:]).values.reduce(0, +)
    }
    func totalStars() -> Int { currentID.map { totalStars(for: $0) } ?? 0 }

    // MARK: - Mosaic posters (long-horizon reward)
    //
    // Replaces the old "a sticker every 2 lessons" pacing (which filled a 16-slot
    // book in a few sessions and then dead-ended). Now each win reveals ONE tile
    // of a 4×4 board over a hidden hand-drawn scene; a finished 16-tile board = one
    // collected poster — a rarer, bigger payoff — and there's always a next scene
    // to chip away at, so the gallery never "fills up".

    static let tilesPerPoster = 16          // a 4×4 board
    static var posterCount: Int { PosterScene.all.count }

    /// Number of distinct lessons a profile has completed (any star count).
    func completedCount(for pid: String) -> Int {
        (starsByProfile[sid(pid)] ?? [:]).values.filter { $0 > 0 }.count
    }
    func completedCount() -> Int { currentID.map { completedCount(for: $0) } ?? 0 }

    /// Cumulative wins (lesson completions, replays included → always progressing).
    func totalWins(for pid: String) -> Int { winsByProfile[sid(pid)] ?? 0 }
    func totalWins() -> Int { currentID.map { totalWins(for: $0) } ?? 0 }

    /// Record one completed lesson (a "win"): advances the mosaic by one tile.
    /// Returns true if this win COMPLETED a 16-tile poster.
    @discardableResult
    func recordWin(for pid: String) -> Bool {
        let n = (winsByProfile[sid(pid)] ?? 0) + 1
        winsByProfile[sid(pid)] = n
        save()
        return n % ProfileStore.tilesPerPoster == 0
    }
    @discardableResult
    func recordWin() -> Bool { currentID.map { recordWin(for: $0) } ?? false }

    /// Posters fully revealed so far.
    func postersCollected(for pid: String) -> Int {
        (winsByProfile[sid(pid)] ?? 0) / ProfileStore.tilesPerPoster
    }
    func postersCollected() -> Int { currentID.map { postersCollected(for: $0) } ?? 0 }

    /// Tiles revealed on the current in-progress board (0...15).
    func tilesRevealed(for pid: String) -> Int {
        (winsByProfile[sid(pid)] ?? 0) % ProfileStore.tilesPerPoster
    }
    func tilesRevealed() -> Int { currentID.map { tilesRevealed(for: $0) } ?? 0 }

    /// Index into `PosterScene.all` of the board currently being revealed (cycles
    /// once every scene has been collected, so there's always a board in progress).
    func currentPosterIndex(for pid: String) -> Int {
        guard ProfileStore.posterCount > 0 else { return 0 }
        return postersCollected(for: pid) % ProfileStore.posterCount
    }
    func currentPosterIndex() -> Int { currentID.map { currentPosterIndex(for: $0) } ?? 0 }

    /// Index of the poster JUST completed by the most recent win (valid right after
    /// `recordWin` returns true). Nil if the last win didn't finish a board.
    func justCompletedPosterIndex(for pid: String) -> Int? {
        let n = winsByProfile[sid(pid)] ?? 0
        guard n > 0, n % ProfileStore.tilesPerPoster == 0, ProfileStore.posterCount > 0 else { return nil }
        return (n / ProfileStore.tilesPerPoster - 1) % ProfileStore.posterCount
    }
    func justCompletedPosterIndex() -> Int? { currentID.flatMap { justCompletedPosterIndex(for: $0) } }

    /// The unit title of the next not-yet-completed lesson for a profile.
    func currentUnitTitle(for pid: String) -> String {
        let order = Curriculum.lessonOrder
        let idx = order.firstIndex { (starsByProfile[sid(pid)]?[$0] ?? 0) == 0 } ?? max(0, order.count - 1)
        let lid = order[min(idx, order.count - 1)]
        return Curriculum.unit(forLesson: lid)?.title ?? ""
    }

    // MARK: - First blast-off share moment (word of mouth)
    //
    // Offered exactly once per CHILD (plain profile id, across languages): on the
    // celebration after the first lesson they ever complete. The flag is marked at
    // offer time, so the button can stay up for that whole celebration but never
    // returns on a later one.

    /// Whether a child has ANY recorded progress in ANY language world. The
    /// "first-ever blast-off" must be first across languages, not per `sid`
    /// world — a language switch starts a fresh world with zeroed counts.
    func hasAnyProgress(for pid: String) -> Bool {
        let prefix = "\(pid)#"
        let mine: (String) -> Bool = { $0 == pid || $0.hasPrefix(prefix) }
        if winsByProfile.contains(where: { mine($0.key) && $0.value > 0 }) { return true }
        return starsByProfile.contains { mine($0.key) && $0.value.values.contains { $0 > 0 } }
    }

    /// Whether the one-time share moment has already been offered for a child.
    func firstShareOffered(for pid: String) -> Bool { firstShareByProfile[pid] ?? false }

    /// Mark the share moment offered — it never shows again for this child.
    func markFirstShareOffered(for pid: String) {
        firstShareByProfile[pid] = true
        save()
    }

    // MARK: - Starting-point placement (per language world)

    /// Whether placement was handled for this child IN THIS LANGUAGE world.
    func placementDone(for pid: String) -> Bool { placementByProfile[sid(pid)] ?? false }

    func markPlacementDone(for pid: String) {
        placementByProfile[sid(pid)] = true
        save()
    }

    /// True once this language world has any recorded stars — placement is moot
    /// (covers profiles that predate the placement feature).
    func worldStarted(for pid: String) -> Bool { !(starsByProfile[sid(pid)] ?? [:]).isEmpty }

    /// Pre-pass lessons the child placed out of: 1★ each (passed, not "perfect"),
    /// with NO streak/win/SRS side effects — placement isn't playing.
    func placeThrough(_ ids: [String]) {
        guard let pid = currentID, !ids.isEmpty else { return }
        var map = starsByProfile[sid(pid)] ?? [:]
        for id in ids { map[id] = max(map[id] ?? 0, 1) }
        starsByProfile[sid(pid)] = map
        save()
    }

    // MARK: - Daily streak

    /// Absolute day index (consecutive calendar days differ by 1; DST/timezone-safe).
    static func dayNumber(_ date: Date) -> Int {
        Calendar.current.ordinality(of: .day, in: .era, for: date) ?? 0
    }

    /// Pure streak rule (unit-tested with injected day numbers).
    static func nextStreak(todayDay: Int, lastDay: Int?, current: Int) -> Int {
        guard let last = lastDay else { return 1 }      // first ever play
        if todayDay <= last { return max(current, 1) }  // same day (or clock moved back): keep
        if todayDay == last + 1 { return current + 1 }  // consecutive day
        return 1                                        // missed a day: restart
    }

    /// The streak to show now — 0 if a day was missed since the last play.
    func currentStreak(for pid: String, today: Int = ProfileStore.dayNumber(Date())) -> Int {
        guard let last = lastDayByProfile[sid(pid)] else { return 0 }
        if today == last || today == last + 1 { return streakByProfile[sid(pid)] ?? 0 }
        return 0
    }
    func currentStreak() -> Int { currentID.map { currentStreak(for: $0) } ?? 0 }

    /// Whether today's goal (≥1 lesson) is already met for a profile.
    func goalMetToday(for pid: String, today: Int = ProfileStore.dayNumber(Date())) -> Bool {
        lastDayByProfile[sid(pid)] == today
    }
}
