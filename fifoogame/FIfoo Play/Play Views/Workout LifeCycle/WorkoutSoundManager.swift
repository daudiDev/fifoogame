//
//  WorkoutSoundManager.swift
//  Fifoo Play
//
//  Created by Daudi Sagala on 8/17/26.
//

import AVFoundation


@MainActor
final class WorkoutSoundManager {

    static let shared = WorkoutSoundManager()

    private var swishPlayer: AVAudioPlayer?


    private init() {}


    // MARK: - Play swish
    func playSwish() {

        guard let url =
            Bundle.main.url(
                forResource: "swish",
                withExtension: "wav"
            )
        else {
            print("❌ swish.wav not found")
            return
        }


        // MARK: Validate File

        guard let attributes =
                try? FileManager.default
                    .attributesOfItem(
                        atPath: url.path
                    ),
              let fileSize =
                attributes[.size]
                    as? NSNumber,
              fileSize.intValue > 0
        else {

            print(
                "❌ swish.wav is missing or empty"
            )

            return
        }


        do {

            /*
             Create the player on demand.

             For a tiny transition sound this is much
             simpler than preloading audio buffers during
             singleton initialization.
            */

            let player =
                try AVAudioPlayer(
                    contentsOf: url
                )

            player.volume = 0.7

            swishPlayer =
                player

            swishPlayer?.play()


        } catch {

            print(
                "❌ Could not play swish:",
                error
            )
        }
    }
    
    func playLevelUp() {

        guard let url =
            Bundle.main.url(
                forResource: "levelup",
                withExtension: "wav"
            )
        else {
            print("❌ levelup.wav not found")
            return
        }


        // MARK: Validate File

        guard let attributes =
                try? FileManager.default
                    .attributesOfItem(
                        atPath: url.path
                    ),
              let fileSize =
                attributes[.size]
                    as? NSNumber,
              fileSize.intValue > 0
        else {

            print(
                "❌ levelup.wav is missing or empty"
            )

            return
        }


        do {

            /*
             Create the player on demand.

             For a tiny transition sound this is much
             simpler than preloading audio buffers during
             singleton initialization.
            */

            let player =
                try AVAudioPlayer(
                    contentsOf: url
                )

            player.volume = 0.7

            swishPlayer =
                player

            swishPlayer?.play()


        } catch {

            print(
                "❌ Could not play swish:",
                error
            )
        }
    }
}
