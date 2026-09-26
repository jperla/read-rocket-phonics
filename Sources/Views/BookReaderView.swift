import SwiftUI

/// A cozy, illustrated storybook reader. Presents a decodable story (a Unit-12
/// story Lesson) as page-turn pages: a big picture, the sentence as tappable
/// words (tap any word to hear it), a "Read to me" button, and a gentle page
/// turn — building toward "reading a whole little book." All story text is
/// original decodable content (reused from the curriculum — no duplication).
///
/// Fully testable: under `-uitest` audio is muted and there are no timed waits,
/// so the autopilot can page to "The End!" with no stall.
struct BookReaderView: View {
    let lesson: Lesson
    var done: () -> Void = {}

    @State private var page = 0
    @State private var highlightedWordIndex: Int? = nil
    @State private var finished = false

    private var fast: Bool { AppEnv.uiTesting }
    private var pages: [[String]] { lesson.sentences }

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: "#FFF3D8"), Color(hex: "#FFD9A8")],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            if finished { endView } else { pageView }

            Button { done() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 34)).foregroundStyle(Theme.ink.opacity(0.5))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("book_close")
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            .padding(22)
        }
    }

    // MARK: - Page

    private var pageView: some View {
        VStack(spacing: 26) {
            Text(lesson.title)
                .font(.system(size: 24, weight: .heavy, design: .rounded))
                .foregroundStyle(Theme.ink.opacity(0.7))

            Text(pageArt(page < pages.count ? pages[page] : [])).font(.system(size: 130))

            // The sentence as tappable word chips.
            let words = page < pages.count ? pages[page] : []
            FlowWords(words: words, highlight: highlightedWordIndex) { i in tapWord(words, i) }

            HStack(spacing: 18) {
                Button { readPage() } label: {
                    Label("Read to me", systemImage: "speaker.wave.2.fill")
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 22).padding(.vertical, 14)
                        .background(Capsule().fill(Theme.coral))
                }
                .buttonStyle(.plain).accessibilityIdentifier("book_read")

                Button { turnPage() } label: {
                    Label(page + 1 >= pages.count ? "The End" : "Next",
                          systemImage: "arrow.right")
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 28).padding(.vertical, 14)
                        .background(Capsule().fill(Theme.bgBottom))
                }
                .buttonStyle(.plain).accessibilityIdentifier("book_next")
            }

            // Page dots
            HStack(spacing: 6) {
                ForEach(0..<pages.count, id: \.self) { i in
                    Circle().fill(i == page ? Theme.ink : Theme.ink.opacity(0.25))
                        .frame(width: 9, height: 9)
                }
            }
        }
        .padding(34)
    }

    private var endView: some View {
        VStack(spacing: 22) {
            Text("🎉").font(.system(size: 110))
            Text(Languages.active.t("the_end"))
                .font(.system(size: 44, weight: .black, design: .rounded))
                .foregroundStyle(Theme.ink)
            Text(String(format: Languages.active.t("you_read"), lesson.title))
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.ink.opacity(0.7))
            Button { done() } label: {
                Text(Languages.active.t("back_to_books"))
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 36).padding(.vertical, 16)
                    .background(Capsule().fill(Theme.coral))
            }
            .buttonStyle(.plain).accessibilityIdentifier("Back to map")
        }
    }

    // MARK: - Page art (auto-illustrate each page from its words)

    private func pageArt(_ words: [String]) -> String {
        for w in words { if let e = BookReaderView.art[w] { return e } }
        return lesson.icon
    }
    private static let art: [String: String] = [
        "cat": "🐱", "hat": "🎩", "rat": "🐀", "dog": "🐶", "pup": "🐶", "sun": "☀️",
        "fish": "🐟", "frog": "🐸", "hop": "🐇", "swim": "🏊", "bike": "🚲", "ride": "🚴",
        "hill": "⛰️", "moon": "🌙", "night": "🌙", "owl": "🦉", "duck": "🦆", "lake": "🌊",
        "log": "🪵", "bug": "🐛", "bee": "🐝", "leaf": "🍃", "bed": "🛏️", "sleep": "😴",
        "run": "🏃", "red": "🟥", "see": "👀", "jump": "🦘", "yawn": "🥱", "ship": "🚢",
        "king": "👑", "ring": "💍", "rug": "🧶", "tree": "🌳", "star": "⭐"
    ]

    // MARK: - Actions

    private func tapWord(_ words: [String], _ i: Int) {
        guard i < words.count else { return }
        highlightedWordIndex = i
        SpeechManager.shared.speak(words[i])
        if !fast {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { if highlightedWordIndex == i { highlightedWordIndex = nil } }
        }
    }

    private func readPage() {
        guard !fast, page < pages.count else { return }
        let words = pages[page]
        SpeechManager.shared.speak(words.joined(separator: " "))
        for (k, _) in words.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(k) * 0.45) {
                if page < pages.count && pages[page] == words { highlightedWordIndex = k }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(words.count) * 0.45) { highlightedWordIndex = nil }
    }

    private func turnPage() {
        Haptics.tap()
        highlightedWordIndex = nil
        if page + 1 >= pages.count {
            SoundFX.shared.correct()
            withAnimation(fast ? nil : .spring(response: 0.4)) { finished = true }
        } else {
            withAnimation(fast ? nil : .easeInOut(duration: 0.25)) { page += 1 }
        }
    }
}

/// Simple wrapping row of tappable word chips.
private struct FlowWords: View {
    let words: [String]
    var highlight: Int? = nil
    let tap: (Int) -> Void

    var body: some View {
        VStack(spacing: 10) {
            ForEach(Array(rows().enumerated()), id: \.offset) { _, row in
                HStack(spacing: 10) {
                    ForEach(row, id: \.idx) { item in
                        Button { tap(item.idx) } label: {
                            Text(item.word)
                                .font(.system(size: 36, weight: .heavy, design: .rounded))
                                .foregroundStyle(highlight == item.idx ? Theme.coral : Theme.ink)
                                .padding(.horizontal, 10).padding(.vertical, 6)
                                .background(RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(highlight == item.idx ? Color.white : Color.white.opacity(0.55)))
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("book_word_\(item.idx)")
                    }
                }
            }
        }
    }

    private func rows() -> [[(idx: Int, word: String)]] {
        let indexed = words.enumerated().map { (idx: $0.offset, word: $0.element) }
        return stride(from: 0, to: indexed.count, by: 4).map { Array(indexed[$0..<min($0 + 4, indexed.count)]) }
    }
}
