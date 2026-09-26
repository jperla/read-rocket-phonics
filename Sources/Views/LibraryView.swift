import SwiftUI

/// The book shelf: a grid of original, decodable storybooks the child can read
/// on their own. Each book is a Unit-12 story (reused — no duplicated text),
/// opened in the illustrated page-turn `BookReaderView`.
struct LibraryView: View {
    var done: () -> Void = {}
    @State private var openBook: Lesson? = nil

    private var stories: [Lesson] {
        // English's "u12" Story Time, or any language pack's "<code>_stories" unit.
        (Curriculum.units.first { $0.id == "u12" || $0.id.hasSuffix("_stories") }?.lessons) ?? []
    }
    private let cols = [GridItem(.adaptive(minimum: 150), spacing: 22)]

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: "#FFF3D8"), Color(hex: "#FFCF8F")],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            VStack(spacing: 14) {
                HStack {
                    Text(Languages.active.t("library_title"))
                        .font(.system(size: 34, weight: .black, design: .rounded))
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    Button { done() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 34)).foregroundStyle(Theme.ink.opacity(0.5))
                    }
                    .buttonStyle(.plain).accessibilityIdentifier("library_close")
                }
                .padding(.horizontal, 26).padding(.top, 22)

                Text(Languages.active.t("library_subtitle"))
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.ink.opacity(0.7))

                ScrollView {
                    LazyVGrid(columns: cols, spacing: 22) {
                        ForEach(stories) { story in
                            Button { openBook = story } label: { bookCover(story) }
                                .buttonStyle(.plain)
                                .accessibilityIdentifier("book_\(story.id)")
                        }
                    }
                    .padding(24)
                }
            }
        }
        .fullScreenCover(item: $openBook) { story in
            BookReaderView(lesson: story, done: { openBook = nil })
        }
    }

    private func bookCover(_ story: Lesson) -> some View {
        VStack(spacing: 10) {
            Text(story.icon).font(.system(size: 72))
            Text(story.title)
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(height: 46)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 22).padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(LinearGradient(colors: [Theme.coral, Theme.bgBottom],
                                     startPoint: .top, endPoint: .bottom))
                .shadow(color: .black.opacity(0.2), radius: 8, y: 5)
        )
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(.white.opacity(0.6), lineWidth: 3))
    }
}
