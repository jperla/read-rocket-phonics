import SwiftUI
import Foundation   // cos/sin for StarShape

/// The hand-drawn "cool images" that hide under each 4×4 mosaic board. A child
/// reveals one tile per win; finishing all 16 unveils the whole scene and earns
/// the poster for their gallery. All vector art (no image assets) so it stays
/// crisp at any size and themes cleanly on dark or light backgrounds.
enum PosterScene: String, CaseIterable, Identifiable {
    case rocket, ocean, jungle, castle, meadow, dino

    var id: String { rawValue }

    /// Kid-friendly title shown on reveal ("You found the Rocket Launch!").
    var name: String {
        switch self {
        case .rocket: return "Rocket Launch"
        case .ocean:  return "Under the Sea"
        case .jungle: return "Jungle"
        case .castle: return "Castle"
        case .meadow: return "Flower Meadow"
        case .dino:   return "Dino Land"
        }
    }

    /// A small accent used on gallery chips / labels.
    var emoji: String {
        switch self {
        case .rocket: return "🚀"
        case .ocean:  return "🐠"
        case .jungle: return "🐯"
        case .castle: return "🏰"
        case .meadow: return "🌻"
        case .dino:   return "🦕"
        }
    }

    static var all: [PosterScene] { allCases }

    /// The full illustration, drawn to fill a square.
    @ViewBuilder var illustration: some View {
        switch self {
        case .rocket: RocketScene()
        case .ocean:  OceanScene()
        case .jungle: JungleScene()
        case .castle: CastleScene()
        case .meadow: MeadowScene()
        case .dino:   DinoScene()
        }
    }
}

// MARK: - Reusable vector shapes

struct PolyTriangle: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.midX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

struct StarShape: Shape {
    var points = 5
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) / 2
        let inner = outer * 0.42
        for i in 0..<(points * 2) {
            let radius = i % 2 == 0 ? outer : inner
            let a = (Double(i) / Double(points * 2)) * 2 * .pi - .pi / 2
            let pt = CGPoint(x: c.x + CGFloat(cos(a)) * radius,
                             y: c.y + CGFloat(sin(a)) * radius)
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath()
        return p
    }
}

/// A soft rolling hill (a wide arc filling the bottom).
struct Hill: Shape {
    var rise: CGFloat = 0.5     // 0…1 how high the crest sits
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.maxY))
        // A quad Bézier reaches only HALF its control offset at the midpoint, so
        // the control sits at 2× rise to make the crest land at rise·height.
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.maxY),
                       control: CGPoint(x: r.midX, y: r.maxY - r.height * rise * 2))
        p.closeSubpath()
        return p
    }
}

private func grad(_ colors: [Color]) -> LinearGradient {
    LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)
}

// MARK: - Scenes

struct RocketScene: View {
    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            ZStack {
                grad([Color(red: 0.10, green: 0.08, blue: 0.32), Color(red: 0.34, green: 0.16, blue: 0.52)])
                // stars
                ForEach(0..<14, id: \.self) { i in
                    StarShape().fill(.white.opacity(0.9))
                        .frame(width: w * 0.045, height: w * 0.045)
                        .position(x: w * starX(i), y: h * starY(i))
                }
                // moon
                Circle().fill(Color(red: 1.0, green: 0.93, blue: 0.6))
                    .frame(width: w * 0.22).position(x: w * 0.80, y: h * 0.22)
                // ground
                Ellipse().fill(grad([Color(red: 0.45, green: 0.28, blue: 0.55), Color(red: 0.28, green: 0.16, blue: 0.38)]))
                    .frame(width: w * 1.5, height: h * 0.5).position(x: w * 0.5, y: h * 1.05)
                // rocket
                rocket(w: w, h: h).position(x: w * 0.42, y: h * 0.52)
            }
        }
        .clipped()
    }
    private func rocket(w: CGFloat, h: CGFloat) -> some View {
        let s = min(w, h)
        return ZStack {
            // flame
            PolyTriangle().fill(grad([Color.orange, Color.yellow]))
                .frame(width: s * 0.18, height: s * 0.26)
                .rotationEffect(.degrees(180)).offset(y: s * 0.30)
            // body
            Capsule().fill(.white).frame(width: s * 0.22, height: s * 0.5)
            // window
            Circle().fill(Color(red: 0.4, green: 0.8, blue: 1)).frame(width: s * 0.10)
                .overlay(Circle().stroke(.gray.opacity(0.5), lineWidth: 2)).offset(y: -s * 0.07)
            // nose
            PolyTriangle().fill(Color(red: 0.96, green: 0.34, blue: 0.44))
                .frame(width: s * 0.22, height: s * 0.18).offset(y: -s * 0.34)
            // fins
            PolyTriangle().fill(Color(red: 0.96, green: 0.34, blue: 0.44))
                .frame(width: s * 0.12, height: s * 0.16).rotationEffect(.degrees(-30)).offset(x: -s * 0.14, y: s * 0.2)
            PolyTriangle().fill(Color(red: 0.96, green: 0.34, blue: 0.44))
                .frame(width: s * 0.12, height: s * 0.16).rotationEffect(.degrees(30)).offset(x: s * 0.14, y: s * 0.2)
        }
    }
    private func starX(_ i: Int) -> CGFloat { CGFloat((i * 37) % 100) / 100 }
    private func starY(_ i: Int) -> CGFloat { CGFloat((i * 53 + 11) % 70) / 100 }
}

struct OceanScene: View {
    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            ZStack {
                grad([Color(red: 0.20, green: 0.65, blue: 0.92), Color(red: 0.04, green: 0.24, blue: 0.55)])
                // sun rays from top
                ForEach(0..<5, id: \.self) { i in
                    Capsule().fill(.white.opacity(0.10))
                        .frame(width: w * 0.10, height: h * 0.9)
                        .rotationEffect(.degrees(Double(i) * 8 - 16))
                        .position(x: w * (0.2 + CGFloat(i) * 0.16), y: h * 0.35)
                }
                // sandy bottom
                Hill(rise: 0.25).fill(grad([Color(red: 0.95, green: 0.86, blue: 0.55), Color(red: 0.80, green: 0.68, blue: 0.40)]))
                // seaweed
                ForEach(0..<3, id: \.self) { i in
                    Capsule().fill(Color(red: 0.16, green: 0.6, blue: 0.36))
                        .frame(width: w * 0.04, height: h * 0.3)
                        .position(x: w * (0.15 + CGFloat(i) * 0.12), y: h * 0.82)
                }
                // fish
                fish(Color(red: 1.0, green: 0.55, blue: 0.2), w * 0.18).position(x: w * 0.62, y: h * 0.42)
                fish(Color(red: 1.0, green: 0.84, blue: 0.3), w * 0.13).position(x: w * 0.38, y: h * 0.6)
                fish(Color(red: 0.95, green: 0.4, blue: 0.6), w * 0.11).position(x: w * 0.80, y: h * 0.68)
                // bubbles
                ForEach(0..<6, id: \.self) { i in
                    Circle().stroke(.white.opacity(0.6), lineWidth: 2)
                        .frame(width: w * (0.03 + CGFloat(i % 3) * 0.015))
                        .position(x: w * (0.5 + CGFloat(i) * 0.02), y: h * (0.5 - CGFloat(i) * 0.07))
                }
            }
        }
        .clipped()
    }
    private func fish(_ c: Color, _ s: CGFloat) -> some View {
        ZStack {
            Ellipse().fill(c).frame(width: s, height: s * 0.66)
            PolyTriangle().fill(c).frame(width: s * 0.4, height: s * 0.5)
                .rotationEffect(.degrees(-90)).offset(x: -s * 0.5)
            Circle().fill(.white).frame(width: s * 0.16).offset(x: s * 0.28, y: -s * 0.06)
                .overlay(Circle().fill(.black).frame(width: s * 0.07).offset(x: s * 0.28, y: -s * 0.06))
        }
    }
}

struct JungleScene: View {
    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            ZStack {
                grad([Color(red: 0.55, green: 0.85, blue: 0.55), Color(red: 0.10, green: 0.45, blue: 0.25)])
                Circle().fill(Color(red: 1.0, green: 0.9, blue: 0.45)).frame(width: w * 0.2).position(x: w * 0.8, y: h * 0.2)
                // back hills
                Hill(rise: 0.5).fill(Color(red: 0.16, green: 0.52, blue: 0.30)).frame(height: h).offset(y: h * 0.1)
                Hill(rise: 0.7).fill(Color(red: 0.10, green: 0.40, blue: 0.22)).frame(height: h).offset(y: h * 0.3)
                // palm trees
                palm(w * 0.42, h).position(x: w * 0.26, y: h * 0.62)
                palm(w * 0.5, h).position(x: w * 0.7, y: h * 0.58)
                // leaves foreground
                ForEach(0..<3, id: \.self) { i in
                    Capsule().fill(Color(red: 0.12, green: 0.55, blue: 0.3))
                        .frame(width: w * 0.3, height: w * 0.1)
                        .rotationEffect(.degrees(Double(i) * 30 - 30))
                        .position(x: w * (0.2 + CGFloat(i) * 0.3), y: h * 0.95)
                }
            }
        }
        .clipped()
    }
    private func palm(_ s: CGFloat, _ h: CGFloat) -> some View {
        ZStack {
            Capsule().fill(Color(red: 0.45, green: 0.30, blue: 0.16)).frame(width: s * 0.10, height: s * 0.8)
            ForEach(0..<5, id: \.self) { i in
                Capsule().fill(Color(red: 0.18, green: 0.6, blue: 0.32))
                    .frame(width: s * 0.5, height: s * 0.16)
                    .rotationEffect(.degrees(Double(i) * 60))
                    .offset(y: -s * 0.4)
            }
        }
    }
}

struct CastleScene: View {
    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            ZStack {
                grad([Color(red: 0.55, green: 0.80, blue: 1.0), Color(red: 0.85, green: 0.92, blue: 1.0)])
                Circle().fill(Color(red: 1.0, green: 0.92, blue: 0.5)).frame(width: w * 0.18).position(x: w * 0.18, y: h * 0.18)
                ForEach(0..<3, id: \.self) { i in
                    cloud(w * 0.3).position(x: w * (0.3 + CGFloat(i) * 0.28), y: h * (0.2 + CGFloat(i % 2) * 0.12))
                }
                Hill(rise: 0.2).fill(Color(red: 0.5, green: 0.78, blue: 0.42)).frame(height: h).offset(y: h * 0.2)
                castle(w: w, h: h).position(x: w * 0.5, y: h * 0.62)
            }
        }
        .clipped()
    }
    private func castle(w: CGFloat, h: CGFloat) -> some View {
        let s = min(w, h)
        let stone = Color(red: 0.78, green: 0.66, blue: 0.78)
        return ZStack {
            // towers
            ForEach([-1.0, 0.0, 1.0], id: \.self) { x in
                VStack(spacing: 0) {
                    PolyTriangle().fill(Color(red: 0.85, green: 0.30, blue: 0.42)).frame(width: s * 0.20, height: s * 0.16)
                    Rectangle().fill(stone).frame(width: s * 0.16, height: s * 0.34)
                }
                .offset(x: CGFloat(x) * s * 0.26, y: x == 0 ? -s * 0.06 : 0)
            }
            // wall + gate
            Rectangle().fill(stone).frame(width: s * 0.62, height: s * 0.24).offset(y: s * 0.18)
            RoundedRectangle(cornerRadius: s * 0.05).fill(Color(red: 0.40, green: 0.26, blue: 0.18))
                .frame(width: s * 0.16, height: s * 0.22).offset(y: s * 0.20)
        }
    }
    private func cloud(_ s: CGFloat) -> some View {
        HStack(spacing: -s * 0.08) {
            Circle().fill(.white).frame(width: s * 0.4)
            Circle().fill(.white).frame(width: s * 0.55)
            Circle().fill(.white).frame(width: s * 0.4)
        }
    }
}

struct MeadowScene: View {
    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            ZStack {
                grad([Color(red: 0.62, green: 0.86, blue: 1.0), Color(red: 0.90, green: 0.97, blue: 1.0)])
                Circle().fill(Color(red: 1.0, green: 0.9, blue: 0.4)).frame(width: w * 0.22).position(x: w * 0.82, y: h * 0.2)
                Hill(rise: 0.35).fill(grad([Color(red: 0.55, green: 0.84, blue: 0.42), Color(red: 0.32, green: 0.66, blue: 0.28)])).frame(height: h).offset(y: h * 0.05)
                // flowers
                ForEach(0..<7, id: \.self) { i in
                    flower(w * 0.12, color: petal(i)).position(x: w * (0.10 + CGFloat(i) * 0.13), y: h * (0.7 + CGFloat(i % 3) * 0.07))
                }
                // butterfly
                butterfly(w * 0.12).position(x: w * 0.35, y: h * 0.35)
            }
        }
        .clipped()
    }
    private func petal(_ i: Int) -> Color {
        [Color(red: 1, green: 0.45, blue: 0.55), Color(red: 1, green: 0.8, blue: 0.3),
         Color(red: 0.7, green: 0.5, blue: 1), Color.white][i % 4]
    }
    private func flower(_ s: CGFloat, color: Color) -> some View {
        ZStack {
            Rectangle().fill(Color(red: 0.2, green: 0.6, blue: 0.3)).frame(width: s * 0.08, height: s * 0.9).offset(y: s * 0.5)
            ForEach(0..<5, id: \.self) { i in
                Ellipse().fill(color).frame(width: s * 0.3, height: s * 0.5)
                    .offset(y: -s * 0.22).rotationEffect(.degrees(Double(i) * 72))
            }
            Circle().fill(Color(red: 1, green: 0.85, blue: 0.3)).frame(width: s * 0.26)
        }
    }
    private func butterfly(_ s: CGFloat) -> some View {
        ZStack {
            ForEach([-1.0, 1.0], id: \.self) { x in
                Ellipse().fill(Color(red: 0.95, green: 0.45, blue: 0.7))
                    .frame(width: s * 0.5, height: s * 0.8)
                    .offset(x: CGFloat(x) * s * 0.28)
                    .rotationEffect(.degrees(x * 18))
            }
            Capsule().fill(.black).frame(width: s * 0.08, height: s * 0.7)
        }
    }
}

struct DinoScene: View {
    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            ZStack {
                grad([Color(red: 1.0, green: 0.72, blue: 0.45), Color(red: 0.95, green: 0.45, blue: 0.35)])
                Circle().fill(Color(red: 1.0, green: 0.95, blue: 0.7)).frame(width: w * 0.22).position(x: w * 0.25, y: h * 0.24)
                // volcano
                volcano(w: w, h: h).position(x: w * 0.78, y: h * 0.55)
                // ground
                Hill(rise: 0.18).fill(Color(red: 0.45, green: 0.62, blue: 0.30)).frame(height: h).offset(y: h * 0.25)
                // dino
                dino(min(w, h) * 0.62).position(x: w * 0.42, y: h * 0.66)
                // ferns
                ForEach(0..<3, id: \.self) { i in
                    ForEach(0..<4, id: \.self) { j in
                        Capsule().fill(Color(red: 0.2, green: 0.5, blue: 0.25))
                            .frame(width: w * 0.16, height: w * 0.04)
                            .rotationEffect(.degrees(Double(j) * 25 - 38))
                            .position(x: w * (0.12 + CGFloat(i) * 0.34), y: h * 0.94)
                    }
                }
            }
        }
        .clipped()
    }
    private func volcano(w: CGFloat, h: CGFloat) -> some View {
        let s = min(w, h)
        return ZStack {
            PolyTriangle().fill(Color(red: 0.45, green: 0.32, blue: 0.28)).frame(width: s * 0.5, height: s * 0.5)
            Circle().fill(Color(red: 1, green: 0.5, blue: 0.1)).frame(width: s * 0.12).offset(y: -s * 0.18)
        }
    }
    private func dino(_ s: CGFloat) -> some View {
        let green = Color(red: 0.36, green: 0.66, blue: 0.36)
        return ZStack {
            Ellipse().fill(green).frame(width: s * 0.8, height: s * 0.5)            // body
            Circle().fill(green).frame(width: s * 0.34).offset(x: s * 0.42, y: -s * 0.22) // head
            Capsule().fill(green).frame(width: s * 0.4, height: s * 0.14)            // neck
                .rotationEffect(.degrees(-35)).offset(x: s * 0.28, y: -s * 0.1)
            PolyTriangle().fill(green).frame(width: s * 0.34, height: s * 0.2)       // tail
                .rotationEffect(.degrees(-90)).offset(x: -s * 0.42)
            // plates
            ForEach(0..<4, id: \.self) { i in
                PolyTriangle().fill(Color(red: 0.85, green: 0.45, blue: 0.3))
                    .frame(width: s * 0.16, height: s * 0.18)
                    .offset(x: s * (-0.18 + CGFloat(i) * 0.13), y: -s * 0.24)
            }
            Circle().fill(.white).frame(width: s * 0.10).offset(x: s * 0.5, y: -s * 0.26)
                .overlay(Circle().fill(.black).frame(width: s * 0.05).offset(x: s * 0.5, y: -s * 0.26))
            // legs
            ForEach([-0.18, 0.16], id: \.self) { x in
                RoundedRectangle(cornerRadius: s * 0.04).fill(green)
                    .frame(width: s * 0.12, height: s * 0.22).offset(x: CGFloat(x) * s, y: s * 0.28)
            }
        }
    }
}

#Preview("Poster scenes") {
    ScrollView {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 10)], spacing: 10) {
            ForEach(PosterScene.all) { s in
                s.illustration
                    .frame(width: 160, height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .overlay(alignment: .bottom) {
                        Text(s.name).font(.caption.bold()).padding(4)
                            .background(.black.opacity(0.4)).foregroundStyle(.white)
                    }
            }
        }.padding()
    }
}
