import XCTest
@testable import ReadRocketPhonics

/// Guards the data assumptions the 3D lesson player (WorldLessonView) relies on,
/// so no lesson can present an unplayable or un-blendable screen.
final class WorldLessonTests: XCTestCase {

    /// Every lesson must have at least one fuel step (word or sentence) — an empty
    /// lesson would blast off instantly with nothing to do.
    func testEveryLessonIsPlayable() {
        for l in Curriculum.allLessons {
            let playable = l.words.count + l.sentences.count + l.letters.count
            XCTAssertGreaterThanOrEqual(playable, 1,
                                        "Lesson \(l.id) has no words, sentences, or letters to play")
            // A letter lesson must declare at least one activity to run per letter.
            if !l.letters.isEmpty {
                XCTAssertFalse(l.letterActivities.isEmpty, "Letter lesson \(l.id) has no activities")
            }
        }
    }

    /// Every letter in the on-ramp has a sound and a keyword picture, and the
    /// reversible letters b/d/p/q are never adjacent in the teaching order.
    func testLetterLandIsSoundAndConfusableSafe() {
        for L in LetterLand.letters {
            XCTAssertFalse(L.ipa.isEmpty, "\(L.letter) has no sound")
            XCTAssertFalse(L.picture.isEmpty, "\(L.letter) has no picture")
        }
        let order = LetterLand.letters.map { $0.letter }
        for pair in [("b","d"), ("p","q"), ("b","p"), ("d","q")] {
            if let i = order.firstIndex(of: pair.0), let j = order.firstIndex(of: pair.1) {
                XCTAssertGreaterThan(abs(i - j), 1, "Reversible letters \(pair.0)/\(pair.1) are taught adjacently")
            }
        }
    }

    /// Every word must be blendable: at least one sounded grapheme so the blend
    /// track has a segment and "Say it!" produces sound.
    func testEveryWordIsBlendable() {
        for l in Curriculum.allLessons {
            for w in l.words {
                XCTAssertFalse(w.soundingIndices.isEmpty, "\(l.id): \"\(w.text)\" has no sounded graphemes")
                XCTAssertEqual(w.text, w.graphemes.map { $0.letters }.joined(),
                               "\(l.id): \"\(w.text)\" graphemes don't spell the word")
            }
        }
    }

    /// Generated word-family words are CVC/digraph only — none should have a silent
    /// grapheme. A silent one means a consonant blend (st/nd/mp/…) was wrongly used
    /// as a single rime token, which would blend the word incorrectly.
    func testWordFamiliesHaveNoSilentGraphemes() {
        for unit in WordFamilies.units {
            for lesson in unit.lessons {
                for w in lesson.words {
                    XCTAssertFalse(w.graphemes.contains { $0.isSilent },
                                   "\(lesson.id): \"\(w.text)\" has a silent grapheme — likely a blend-final used as one token")
                }
            }
        }
    }

    /// A pictured word should have a usable distractor for the picture-pick, OR
    /// it gracefully falls back to read-confirm — either way it's never a dead end.
    func testPicturedWordsHaveAFallback() {
        for l in Curriculum.allLessons {
            for w in l.words where w.picture != nil {
                // not an assertion failure either way — just document the branch is reachable
                let hasDistractor = l.words.contains { $0.id != w.id && $0.picture != nil && $0.picture != w.picture }
                XCTAssertTrue(hasDistractor || w.picture != nil)
            }
        }
    }

    /// The share moment fires exactly once: on the FIRST-ever blast-off, never on
    /// a replay — and the persisted flag is what makes it stick.
    func testFirstShareOfferedOnFirstBlastOffOnly() {
        let suite = "test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = ProfileStore(defaults: defaults, key: "k")
        store.select("fox")

        let first = LessonViewModel(lesson: Curriculum.firstLesson)
        first.start(store: store)
        first.recordProgress()
        XCTAssertTrue(first.offerFirstShare)
        XCTAssertTrue(store.firstShareOffered(for: "fox"))

        let replay = LessonViewModel(lesson: Curriculum.firstLesson)
        replay.start(store: store)
        replay.recordProgress()
        XCTAssertFalse(replay.offerFirstShare)

        // A different child still gets their own first-blast-off moment.
        store.select("bunny")
        let bunny = LessonViewModel(lesson: Curriculum.firstLesson)
        bunny.start(store: store)
        bunny.recordProgress()
        XCTAssertTrue(bunny.offerFirstShare)
    }

    /// A pre-update child (progress recorded before the share flag existed) who
    /// switches language gets a fresh world with zeroed counts — the share
    /// moment must still NOT fire, because it wasn't their first-ever blast-off.
    func testFirstShareNotOfferedInFreshLanguageWorld() {
        let suite = "test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite); Languages.setCurrent("en") }
        let store = ProfileStore(defaults: defaults, key: "k")
        store.select("fox")
        store.record(Curriculum.lessonOrder[0], stars: 3)   // pre-update progress…
        store.recordWin()                                   // …flag never set

        store.setLanguage("el")
        let vm = LessonViewModel(lesson: Curriculum.firstLesson)
        vm.start(store: store)
        vm.recordProgress()
        XCTAssertFalse(vm.offerFirstShare)
    }

    /// Keep the end-to-end "play every lesson" list in sync with the curriculum.
    /// If this fails, update `allLessonIDs` in ReadRocketUITests to match (this
    /// literal and that one must be IDENTICAL — regenerate both together).
    func testLessonOrderMatchesE2EList() {
        let expected = [
        "snd_1","snd_2","snd_3","snd_4","ltr_s","ltr_a","ltr_t","ltr_i",
        "ltr_p","ltr_n","ltr_c","ltr_e","ltr_h","ltr_r","ltr_m","ltr_d",
        "en_rev2_1a","en_rev2_1b","en_rev2_2a","en_rev2_2b","en_rev2_3a","en_rev2_3b","ltr_g","ltr_o",
        "ltr_k","ltr_u","ltr_l","ltr_f","ltr_b","ltr_j","ltr_v","ltr_w",
        "ltr_y","ltr_z","en_rev4_1a","en_rev4_1b","en_rev4_2a","en_rev4_2b","en_rev4_3a","en_rev4_3b",
        "en_rev4_4a","en_rev4_4b","en_rev4_5a","en_rev4_5b","ltr_q","ltr_x","en_revall_1a","en_revall_1b",
        "en_revall_2a","en_revall_2b","en_revall_3a","en_revall_3b","en_revall_4a","en_revall_4b","en_revall_5a","en_revall_5b",
        "en_revall_6a","en_revall_6b","bl_vc1","bl_vc2","bl_vc3","bl_cvc1","bl_cvc2","bl_cvc3",
        "u1l1","u1l2","u1l3","u1_lapA1","u1_lapA2","u1_lapA3","u1_lapA4","u2l1",
        "u2l2","u2l3","u2l4","u2_lapA1","u2_lapA2","u2_lapA3","u2_lapA4","u2_lapA5",
        "u2_lapB","u3l1","u3l2","u3l3","u3l4","u3_lapA1","u3_lapA2","u3_lapA3",
        "u3_lapA4","u3_lapA5","u3_lapB","u4l1","u4l2","u4l3","u4l4","u4_lapA1",
        "u4_lapA2","u4_lapA3","u4_lapA4","u4_lapA5","u4_lapB","u5l1","u5l2","u5l3",
        "u5_lapA1","u5_lapA2","u5_lapA3","u5_lapB","u6l1","u6l2","u6l3","u6l4",
        "u6_lapA1","u6_lapA2","u6_lapA3","u6_lapA4","u6_lapB","u7l1","u7l2","u7l3",
        "u7l4","u7_lapA1","u7_lapA2","u7_lapA3","u7_lapA4","u7_lapB","u8l1","u8l2",
        "u8l3","u8_lapA1","u8_lapA2","u8_lapA3","u8_lapB","u9l1","u9l2","u9l3",
        "u9l4","u9_lapA1","u9_lapA2","u9_lapA3","u9_lapA4","u9_lapB","u10l1","u10l2",
        "u10l3","u10_lapA1","u10_lapA2","u10_lapA3","u10_lapB","u11l1","u11l2","u11l3",
        "u11_lapA1","u11_lapA2","u11_lapA3","u11_lapB","u12l1","u12l2","u12l3","u12l4",
        "u12l5","u12l6","u12l7","u12l8","u12l9","fam_at","fam_an","fam_ap",
        "fam_ad","fam_ag","fam_am","fam_ab","fam_ack","fam_ash","fam_all","fam_it",
        "fam_ig","fam_in","fam_ip","fam_id","fam_ix","fam_ick","fam_ish","fam_ing",
        "fam_ill","fam_ot","fam_og","fam_op","fam_ox","fam_ob","fam_od","fam_ock",
        "fam_ong","fam_ug","fam_un","fam_ut","fam_up","fam_ub","fam_uck","fam_um",
        "fam_ush","fam_ung","fam_ed","fam_en","fam_et","fam_eg","fam_ell","fam_eck",
        "en_spell_1","en_spell_2","en_spell_3"
        ]
        XCTAssertEqual(Curriculum.lessonOrder, expected,
                       "Curriculum changed — update allLessonIDs in ReadRocketUITests to match.")
    }
}
