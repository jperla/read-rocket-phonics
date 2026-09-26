import SwiftUI

/// The reward gallery. Shows the picture currently being uncovered (a 4×4 mosaic
/// that fills one tile per finished lesson) and every poster collected so far.
/// Because a new scene always follows the last, the gallery never "fills up".
struct StickerBookView: View {
    @EnvironmentObject var store: ProfileStore
    @Environment(\.dismiss) private var dismiss
    private let cols = [GridItem(.adaptive(minimum: 150), spacing: 16)]

    var body: some View {
        let collected = store.postersCollected()
        let curIdx = store.currentPosterIndex()
        let curTiles = store.tilesRevealed()
        let scenes = PosterScene.all

        ZStack {
            Theme.background(Theme.bgTop, Theme.bgBottom)
            VStack(spacing: 14) {
                HStack {
                    Text(Languages.active.t("my_posters"))
                        .font(.system(size: 40, weight: .black, design: .rounded))
                        .foregroundStyle(.white).shadow(radius: 4, y: 2)
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 38)).foregroundStyle(.white.opacity(0.9))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("stickers_close")
                }
                .padding(.horizontal, 28).padding(.top, 24)

                ScrollView {
                    VStack(spacing: 10) {
                        Text(Languages.active.t("keep_going_uncover"))
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.9))
                        if !scenes.isEmpty {
                            MosaicBoard(scene: scenes[curIdx % scenes.count], revealed: curTiles)
                                .frame(width: 260, height: 260)
                        }
                        Text("\(curTiles) / \(ProfileStore.tilesPerPoster)")
                            .font(.system(size: 20, weight: .heavy, design: .rounded))
                            .foregroundStyle(Theme.sun)
                    }
                    .padding(.vertical, 8)

                    if collected > 0 && !scenes.isEmpty {
                        Text("Your posters")
                            .font(.system(size: 22, weight: .black, design: .rounded))
                            .foregroundStyle(.white).padding(.top, 12)
                        LazyVGrid(columns: cols, spacing: 16) {
                            ForEach(0..<collected, id: \.self) { i in
                                posterCard(scenes[i % scenes.count])
                            }
                        }
                        .padding(.horizontal, 24).padding(.top, 6)
                    }
                }

                Text(collected == 0 ? "Finish lessons to win your first poster!"
                                    : "Finish lessons to win more posters!")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.bottom, 16)
            }
        }
    }

    private func posterCard(_ scene: PosterScene) -> some View {
        VStack(spacing: 6) {
            scene.illustration
                .frame(height: 130)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(.white.opacity(0.4), lineWidth: 2))
            Text("\(scene.emoji) \(scene.name)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.white).lineLimit(1)
        }
    }
}
