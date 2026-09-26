import SwiftUI

/// Grown-ups screen: a read-only progress summary for each child profile.
/// Reached by long-pressing the gear on the map (kid-resistant), with a close
/// button always present so it can never trap a child.
struct ParentProgressView: View {
    @EnvironmentObject var store: ProfileStore
    @Environment(\.dismiss) private var dismiss
    @State private var showSounds = false
    @State private var showPlacement = false

    private var totalLessons: Int { Curriculum.lessonOrder.count }

    var body: some View {
        ZStack {
            Theme.background(Theme.bgTop, Theme.bgBottom)
            VStack(spacing: 18) {
                HStack {
                    Text("Grown-ups")
                        .font(.system(size: 36, weight: .black, design: .rounded))
                        .foregroundStyle(.white).shadow(radius: 3, y: 2)
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 36)).foregroundStyle(.white.opacity(0.9))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("parent_close")
                }
                .padding(.horizontal, 26).padding(.top, 22)

                Button { showSounds = true } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "speaker.wave.2.fill")
                        Text("Check sounds")
                    }
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Capsule().fill(Theme.coral)
                        .shadow(color: Theme.coral.opacity(0.4), radius: 8, y: 4))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("open_soundcheck")
                .padding(.horizontal, 26)

                // Re-run placement any time (e.g. the child leveled up outside the
                // app, or started too low). Placement only ADDS passed lessons —
                // it never takes earned progress away.
                Button { showPlacement = true } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "figure.stairs")
                        Text(Languages.active.t("placement_title"))
                    }
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundStyle(Theme.ink)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Capsule().fill(.white)
                        .shadow(color: .black.opacity(0.15), radius: 8, y: 4))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("open_placement")
                .padding(.horizontal, 26)

                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(store.profiles) { p in
                            HStack(spacing: 16) {
                                Critter(kind: critterKind(forProfile: p.id), size: 74)
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(p.name.uppercased())
                                        .font(.system(size: 26, weight: .heavy, design: .rounded))
                                        .foregroundStyle(Theme.ink)
                                    Text("\(store.completedCount(for: p.id)) of \(totalLessons) lessons")
                                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                                        .foregroundStyle(Theme.ink.opacity(0.75))
                                    HStack(spacing: 18) {
                                        Label("\(store.totalStars(for: p.id))", systemImage: "star.fill")
                                        Label("\(store.postersCollected(for: p.id))", systemImage: "photo.on.rectangle.angled")
                                        Label("\(store.currentStreak(for: p.id))", systemImage: "flame.fill")
                                    }
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundStyle(Theme.ink.opacity(0.8))
                                    Text("On: \(store.currentUnitTitle(for: p.id))")
                                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                                        .foregroundStyle(Theme.ink.opacity(0.6))
                                    Text("Mastered \(store.masteredCount(for: p.id)) words · practicing \(store.practicingCount(for: p.id))")
                                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                                        .foregroundStyle(Theme.ink.opacity(0.6))
                                    Text(store.goalMetToday(for: p.id) ? "Today: done ✓" : "Today's goal: 1 lesson")
                                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                                        .foregroundStyle(store.goalMetToday(for: p.id) ? Theme.grass : Theme.ink.opacity(0.5))
                                }
                                Spacer()
                            }
                            .padding(18)
                            .background(
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .fill(.white)
                                    .shadow(color: .black.opacity(0.12), radius: 6, y: 3)
                            )
                        }
                    }
                    .padding(.horizontal, 22).padding(.bottom, 24)
                }
            }
        }
        .fullScreenCover(isPresented: $showSounds) {
            SoundCheckView(done: { showSounds = false })
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
