import SwiftUI

/// A 4×4 mosaic over a hidden `PosterScene`. `revealed` tiles (0…16) are peeled
/// away to expose the art beneath; finishing all 16 unveils the whole picture.
/// The peel order is a fixed scatter (not strict reading order) so it feels like
/// a picture emerging rather than a wipe.
struct MosaicBoard: View {
    let scene: PosterScene
    var revealed: Int                 // how many tiles are uncovered
    var cornerRadius: CGFloat = 24

    /// Reveal rank for each of the 16 cells (cell index → order it opens).
    private static let rank: [Int] = [ 0, 8, 2, 10,
                                      12, 4, 14, 6,
                                       3, 11, 1, 9,
                                      15, 7, 13, 5]

    var body: some View {
        GeometryReader { g in
            let side = min(g.size.width, g.size.height)
            let gap: CGFloat = side * 0.012
            let tile = (side - gap * 3) / 4
            ZStack {
                scene.illustration
                    .frame(width: side, height: side)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))

                ForEach(0..<16, id: \.self) { idx in
                    let open = MosaicBoard.rank[idx] < revealed
                    let row = idx / 4, col = idx % 4
                    tileCover(idx: idx)
                        .frame(width: tile, height: tile)
                        .scaleEffect(open ? 0.15 : 1)
                        .opacity(open ? 0 : 1)
                        .rotation3DEffect(.degrees(open ? 80 : 0), axis: (x: 1, y: 1, z: 0))
                        .position(x: tile / 2 + CGFloat(col) * (tile + gap),
                                  y: tile / 2 + CGFloat(row) * (tile + gap))
                        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: open)
                }
            }
            .frame(width: side, height: side)
            .overlay(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(.white.opacity(0.5), lineWidth: 3))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func tileCover(idx: Int) -> some View {
        let a = Color(red: 0.42, green: 0.34, blue: 0.72)
        let b = Color(red: 0.26, green: 0.20, blue: 0.50)
        return RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(LinearGradient(colors: [a, b], startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(.white.opacity(0.18), lineWidth: 1))
            .overlay(Text("✦").font(.system(size: 18)).foregroundStyle(.white.opacity(0.30)))
            .shadow(color: .black.opacity(0.15), radius: 2, y: 1)
    }
}

#Preview("Mosaic progress") {
    VStack(spacing: 20) {
        ForEach([3, 9, 16], id: \.self) { n in
            MosaicBoard(scene: .rocket, revealed: n).frame(width: 220, height: 220)
        }
    }
    .padding().background(Color.black)
}
