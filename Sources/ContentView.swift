import SwiftUI

/// Root: pick a player (by tapping an animal — no reading needed), then the map.
struct RootView: View {
    @EnvironmentObject var store: ProfileStore

    var body: some View {
        Group {
            if AppEnv.previewParent {
                ParentProgressView()
            } else if let lid = AppEnv.lessonID,
                      let lesson = Curriculum.allLessons.first(where: { $0.id == lid }) {
                WorldLessonView(lesson: lesson)
            } else if let bid = AppEnv.bookID,
                      let story = Curriculum.allLessons.first(where: { $0.id == bid }) {
                BookReaderView(lesson: story)
            } else if AppEnv.sliceMode {
                WorldLessonView(lesson: Curriculum.firstLesson)
            } else if AppEnv.soundCheck {
                SoundCheckView()
            } else if AppEnv.giftDemo {
                StickerGiftCelebration(sticker: "🦊", total: 3)
            } else if AppEnv.mosaicDemo {
                LessonCelebrationView(stars: 3, scene: .rocket, tilesStart: 15, posterCompleted: true)
            } else if AppEnv.strokeSheet {
                StrokeSheetView()
            } else if let tl = AppEnv.traceDemo {
                ZStack {
                    Theme.background(Theme.bgTop, Theme.bgBottom)
                    VStack(spacing: 16) {
                        TracingView(letter: tl, reps: LetterLand.traceReps(tl), onRep: {
                            if let m = LetterLand.mnemonic(tl) { SpeechManager.shared.speak(m) }
                        }).frame(width: 320, height: 360)
                            .background(RoundedRectangle(cornerRadius: 28).fill(.white))
                        if let m = LetterLand.mnemonic(tl) {
                            Text("👶 \(m)")
                                .font(.system(size: 19, weight: .heavy, design: .rounded)).foregroundStyle(Theme.sun)
                        }
                    }
                }
            } else if store.current == nil {
                ProfilePickerView()
                    .transition(.opacity)
            } else if let pid = store.currentID, !AppEnv.uiTesting,
                      !store.placementDone(for: pid), !store.worldStarted(for: pid) {
                // First entry into this language world: pick a starting point
                // (or run the quick check) before the map opens.
                PlacementView()
                    .transition(.opacity)
            } else {
                MapView()
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: store.currentID)
        .onAppear { MusicPlayer.shared.start() }
    }
}

struct ProfilePickerView: View {
    @EnvironmentObject var store: ProfileStore
    @State private var renaming: Profile? = nil
    @State private var draftName = ""

    private let columns = [GridItem(.adaptive(minimum: 220), spacing: 28)]

    var body: some View {
        ZStack {
            Theme.background(Theme.bgTop, Theme.bgBottom)

            VStack(spacing: 36) {
                VStack(spacing: 8) {
                    Text("🚀 Read Rocket")
                        .font(.system(size: 60, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(radius: 6, y: 3)
                    Text(Languages.active.t("who_reads"))
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.95))
                }

                LazyVGrid(columns: columns, spacing: 28) {
                    ForEach(store.profiles) { p in
                        Button {
                            store.select(p.id)   // sets this child's language first
                            SpeechManager.shared.speakGreeting(Languages.active.t("hi_lets_read"), name: p.name)
                        } label: {
                            VStack(spacing: 10) {
                                Critter(kind: critterKind(forProfile: p.id), size: 120)
                                Text(p.name.uppercased())
                                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                                    .foregroundStyle(Theme.ink)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 28)
                            .background(
                                RoundedRectangle(cornerRadius: 32, style: .continuous)
                                    .fill(.white)
                                    .shadow(color: .black.opacity(0.15), radius: 10, y: 6)
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("profile_\(p.id)")
                        .contextMenu {
                            Button {
                                draftName = p.name; renaming = p
                            } label: { Label("Rename", systemImage: "pencil") }
                        }
                    }
                }
                .padding(.horizontal, 30)

                Text("Hold a card to rename")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.8))
            }
            .padding(.vertical, 40)
        }
        .overlay(alignment: .topTrailing) { MusicButton().padding(20) }
        .onAppear {
            SpeechManager.shared.speak(Languages.active.t("who_reads"))
        }
        .alert("Name", isPresented: Binding(get: { renaming != nil },
                                            set: { if !$0 { renaming = nil } })) {
            TextField("Name", text: $draftName)
                .textInputAutocapitalization(.characters)   // names default to ALL CAPS
            Button("Save") { if let p = renaming { store.rename(p.id, to: draftName) }; renaming = nil }
            Button("Cancel", role: .cancel) { renaming = nil }
        }
    }
}
