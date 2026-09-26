import XCTest

/// Real end-to-end autopilot for the 3D lesson player (WorldLessonView). Every
/// lesson now runs in the same blend-to-mastery format, so one play loop drives
/// any lesson type: tap "Got it!" for a new-sound intro, "Say it!" to blend a
/// word, then the correct picture OR "I read it!" (for un-pictured words and
/// sentences), until the rocket blasts off ("Great job!").
///
/// Progression must NOT depend on audio: this mode mutes sound, so a screen that
/// required hearing something to advance would hang and fail here.
final class ReadRocketUITests: XCTestCase {

    var app: XCUIApplication!

    /// Every lesson id, in order. Kept in sync with Curriculum by a unit test
    /// (WorldLessonTests.testLessonOrderMatchesE2EList).
    static let allLessonIDs = [
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

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-uitest"]
        app.launch()
    }

    @discardableResult
    private func tapIfHittable(_ e: XCUIElement) -> Bool {
        if e.exists && e.isHittable { e.tap(); return true }
        return false
    }

    /// Scroll the map until the lesson node is on screen, then open it.
    private func openLesson(_ id: String, file: StaticString = #file, line: UInt = #line) {
        let node = app.buttons[id]
        var swipes = 0
        while !node.isHittable && swipes < 30 { app.swipeUp(); swipes += 1 }
        if !node.isHittable { for _ in 0..<6 where !node.isHittable { app.swipeDown() } }
        XCTAssertTrue(node.isHittable, "Could not reach lesson node \(id)", file: file, line: line)
        node.tap()
    }

    /// Drive whatever lesson is on screen to the celebration using only the
    /// on-screen controls. Works for every step type in WorldLessonView.
    private func playToBlastOff(_ id: String, file: StaticString = #file, line: UInt = #line) {
        let celebration = app.staticTexts["Great job!"]
        var guardC = 0
        while !celebration.exists && guardC < 250 {
            usleep(120_000)   // let the (test-mode static) step settle before querying
            if app.buttons["Got it!"].isHittable { app.buttons["Got it!"].tap() }            // sound intro
            else if app.buttons["slice_pick_correct"].isHittable { app.buttons["slice_pick_correct"].tap() }      // pick the picture (3 options)
            else if app.buttons["flex_correct"].firstMatch.isHittable { app.buttons["flex_correct"].firstMatch.tap() }  // flex the vowel-team sound
            else if app.buttons["build_correct"].firstMatch.isHittable { app.buttons["build_correct"].firstMatch.tap() }       // spell the word
            else if app.buttons["sentbuild_correct"].firstMatch.isHittable { app.buttons["sentbuild_correct"].firstMatch.tap() } // build the sentence
            else if app.buttons["slice_blend"].isHittable { app.buttons["slice_blend"].tap() }   // sound out a word
            guardC += 1
        }
        XCTAssertTrue(celebration.waitForExistence(timeout: 8),
                      "Lesson \(id) never reached blast-off — it got stuck", file: file, line: line)
        XCTAssertTrue(tapIfHittable(app.buttons["Back to map"]),
                      "No 'Back to map' after lesson \(id)", file: file, line: line)
    }

    func testStartScreen() {
        XCTAssertTrue(app.buttons["profile_fox"].waitForExistence(timeout: 15))
    }

    /// Map → lesson WIRING smoke: pick a profile, open a lesson from the map, tap
    /// a tile (regression guard for the original "stuck" bug), and play it through.
    /// Full per-lesson content coverage lives in testEveryLessonReachesBlastOff.
    func testMapOpensAndPlaysLesson() {
        app.buttons["profile_fox"].tap()
        openLesson("lesson_u1l1")
        let tile = app.buttons["slice_tile_0"]
        if tile.waitForExistence(timeout: 5) { tile.tap() }
        playToBlastOff("u1l1")
    }

    /// Launch a single lesson directly (-slice) and play it to blast-off.
    private func playSliceLesson(extraArgs: [String], file: StaticString = #file, line: UInt = #line) {
        app.terminate()
        app.launchArguments = ["-uitest", "-slice"] + extraArgs
        app.launch()
        playToBlastOff("slice", file: file, line: line)
    }

    func testSliceLessonReachesBlastOff() {
        playSliceLesson(extraArgs: [])
    }

    /// Regression guard for the real "Say it! does nothing" device bug: when the
    /// blend audio produces nothing and never calls back, the lesson must STILL
    /// advance (transitions are timer-driven, never audio-gated).
    func testSliceSurvivesDeadBlendAudio() {
        playSliceLesson(extraArgs: ["-deadaudio"])
    }

    /// Launch one lesson directly by id and play it to blast-off.
    private func playLessonDirect(_ id: String, file: StaticString = #file, line: UInt = #line) {
        app.terminate()
        app.launchArguments = ["-uitest", "-lesson", id]
        app.launch()
        playToBlastOff(id, file: file, line: line)
    }

    /// EVERY-BUILD content smoke: one lesson per unit (12), covering every step
    /// type (intro, picture-pick, read-confirm, sentence, story) — fast enough for
    /// the gate. Full 48-lesson coverage is testEveryLessonReachesBlastOff
    /// (on-demand via `Scripts/rr.sh e2e-all`).
    func testSmokeOneLessonPerUnit() {
        for id in ["snd_1", "ltr_s",                  // on-ramp: first-sound + a full letter lesson
                   "u1l1", "u2l3", "u3l1", "u4l1", "u5l3", "u6l1",
                   "u7l1", "u8l1", "u9l1", "u10l1", "u11l1", "u12l1",
                   "fam_at", "fam_ug", "fam_en"] {   // generated word-family lessons
            playLessonDirect(id)
        }
    }

    /// FULL COVERAGE (on-demand): launch EVERY lesson directly and play it to
    /// blast-off — guarantees no lesson in the whole curriculum can get stuck.
    /// Run via `Scripts/rr.sh e2e-all`; skipped in the every-build gate because
    /// 48 relaunches is too slow for every commit.
    func testEveryLessonReachesBlastOff() {
        for id in ReadRocketUITests.allLessonIDs {
            playLessonDirect(id)
        }
    }

    /// The storybook reader must page through every page to "The End!".
    func testBookReaderPagesToEnd() {
        app.terminate()
        app.launchArguments = ["-uitest", "-book", "u12l1"]
        app.launch()
        let end = app.staticTexts["The End!"]
        var guardC = 0
        while !end.exists && guardC < 60 {
            usleep(120_000)
            if app.buttons["book_next"].isHittable { app.buttons["book_next"].tap() }
            guardC += 1
        }
        XCTAssertTrue(end.waitForExistence(timeout: 5), "Book never reached 'The End!'")
        XCTAssertTrue(app.buttons["Back to map"].waitForExistence(timeout: 3))
    }

    /// The grown-ups Sound Check screen must render every group and let each
    /// sound tile be tapped without crashing or stalling.
    func testSoundCheckLoadsAndTaps() {
        app.terminate()
        app.launchArguments = ["-uitest", "-soundcheck"]
        app.launch()
        XCTAssertTrue(app.buttons["sound_g"].waitForExistence(timeout: 10), "Sound Check did not render")
        for id in ["sound_a", "sound_g", "sound_y", "sound_sh", "sound_oo", "sound_ar"] {
            if app.buttons[id].isHittable { app.buttons[id].tap() }
        }
        XCTAssertTrue(app.buttons["sound_play_all"].exists)
    }
}
