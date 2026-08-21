//
//  WorkoutVoiceManager.swift
//  Fifoo Play
//
//  Created by Daudi Sagala on 8/16/26.
//


import Foundation
import AVFoundation
import Observation


@MainActor
@Observable
final class WorkoutVoiceManager {

    static let shared =
        WorkoutVoiceManager()


    private let synthesizer =
        AVSpeechSynthesizer()


    // MARK: - Mute State

    var isMuted: Bool = false


    private init() {}


    // MARK: - Speak

    func speak(
        _ text: String,
        interruptCurrentSpeech: Bool = true
    ) {

        // Voice announcements are muted.
        // WorkoutSoundManager is completely unaffected.
        guard !isMuted else {
            return
        }


        let trimmedText =
            text.trimmingCharacters(
                in: .whitespacesAndNewlines
            )


        guard !trimmedText.isEmpty else {
            return
        }


        if interruptCurrentSpeech,
           synthesizer.isSpeaking {

            synthesizer.stopSpeaking(
                at: .immediate
            )
        }


        configureAudioSession()


        let utterance =
            AVSpeechUtterance(
                string: trimmedText
            )


        utterance.voice =
            AVSpeechSynthesisVoice(
                language: "en-US"
            )

        utterance.rate =
            0.47

        utterance.pitchMultiplier =
            1.0

        utterance.volume =
            1.0

        utterance.preUtteranceDelay =
            0.15

        utterance.postUtteranceDelay =
            0.1


        synthesizer.speak(
            utterance
        )
    }


    // MARK: - Mute

    func mute() {

        isMuted = true

        /*
         Stop an announcement that is already speaking.
        */

        if synthesizer.isSpeaking {

            synthesizer.stopSpeaking(
                at: .immediate
            )
        }
    }


    // MARK: - Unmute

    func unmute() {

        isMuted = false
    }


    // MARK: - Toggle

    func toggleMute() {

        if isMuted {

            unmute()

        } else {

            mute()
        }
    }


    // MARK: - Stop

    func stop() {

        guard synthesizer.isSpeaking else {
            return
        }

        synthesizer.stopSpeaking(
            at: .immediate
        )
    }


    // MARK: - Audio Session

    private func configureAudioSession() {

        let audioSession =
            AVAudioSession.sharedInstance()

        do {

            try audioSession.setCategory(
                .playback,
                mode: .spokenAudio,
                options: [
                    .duckOthers
                ]
            )

            try audioSession.setActive(
                true,
                options:
                    .notifyOthersOnDeactivation
            )

        } catch {

            print(
                "Workout voice audio error:",
                error
            )
        }
    }
}
