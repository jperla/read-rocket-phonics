import Foundation

/// Discrimination-review lessons: the bridge between learning single letters and
/// reading words. Each lesson focuses on ONE activity type repeated across many
/// already-taught letters (Mentava-style: kids improve by repeating the same
/// activity within a lesson — variety lives between lessons, not inside one).
/// Language-agnostic (works for any pack).
enum ReviewLessons {
    /// A review unit covering `letters`: for each chunk, one drag-the-sound
    /// lesson and one hear→tap lesson — homogeneous within each lesson.
    static func unit(id: String, title: String, letters: [Letter], perLesson: Int = 5) -> Unit {
        let groups = stride(from: 0, to: letters.count, by: perLesson).map {
            Array(letters[$0 ..< min($0 + perLesson, letters.count)])
        }
        let lessons: [Lesson] = groups.enumerated().flatMap { i, group -> [Lesson] in
            [Lesson(id: "\(id)_\(i + 1)a", title: title, icon: "🐾",
                    letters: group, letterActivities: [.soundToLetter]),
             Lesson(id: "\(id)_\(i + 1)b", title: title, icon: "👂",
                    letters: group, letterActivities: [.hearTap])]
        }
        return Unit(id: id, title: title, colorA: "#FF9A6B", colorB: "#A78BFA", lessons: lessons)
    }

    /// A short SPELLING unit from already-mastered early words — placed at the
    /// very END of a language's curriculum. Encoding is much harder than
    /// decoding, so it only appears after the child has read all the words.
    static func spellingUnit(idPrefix: String, title: String, words: [PWord]) -> Unit? {
        let spellable = words.filter { $0.picture != nil }
        guard spellable.count >= 3 else { return nil }
        let groups = stride(from: 0, to: min(spellable.count, 9), by: 3).map {
            Array(spellable[$0 ..< min($0 + 3, spellable.count)])
        }
        let lessons = groups.enumerated().map { i, g in
            Lesson(id: "\(idPrefix)_spell_\(i + 1)", title: title, icon: "✏️", words: g, spell: true)
        }
        return Unit(id: "\(idPrefix)_spell", title: title, colorA: "#FFCD3C", colorB: "#67C8FF",
                    lessons: lessons)
    }

    // MARK: - Generated drill (Mentava-style repetition without hand-authoring)

    /// Append PRACTICE LAPS to every word unit: lap A re-runs the unit's own
    /// words in a different (deterministic) order; lap B interleaves half of
    /// them with words from EARLIER units (cumulative review). Repetition is
    /// the point — the same words drilled again, not new content.
    static func withPracticeLaps(_ wordUnits: [Unit], practiceTitle: String,
                                 mixTitle: String) -> [Unit] {
        var prevWords: [PWord] = []
        return wordUnits.map { u in
            let own = u.lessons.flatMap(\.words)
            guard own.count >= 3 else { prevWords += own; return u }
            var lessons = u.lessons
            // Lap A: every word again, reshuffled, in bite-size lessons of ≤6.
            let lapA = seededShuffle(own, seed: own.count &* 31 &+ u.id.count)
            for (k, chunk) in chunked(lapA, by: 6).enumerated() {
                lessons.append(Lesson(id: "\(u.id)_lapA\(k + 1)", title: practiceTitle,
                                      icon: "🔁", words: chunk))
            }
            // Lap B: half this unit + as many from earlier units, interleaved.
            if !prevWords.isEmpty {
                let half = max(2, min(4, own.count / 2))
                let mine = Array(lapA.prefix(half))
                let old = stridePick(prevWords, count: half, salt: u.id.count)
                let mixed = seededShuffle(mine + old, seed: u.id.count &* 7 &+ 3)
                lessons.append(Lesson(id: "\(u.id)_lapB", title: mixTitle,
                                      icon: "🔀", words: mixed))
            }
            prevWords += own
            var copy = u; copy.lessons = lessons
            return copy
        }
    }

    /// Deterministic Fisher–Yates (seeded LCG): same input → same order every
    /// launch, so lesson content is stable but differs from the teaching order.
    private static func seededShuffle<T>(_ a: [T], seed: Int) -> [T] {
        guard a.count > 1 else { return a }
        var arr = a
        var s = UInt64(truncatingIfNeeded: seed) | 1
        for i in (1 ..< arr.count).reversed() {
            s = s &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            arr.swapAt(i, Int(s >> 33) % (i + 1))
        }
        return arr
    }

    /// Up to `count` words spread evenly across the pool (unique by text).
    private static func stridePick(_ pool: [PWord], count: Int, salt: Int) -> [PWord] {
        guard !pool.isEmpty else { return [] }
        var out: [PWord] = []; var seen = Set<String>()
        let step = max(1, pool.count / max(1, count))
        var i = salt % pool.count
        for _ in 0 ..< pool.count where out.count < count {
            let w = pool[i % pool.count]
            if seen.insert(w.text).inserted { out.append(w) }
            i += step
        }
        return out
    }

    private static func chunked(_ words: [PWord], by n: Int) -> [[PWord]] {
        stride(from: 0, to: words.count, by: n).map { Array(words[$0 ..< min($0 + n, words.count)]) }
    }

    /// Assemble: First-Sounds + (letter unit, … interleaving a cumulative review
    /// every 2 chunks) + a big all-letters review + words (with practice laps)
    /// + final spelling unit.
    static func assemble(soundsUnit: Unit,
                         letterUnits: [(unit: Unit, letters: [Letter])],
                         reviewTitle: String,
                         idPrefix: String,
                         wordUnits: [Unit],
                         spellTitle: String = "Spell it!",
                         practiceTitle: String = "Practice!",
                         mixTitle: String = "Mix it up!") -> [Unit] {
        var out: [Unit] = [soundsUnit]
        var taught: [Letter] = []
        var lastReviewCount = 0     // letters covered by the most recent review
        for (i, lu) in letterUnits.enumerated() {
            out.append(lu.unit)
            taught += lu.letters
            if (i + 1) % 2 == 0 && taught.count >= 4 {
                out.append(unit(id: "\(idPrefix)_rev\(i + 1)", title: reviewTitle, letters: taught))
                lastReviewCount = taught.count
            }
        }
        // Big all-letters review — skipped when an even unit count means the loop's
        // final review already covered every taught letter (otherwise the child
        // faces two identical back-to-back review units before words).
        if taught.count > 5 && taught.count != lastReviewCount {
            out.append(unit(id: "\(idPrefix)_revall", title: reviewTitle, letters: taught))
        }
        out += withPracticeLaps(wordUnits, practiceTitle: practiceTitle, mixTitle: mixTitle)
        // Spelling LAST: the first words of the curriculum, now spelled from
        // sound. Drawn from the ORIGINAL units so laps can't skew the selection.
        let earlyWords = wordUnits.flatMap { $0.lessons }.flatMap { $0.words }
        if let spell = spellingUnit(idPrefix: idPrefix, title: spellTitle, words: earlyWords) {
            out.append(spell)
        }
        return out
    }
}
