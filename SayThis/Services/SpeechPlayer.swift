import AVFoundation
import Foundation

@MainActor
final class SpeechPlayer {
    private let synthesizer = AVSpeechSynthesizer()

    func speak(_ text: String, accent: Accent, slow: Bool) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: accent.voiceLanguage)
            ?? AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = slow ? 0.38 : AVSpeechUtteranceDefaultSpeechRate
        utterance.pitchMultiplier = 1.0
        utterance.preUtteranceDelay = 0
        synthesizer.speak(utterance)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }
}
