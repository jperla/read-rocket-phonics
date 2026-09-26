import Foundation

/// Global flags read from launch arguments. `-uitest` mutes speech and disables
/// continuous animations so XCUITest can drive the app without idling forever.
enum AppEnv {
    static let uiTesting = ProcessInfo.processInfo.arguments.contains("-uitest")
    /// Launch straight into the parent progress view for QA.
    static let previewParent = ProcessInfo.processInfo.arguments.contains("-showParent")
    /// Launch straight into the Mentava-style vertical slice (3D blend-to-mastery)
    /// for visual QA and end-to-end autopilot.
    static let sliceMode = ProcessInfo.processInfo.arguments.contains("-slice")
    /// Launch straight into a specific lesson by id (`-lesson u6l1`) — lets the
    /// e2e autopilot drive every lesson directly without map navigation.
    static let lessonID: String? = {
        let a = ProcessInfo.processInfo.arguments
        if let i = a.firstIndex(of: "-lesson"), i + 1 < a.count { return a[i + 1] }
        return nil
    }()
    /// Launch straight into the storybook reader for a story lesson (`-book u12l1`).
    static let bookID: String? = {
        let a = ProcessInfo.processInfo.arguments
        if let i = a.firstIndex(of: "-book"), i + 1 < a.count { return a[i + 1] }
        return nil
    }()
    /// Launch straight into the grown-ups Sound Check screen for QA.
    static let soundCheck = ProcessInfo.processInfo.arguments.contains("-soundcheck")
    /// Test hook: make blend audio produce nothing and never call back —
    /// reproduces a real device where the speech synth silently never finishes.
    /// Used to prove the UI advances on its own timer, not on an audio callback.
    static let deadBlendAudio = ProcessInfo.processInfo.arguments.contains("-deadaudio")
    /// QA: preview the sticker gift celebration directly for visual checks.
    static let giftDemo = ProcessInfo.processInfo.arguments.contains("-giftdemo")
    /// QA: pre-seed the mosaic win count (`-mosaicwins 15`) so the very next lesson
    /// completes a poster — lets us land on (and test) the big dance party directly.
    static let mosaicWins: Int? = {
        let a = ProcessInfo.processInfo.arguments
        if let i = a.firstIndex(of: "-mosaicwins"), i + 1 < a.count { return Int(a[i + 1]) }
        return nil
    }()
    /// QA: preview the poster mosaic / dance party directly (`-mosaicdemo`).
    static let mosaicDemo = ProcessInfo.processInfo.arguments.contains("-mosaicdemo")
    /// QA: render all 26 lowercase tracing letterforms in a grid for a visual audit.
    static let strokeSheet = ProcessInfo.processInfo.arguments.contains("-strokesheet")
    /// QA: force the active learning language for every profile (`-lang el`).
    static let forceLanguage: String? = {
        let a = ProcessInfo.processInfo.arguments
        if let i = a.firstIndex(of: "-lang"), i + 1 < a.count { return a[i + 1] }
        return nil
    }()
    /// QA: preview the letter-tracing screen (`-tracedemo b`) for visual checks.
    static let traceDemo: String? = {
        let a = ProcessInfo.processInfo.arguments
        if let i = a.firstIndex(of: "-tracedemo"), i + 1 < a.count { return a[i + 1] }
        return nil
    }()
}
