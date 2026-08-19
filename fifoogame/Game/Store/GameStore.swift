//
//  GameStore 2.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/18/26.
//


//
//  GameStore.swift
//  Fifoo
//

import Foundation
import Combine


@MainActor
final class GameStore:
    ObservableObject {

    // MARK: - Game Day

    @Published
    private(set) var gameDay:
        GameDay


    // MARK: - World

    @Published
    private(set) var roadGraph:
        RoadGraph


    // MARK: - Selection

    @Published
    private(set) var selection =
        SelectionState()


    // MARK: - Current Time

    @Published
    private(set) var currentDayTime:
        DayTime


    // MARK: - Diagnostics

    @Published
    private(set) var lastSceneInteraction:
        SceneInteraction?


    // MARK: - Clock

    private var clockTask:
        Task<Void, Never>?


    // MARK: - Init

    init(
        gameDay:
            GameDay = .today(),

        roadGraph:
            RoadGraph =
        DenseCityRoadGraph.make(),

        now:
            Date = .now
    ) {

        self.gameDay =
            gameDay


        self.roadGraph =
            roadGraph


        let timeZone =
            TimeZone(
                identifier:
                    gameDay.timeZoneID
            )
            ?? .autoupdatingCurrent


        self.currentDayTime =
            DayTime.from(
                date:
                    now,
                timeZone:
                    timeZone
            )
    }
}


// MARK: - Clock

extension GameStore {

    func startClock() {

        guard
            clockTask == nil
        else {

            refreshCurrentTime()

            return
        }


        refreshCurrentTime()


        clockTask =
            Task { [weak self] in

                while !Task.isCancelled {

                    do {

                        try await Task.sleep(
                            for:
                                .seconds(30)
                        )

                    } catch {

                        return
                    }


                    guard let self else {
                        return
                    }


                    self.refreshCurrentTime()
                }
            }
    }


    func stopClock() {

        clockTask?
            .cancel()


        clockTask =
            nil
    }


    func refreshCurrentTime(
        now:
            Date = .now
    ) {

        let timeZone =
            TimeZone(
                identifier:
                    gameDay.timeZoneID
            )
            ?? .autoupdatingCurrent


        currentDayTime =
            DayTime.from(
                date:
                    now,
                timeZone:
                    timeZone
            )
    }
}


// MARK: - Scene Interaction

extension GameStore:
    SceneInteractionDelegate {

    func sceneDidEmit(
        _ interaction:
            SceneInteraction
    ) {

        lastSceneInteraction =
            interaction


        switch interaction {

        case .backgroundTapped:

            selection.clear()


        case let .roadEdgeTapped(
            edgeID,
            _,
            _
        ):

            var updated =
                selection


            updated.selectRoadEdge(
                edgeID
            )


            selection =
                updated


        case let .roadVertexTapped(
            vertexID,
            _,
            _
        ):

            var updated =
                selection


            updated.selectRoadVertex(
                vertexID
            )


            selection =
                updated
        }
    }
}
