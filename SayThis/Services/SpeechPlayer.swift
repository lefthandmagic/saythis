import AVFoundation
import Observation

@MainActor
@Observable
final class SpeechPlayer {
    private let engine = SpeechEngine()
    private(set) var isSpeaking = false
    private(set) var slow = false

    init() {
        engine.onSpeaking = { [weak self] speaking in
            Task { @MainActor in
                self?.isSpeaking = speaking
            }
        }
        _ = AVSpeechSynthesisVoice.speechVoices()
    }

    func speak(_ text: String, accent: Accent, slow: Bool) {
        let spoken = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !spoken.isEmpty else { return }
        Self.activatePlaybackSession()
        self.slow = slow

        let utterance = AVSpeechUtterance(string: spoken)
        utterance.voice = Self.voice(for: accent)
        utterance.rate = slow
            ? AVSpeechUtteranceDefaultSpeechRate * 0.42
            : AVSpeechUtteranceDefaultSpeechRate
        utterance.volume = 1
        engine.speak(utterance)
    }

    func stop() {
        engine.stop()
        isSpeaking = false
    }

    /// Playback ignores the ringer switch. The default session stays silent on a phone.
    private static func activatePlaybackSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        try? session.setActive(true)
    }

    private static func voice(for accent: Accent) -> AVSpeechSynthesisVoice? {
        let code = accent.voiceLanguage
        let voices = AVSpeechSynthesisVoice.speechVoices()
        return voices.first { $0.language == code }
            ?? voices.first { $0.language.hasPrefix(String(code.prefix(2))) }
            ?? AVSpeechSynthesisVoice(language: code)
            ?? AVSpeechSynthesisVoice(language: "en-US")
    }
}

private final class SpeechEngine: NSObject, AVSpeechSynthesizerDelegate {
    let synthesizer = AVSpeechSynthesizer()
    var onSpeaking: ((Bool) -> Void)?
    private var queued: AVSpeechUtterance?

    override init() {
        super.init()
        synthesizer.delegate = self
        synthesizer.usesApplicationAudioSession = true
    }

    func speak(_ utterance: AVSpeechUtterance) {
        if synthesizer.isSpeaking {
            queued = utterance
            synthesizer.stopSpeaking(at: .immediate)
            return
        }
        queued = nil
        synthesizer.speak(utterance)
    }

    func stop() {
        queued = nil
        synthesizer.stopSpeaking(at: .immediate)
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { self.onSpeaking?(true) }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { self.continueOrFinish() }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { self.continueOrFinish() }
    }

    private func continueOrFinish() {
        if let queued {
            self.queued = nil
            synthesizer.speak(queued)
        } else {
            onSpeaking?(false)
        }
    }
}
