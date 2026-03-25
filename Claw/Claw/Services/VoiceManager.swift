import Foundation
import Speech
import AVFoundation

@MainActor
final class VoiceManager: NSObject, ObservableObject {
    @Published var isListening = false
    @Published var transcript = ""
    @Published var isPlaying = false

    private var audioEngine = AVAudioEngine()
    private var speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioPlayer: AVAudioPlayer?

    // MARK: - Permissions

    func requestPermissions() {
        SFSpeechRecognizer.requestAuthorization { _ in }
        AVAudioSession.sharedInstance().requestRecordPermission { _ in }
    }

    // MARK: - Speech to Text

    func startListening() {
        guard !isListening else { return }
        guard SFSpeechRecognizer.authorizationStatus() == .authorized else {
            requestPermissions()
            return
        }

        transcript = ""
        isListening = true

        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try? audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest?.shouldReportPartialResults = true

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest!) { [weak self] result, error in
            Task { @MainActor in
                if let result = result {
                    self?.transcript = result.bestTranscription.formattedString
                }
                if error != nil || (result?.isFinal ?? false) {
                    self?.stopListeningInternal()
                }
            }
        }

        audioEngine.prepare()
        try? audioEngine.start()
    }

    func stopListening() {
        guard isListening else { return }
        stopListeningInternal()
    }

    private func stopListeningInternal() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        isListening = false
        try? AVAudioSession.sharedInstance().setActive(false)
    }

    // MARK: - Text to Speech (ElevenLabs via server)

    func speak(_ text: String) async {
        isPlaying = true
        defer { Task { @MainActor in isPlaying = false } }

        do {
            let data = try await APIClient.shared.requestTTS(text)
            try? AVAudioSession.sharedInstance().setCategory(.playback)
            try? AVAudioSession.sharedInstance().setActive(true)
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.play()

            // Wait for playback to finish
            while audioPlayer?.isPlaying == true {
                try? await Task.sleep(for: .milliseconds(200))
            }
        } catch {
            print("TTS error: \(error)")
        }
    }

    func stopSpeaking() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
    }
}
