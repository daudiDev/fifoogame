//
//  FullScreenVideoView.swift
//  Fifoo Play
//
//  Created by Daudi Sagala on 8/10/26.
//

import SwiftUI
import AVKit


// MARK: - Video Player Cache

@MainActor
final class ExerciseVideoCache {

    static let shared =
        ExerciseVideoCache()

    private var players:
        [URL: AVPlayer] = [:]

    private init() { }


    // MARK: Player

    func player(
        for url: URL
    ) -> AVPlayer {

        // Already created/preloaded.
        if let existingPlayer =
            players[url] {

            return existingPlayer
        }


        // MARK: Create Player Item

        let item =
            AVPlayerItem(
                url: url
            )

        // Keep a small forward buffer so the video
        // is ready when it becomes the current exercise.
        item.preferredForwardBufferDuration = 5


        // MARK: Create Player

        let player =
            AVPlayer(
                playerItem: item
            )

        player.automaticallyWaitsToMinimizeStalling = true


        // Cache the player.
        players[url] = player


        return player
    }


    // MARK: Preload

    func preload(
        url: URL
    ) {

        let player =
            player(
                for: url
            )

        // Force AVPlayer to begin preparing its asset/item
        // without actually playing it for the user.
        player.pause()

        player.currentItem?
            .preferredForwardBufferDuration = 5
    }


    // MARK: Remove Player

    func removePlayer(
        for url: URL
    ) {

        guard let player =
                players[url] else {
            return
        }

        player.pause()

        players[url] = nil
    }


    // MARK: Remove Everything

    func removeAll() {

        for player in
            players.values {

            player.pause()
        }

        players.removeAll()
    }
}


// MARK: - Full Screen Video

struct FullScreenVideoView: View {

    let url: URL

    /// True only when this exercise is actually the
    /// current visible workout exercise.
    ///
    /// The next TikTok page should pass false so that
    /// its video can preload without playing.
    let isActive: Bool


    @State private var player:
        AVPlayer?


    var body: some View {

        ZStack {

            // MARK: Background

            Color.black
                .ignoresSafeArea()


            // MARK: Video

            if let player {

                VideoPlayer(
                    player: player
                )
                .ignoresSafeArea()
                .transition(
                    .identity
                )

            } else {

                // Avoid flashing a ProgressView between
                // exercise page transitions.
                Color.black
                    .ignoresSafeArea()
            }
        }

        // MARK: Load / Preload

        .task(
            id: url
        ) {

            configurePlayer()
        }

        // MARK: Current Page Changed

        .onChange(
            of: isActive
        ) { _, newValue in

            updatePlayback(
                isActive: newValue
            )
        }

        // MARK: View Appeared

        .onAppear {

            if player == nil {

                configurePlayer()
            }

            updatePlayback(
                isActive: isActive
            )
        }

        // IMPORTANT:
        //
        // Do NOT blindly pause here.
        //
        // During a TikTok page transition, the same cached
        // AVPlayer may already have become the player for
        // the new current page.
        //
        // Playback is controlled by `isActive` instead.
    }


    // MARK: - Configure Player

    @MainActor
    private func configurePlayer() {

        let cachedPlayer =
            ExerciseVideoCache.shared.player(
                for: url
            )

        // Assign without an animation.
        var transaction =
            Transaction()

        transaction.disablesAnimations = true


        withTransaction(
            transaction
        ) {

            player = cachedPlayer
        }


        // MARK: Playback

        updatePlayback(
            isActive: isActive
        )
    }


    // MARK: - Playback State

    @MainActor
    private func updatePlayback(
        isActive: Bool
    ) {

        guard let player else {
            return
        }


        if isActive {

            // MARK: Current Exercise

            player.play()

        } else {

            // MARK: Upcoming Exercise

            //
            // Keep the player/asset alive and prepared,
            // but do not play the next exercise underneath
            // the current one.
            player.pause()
        }
    }
}
