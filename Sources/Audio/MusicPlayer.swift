import Foundation
import AVFoundation
import Combine
import SwiftUI

/// Looping background music (CC0 Kenney tracks). Ducks under speech, persists the
/// on/off + chosen track, and stays silent in UI tests.
final class MusicPlayer: ObservableObject {
    static let shared = MusicPlayer()

    struct Track { let file: String; let name: String }
    let tracks: [Track] = [
        Track(file: "music_beach", name: "Beach"),
        Track(file: "music_farm",  name: "Farm"),
        Track(file: "music_flow",  name: "Flowing")
    ]

    @Published var enabled: Bool { didSet { UserDefaults.standard.set(enabled, forKey: enabledKey); apply() } }
    @Published var trackIndex: Int { didSet { UserDefaults.standard.set(trackIndex, forKey: trackKey); reloadIfPlaying() } }

    private let enabledKey = "readrocket.music.enabled"
    private let trackKey = "readrocket.music.track"
    private var player: AVAudioPlayer?
    private var cancellable: AnyCancellable?
    private var resumeWork: DispatchWorkItem?
    private let baseVolume: Float = 0.13
    private let partyVolume: Float = 0.85
    private var celebrating = false
    private var celebrateRestore: DispatchWorkItem?

    private init() {
        let d = UserDefaults.standard
        enabled = d.object(forKey: enabledKey) == nil ? true : d.bool(forKey: enabledKey)
        trackIndex = d.integer(forKey: trackKey)
    }

    /// Call once when the app appears.
    func start() {
        guard !AppEnv.uiTesting else { return }
        _ = SpeechManager.shared   // make sure the audio session is configured
        cancellable = SpeechManager.shared.$isSpeaking
            .receive(on: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] speaking in
                guard let self else { return }
                if speaking {
                    // Fully pause while sounding out so the sounds are crystal clear.
                    self.resumeWork?.cancel()
                    self.player?.pause()
                } else {
                    // Resume shortly after the last sound, unless more speech starts
                    // (prevents music swelling between rapid letter taps).
                    let work = DispatchWorkItem { [weak self] in
                        guard let self, self.enabled, !SpeechManager.shared.isSpeaking else { return }
                        self.player?.setVolume(self.celebrating ? self.partyVolume : self.baseVolume, fadeDuration: 0.3)
                        self.player?.play()
                    }
                    self.resumeWork = work
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6, execute: work)
                }
            }
        apply()
    }

    private func apply() {
        guard !AppEnv.uiTesting else { return }
        if enabled {
            if player == nil { load() }
            player?.play()
        } else {
            player?.pause()
        }
    }

    private func reloadIfPlaying() {
        guard enabled, !AppEnv.uiTesting else { return }
        load(); player?.play()
    }

    private func load() {
        let i = max(0, min(trackIndex, tracks.count - 1))
        guard let url = Bundle.main.url(forResource: tracks[i].file, withExtension: "m4a") else {
            player = nil; return
        }
        player = try? AVAudioPlayer(contentsOf: url)
        player?.numberOfLoops = -1
        player?.volume = baseVolume
        player?.prepareToPlay()
    }

    func toggle() { enabled.toggle() }
    var currentName: String { tracks[max(0, min(trackIndex, tracks.count - 1))].name }

    /// Swell the background track up to full for a celebration, then ease it back
    /// down to the quiet bed after `seconds`. No-op if the child turned music off
    /// (we never force audio on) or under UI tests.
    func celebrate(seconds: Double) {
        guard !AppEnv.uiTesting, enabled else { return }
        if player == nil { load() }
        resumeWork?.cancel()
        celebrating = true
        player?.setVolume(partyVolume, fadeDuration: 0.5)
        player?.play()
        let restore = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.celebrating = false
            self.player?.setVolume(self.baseVolume, fadeDuration: 1.2)
        }
        celebrateRestore?.cancel()
        celebrateRestore = restore
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: restore)
    }
}

/// Reusable music on/off button with a track picker in its context menu.
struct MusicButton: View {
    @ObservedObject private var music = MusicPlayer.shared

    var body: some View {
        Button {
            Haptics.tap(); music.toggle()
        } label: {
            Image(systemName: music.enabled ? "music.note" : "music.note")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(music.enabled ? .white : .white.opacity(0.4))
                .padding(10)
                .background(Circle().fill(.white.opacity(0.22)))
                .overlay {
                    if !music.enabled {
                        Capsule().fill(.white.opacity(0.85))
                            .frame(width: 30, height: 3).rotationEffect(.degrees(-45))
                    }
                }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("music_toggle")
        .contextMenu {
            Button(music.enabled ? "Turn music off" : "Turn music on") { music.toggle() }
            Divider()
            ForEach(0..<music.tracks.count, id: \.self) { i in
                Button {
                    music.trackIndex = i
                    if !music.enabled { music.enabled = true }
                } label: {
                    Label(music.tracks[i].name,
                          systemImage: music.trackIndex == i ? "checkmark" : "music.note")
                }
            }
        }
    }
}
