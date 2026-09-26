import SwiftUI

struct MapView: View {
    @EnvironmentObject var store: ProfileStore
    @State private var active: Lesson? = nil
    @State private var showStickers = false
    private let order = Curriculum.lessonOrder

    /// Review due? It joins the ONE flow as the highlighted next node — no
    /// separate button, no daily choice. Needs ≥3 genuinely-missed words.
    private var dueReview: Lesson? {
        let missed = store.reviewWords(limit: 4)
        guard missed.count >= 3 else { return nil }
        return Curriculum.dailyReview(missed: missed,
                                      mastered: store.masteredSample(limit: 2, excluding: Set(missed)))
    }

    var body: some View {
        let currentIdx = store.currentLessonIndex(order: order)
        let review = dueReview
        return ZStack(alignment: .top) {
            SpaceBackdrop()

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 0) {
                        Color.clear.frame(height: 86)
                        ForEach(Curriculum.units) { unit in
                            UnitBanner(unit: unit)
                                .padding(.top, 16)
                                .padding(.bottom, 10)
                            // DENSE grid — a whole unit fits one screen instead
                            // of one long mega-scroll of single nodes.
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 126), spacing: 12)],
                                      spacing: 16) {
                                ForEach(unit.lessons) { lesson in
                                    let gi = order.firstIndex(of: lesson.id) ?? 0
                                    if gi == currentIdx, let review {
                                        CompactNode(lesson: review, unit: unit, unlocked: true,
                                                    stars: 0, isCurrent: true, isReview: true) {
                                            active = review
                                        }
                                    }
                                    CompactNode(
                                        lesson: lesson, unit: unit,
                                        unlocked: store.isUnlocked(lesson.id, order: order),
                                        stars: store.stars(lesson.id),
                                        isCurrent: gi == currentIdx && review == nil,
                                        isReview: false
                                    ) { active = lesson }
                                    .id(lesson.id)
                                }
                            }
                            .padding(.horizontal, 26)
                        }
                        Color.clear.frame(height: 60)
                    }
                }
                .onAppear {
                    let idx = min(currentIdx, order.count - 1)
                    if idx >= 0 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation { proxy.scrollTo(order[idx], anchor: .center) }
                        }
                    }
                }
            }

            HeaderBar(onStickers: { showStickers = true })
        }
        .fullScreenCover(item: $active) { lesson in
            WorldLessonView(lesson: lesson, done: { active = nil }).environmentObject(store)
        }
        .sheet(isPresented: $showStickers) {
            StickerBookView().environmentObject(store)
        }
    }
}

private struct HeaderBar: View {
    @EnvironmentObject var store: ProfileStore
    var onStickers: () -> Void = {}
    @State private var showParent = false
    @State private var showLibrary = false
    @State private var showPlacement = false
    @State private var gate: ParentalGate? = nil
    /// Where a passed parental gate leads: grown-ups area, or straight to placement.
    @State private var gateOpensPlacement = false

    var body: some View {
        HStack {
            Button { store.currentID = nil } label: {
                HStack(spacing: 8) {
                    Text(store.current?.emoji ?? "🦊").font(.system(size: 32))
                    Image(systemName: "arrow.left.arrow.right.circle.fill")
                        .font(.system(size: 22)).foregroundStyle(.white.opacity(0.9))
                }
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(Capsule().fill(.white.opacity(0.25)))
            }
            .buttonStyle(.plain)

            // Settings: a plain TAP opens the parental gate (App Review tapped this
            // and saw nothing happen — the old long-press-only was a dead button).
            // The math gate is the kid-proofing now, not a hidden gesture.
            Button { Haptics.tap(); gateOpensPlacement = false; gate = ParentalGate() } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white.opacity(0.55))
                    .padding(8)
                    .background(Circle().fill(.white.opacity(0.18)))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("parent_open")
            .padding(.leading, 8)

            // Growing companion buddy — levels up as the kids learn. Tapping it
            // (behind the gate) jumps straight to the placement check, so a
            // grown-up can re-level the child any time.
            Button { Haptics.tap(); gateOpensPlacement = true; gate = ParentalGate() } label: {
                HStack(spacing: 6) {
                    Critter(kind: critterKind(forProfile: store.currentID ?? "fox"),
                            size: CGFloat(30 + min(6, store.completedCount() / 4) * 4))
                    Text("Lv \(1 + store.completedCount() / 4)")
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 10).padding(.vertical, 4)
                .background(Capsule().fill(.white.opacity(0.18)))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("level_open")
            .padding(.leading, 8)

            Spacer()

            // Language picker — each child can learn multiple languages, each its
            // own separate world (map, progress, posters).
            Menu {
                ForEach(Languages.all, id: \.id) { pack in
                    Button { store.setLanguage(pack.id) } label: {
                        Label("\(pack.flag)  \(pack.nativeName)",
                              systemImage: store.currentLanguage == pack.id ? "checkmark" : "")
                    }
                }
            } label: {
                Text(Languages.pack(store.currentLanguage).flag)
                    .font(.system(size: 24))
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(.white.opacity(0.22)))
            }
            .accessibilityIdentifier("language_picker")
            .padding(.trailing, 6)

            Button { showLibrary = true } label: {
                Image(systemName: "books.vertical.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(8)
                    .background(Circle().fill(.white.opacity(0.22)))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("open_library")
            .padding(.trailing, 6)

            Button { onStickers() } label: {
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(8)
                    .background(Circle().fill(.white.opacity(0.22)))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("stickers_open")
            .padding(.trailing, 6)

            MusicButton()
                .padding(.trailing, 6)

            if store.currentStreak() > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill").foregroundStyle(Theme.coral)
                    Text("\(store.currentStreak())")
                        .font(.system(size: 26, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 16).padding(.vertical, 8)
                .background(Capsule().fill(.white.opacity(0.25)))
                .padding(.trailing, 6)
            }

            HStack(spacing: 6) {
                Image(systemName: "star.fill").foregroundStyle(Theme.sun)
                Text("\(store.totalStars())")
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 18).padding(.vertical, 8)
            .background(Capsule().fill(.white.opacity(0.25)))
        }
        .padding(.horizontal, 20).padding(.top, 12)
        .sheet(isPresented: $showParent) {
            ParentProgressView().environmentObject(store)
        }
        .fullScreenCover(isPresented: $showLibrary) {
            LibraryView(done: { showLibrary = false })
        }
        .sheet(item: $gate) { g in
            ParentalGateView(gate: g) { passed in
                gate = nil
                guard passed else { return }
                if gateOpensPlacement { showPlacement = true } else { showParent = true }
            }
        }
        .fullScreenCover(isPresented: $showPlacement) {
            PlacementView(done: { showPlacement = false })
                .environmentObject(store)
                .overlay(alignment: .topTrailing) {
                    Button { showPlacement = false } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 34)).foregroundStyle(.white.opacity(0.9))
                    }
                    .buttonStyle(.plain).padding(20)
                    .accessibilityIdentifier("placement_close")
                }
        }
    }
}

private struct UnitBanner: View {
    let unit: Unit
    var body: some View {
        Text(unit.title.uppercased())
            .font(.system(size: 22, weight: .black, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 26).padding(.vertical, 10)
            .background(
                Capsule().fill(
                    LinearGradient(colors: [Color(hex: unit.colorA), Color(hex: unit.colorB)],
                                   startPoint: .leading, endPoint: .trailing)
                )
                .shadow(color: .black.opacity(0.2), radius: 6, y: 3)
            )
            .overlay(Capsule().stroke(.white.opacity(0.6), lineWidth: 2))
    }
}

/// Compact grid node — small enough that a whole unit fits one screen.
/// The single CURRENT node (or the inline review node) pulses gold; finished
/// nodes stay replayable; everything ahead is locked.
private struct CompactNode: View {
    let lesson: Lesson
    let unit: Unit
    let unlocked: Bool
    let stars: Int
    let isCurrent: Bool
    let isReview: Bool
    let tap: () -> Void

    @State private var pulse = false

    var body: some View {
        Button {
            if unlocked { Haptics.tap(); tap() }
            else if !AppEnv.uiTesting { SpeechManager.shared.speak(Languages.active.t("locked_hint")) }
        } label: {
            VStack(spacing: 5) {
                ZStack {
                    Circle()
                        .fill(unlocked
                              ? AnyShapeStyle(LinearGradient(
                                    colors: isReview ? [Theme.sun, Theme.coral]
                                                     : [Color(hex: unit.colorA), Color(hex: unit.colorB)],
                                    startPoint: .top, endPoint: .bottom))
                              : AnyShapeStyle(Color.white.opacity(0.3)))
                        .frame(width: 84, height: 84)
                        .overlay(Circle().stroke(.white, lineWidth: 4))
                        .shadow(color: .black.opacity(0.18), radius: 6, y: 4)

                    if unlocked {
                        Text(lesson.icon).font(.system(size: 42))
                    } else {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundStyle(.white.opacity(0.85))
                    }

                    if isCurrent && unlocked {
                        Circle().stroke(Theme.sun, lineWidth: 5)
                            .frame(width: 96, height: 96)
                            .scaleEffect(pulse ? 1.1 : 1)
                            .opacity(pulse ? 0.25 : 1)
                        Text("🚀")
                            .font(.system(size: 34))
                            .offset(y: -58)
                            .accessibilityHidden(true)
                    }
                }
                .padding(.top, isCurrent ? 26 : 0)

                Text(lesson.title)
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white.opacity(unlocked ? 1 : 0.65))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(height: 34, alignment: .top)
                    .shadow(radius: 2, y: 1)

                StarRow(count: stars, size: 12)
                    .opacity(unlocked && stars > 0 ? 1 : 0)
            }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(isReview ? "lesson_review" : "lesson_\(lesson.id)")
        .onAppear {
            if isCurrent && !AppEnv.uiTesting {
                withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) { pulse = true }
            }
        }
    }
}

/// Deep-space gradient + a static, deterministic starfield. No animation so the
/// map stays "idle" for XCUITest. Ties the journey together with the 3D worlds.
struct SpaceBackdrop: View {
    var body: some View {
        ZStack {
            Theme.spaceGradient()
            Canvas { ctx, size in
                var seed: UInt64 = 0x5EED1234
                func rnd() -> Double {
                    seed = seed &* 6364136223846793005 &+ 1442695040888963407
                    return Double(seed >> 11) / Double(UInt64(1) << 53)
                }
                for _ in 0..<160 {
                    let x = rnd() * size.width, y = rnd() * size.height
                    let r = 0.6 + rnd() * 1.9
                    let o = 0.2 + rnd() * 0.65
                    ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: r, height: r)),
                             with: .color(.white.opacity(o)))
                }
            }
            .accessibilityHidden(true)
        }
        .ignoresSafeArea()
    }
}
