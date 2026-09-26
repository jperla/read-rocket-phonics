import Foundation

/// Starting-point placement: a child who already knows letters (or reads simple
/// words) shouldn't grind through First Sounds. A grown-up picks the level — or
/// a short kid-facing check (≤8 questions) verifies it — and the lessons they
/// placed out of are pre-passed. Pure logic; the UI lives in PlacementView.
enum Placement {
    enum Level {
        case newReader      // start at the very beginning
        case knowsLetters   // skip the letter on-ramp, start at words
        case readsWords     // also skip the first two word units
    }

    /// True for a unit that contains any actual reading (words or sentences).
    private static func isWordUnit(_ u: Unit) -> Bool {
        u.lessons.contains { !$0.words.isEmpty || !$0.sentences.isEmpty }
    }

    /// Lesson ids the child placed out of, for the given (active) curriculum.
    static func lessonsToSkip(level: Level, units: [Unit]) -> [String] {
        switch level {
        case .newReader:
            return []
        case .knowsLetters:
            // Everything before the first unit with real reading in it.
            return Array(units.prefix { !isWordUnit($0) }).flatMap { $0.lessons.map(\.id) }
        case .readsWords:
            // The on-ramp plus the first TWO word units — deliberately
            // conservative: slightly-too-easy beats frustrated-and-quit.
            guard let firstWord = units.firstIndex(where: isWordUnit) else {
                return units.flatMap { $0.lessons.map(\.id) }
            }
            let through = min(units.count, firstWord + 2)
            return units.prefix(through).flatMap { $0.lessons.map(\.id) }
        }
    }

    /// Quiz stage A: `count` letters spread evenly across the alphabet.
    static func letterQuestions(_ pack: LanguagePack, count: Int = 4) -> [Letter] {
        let ls = pack.letters
        guard ls.count > count else { return ls }
        return (0 ..< count).map { ls[$0 * (ls.count - 1) / (count - 1)] }
    }

    /// Quiz stage B: `count` early picture-words from the teaching path
    /// (practice laps and the spelling unit excluded), spread out so they don't
    /// all come from one lesson, with distinct pictures.
    static func wordQuestions(units: [Unit], count: Int = 4) -> [PWord] {
        let words = units.flatMap { $0.lessons }
            .filter { !$0.id.contains("_lap") && !$0.spell }
            .flatMap(\.words)
            .filter { $0.picture != nil }
        guard !words.isEmpty else { return [] }
        var out: [PWord] = []
        var seenText = Set<String>(), seenPic = Set<String>()
        let step = max(1, min(words.count / max(1, count), 8))
        var i = 0
        while out.count < count && i < words.count {
            let w = words[i]
            if seenText.insert(w.text).inserted, let p = w.picture, seenPic.insert(p).inserted {
                out.append(w)
            }
            i += step
        }
        return out
    }
}
