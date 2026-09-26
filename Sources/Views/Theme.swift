import SwiftUI

extension Color {
    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: h).scanHexInt64(&int)
        let r, g, b: UInt64
        switch h.count {
        case 6: (r, g, b) = (int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (r, g, b) = (200, 200, 200)
        }
        self.init(.sRGB,
                  red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255,
                  opacity: 1)
    }
}

enum Theme {
    static let bgTop = Color(hex: "#67C8FF")
    static let bgBottom = Color(hex: "#A78BFA")
    static let ink = Color(hex: "#2B2350")
    static let sun = Color(hex: "#FFCD3C")
    static let grass = Color(hex: "#5BD16B")
    static let coral = Color(hex: "#FF7E6B")

    static func background(_ a: Color, _ b: Color) -> some View {
        LinearGradient(colors: [a, b], startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
    }

    /// Deep-space gradient shared by the map backdrop and the 3D-lesson backdrop.
    static let spaceColors = [Color(hex: "#0A1130"), Color(hex: "#241A47"), Color(hex: "#3A2A6B")]
    static func spaceGradient() -> LinearGradient {
        LinearGradient(colors: spaceColors, startPoint: .top, endPoint: .bottom)
    }

    static let rounded = Font.Design.rounded
}

/// Big tappable candy button used everywhere.
struct CandyButton: View {
    let title: String
    var systemImage: String? = nil
    var color: Color = Theme.coral
    var textColor: Color = .white
    let action: () -> Void

    @State private var pressed = false

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            HStack(spacing: 14) {
                if let s = systemImage { Image(systemName: s) }
                Text(title)
            }
            .font(.system(size: 34, weight: .heavy, design: .rounded))
            .foregroundStyle(textColor)
            .padding(.horizontal, 44)
            .padding(.vertical, 22)
            .background(
                Capsule().fill(color)
                    .shadow(color: color.opacity(0.5), radius: 10, y: 6)
            )
            .overlay(Capsule().stroke(.white.opacity(0.6), lineWidth: 3))
            .scaleEffect(pressed ? 0.94 : 1)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(title)
        .simultaneousGesture(DragGesture(minimumDistance: 0)
            .onChanged { _ in withAnimation(.easeOut(duration: 0.08)) { pressed = true } }
            .onEnded { _ in withAnimation(.spring(response: 0.3)) { pressed = false } })
    }
}

/// One letter / digraph tile shown in the blending row.
struct LetterTile: View {
    let text: String
    var highlighted: Bool = false
    var silent: Bool = false
    var color: Color = .white

    var body: some View {
        Text(text)
            .font(.system(size: 84, weight: .black, design: .rounded))
            .foregroundStyle(silent ? Theme.ink.opacity(0.3) : Theme.ink)
            .frame(minWidth: 96)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(highlighted ? Theme.sun : color)
                    .shadow(color: .black.opacity(0.12), radius: 6, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(highlighted ? Theme.coral : .clear, lineWidth: 5)
            )
            .scaleEffect(highlighted ? 1.12 : 1)
            .animation(AppEnv.uiTesting ? nil : .spring(response: 0.28, dampingFraction: 0.6), value: highlighted)
    }
}

struct StarRow: View {
    let count: Int          // 0...3
    var size: CGFloat = 36
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { i in
                Image(systemName: i < count ? "star.fill" : "star")
                    .font(.system(size: size))
                    .foregroundStyle(i < count ? Theme.sun : .white.opacity(0.5))
            }
        }
    }
}

enum Haptics {
    static func tap() {
        #if canImport(UIKit)
        let g = UIImpactFeedbackGenerator(style: .soft)
        g.impactOccurred()
        #endif
    }
    static func success() {
        #if canImport(UIKit)
        let g = UINotificationFeedbackGenerator()
        g.notificationOccurred(.success)
        #endif
    }
}
