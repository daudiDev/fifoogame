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
    
    
    @Published
    private(set) var routeState =
        DayRouteState()


    // MARK: - Diagnostics

    @Published
    private(set) var lastSceneInteraction:
        SceneInteraction?
    
    @Published
    private(set) var gameNodes:
        [GameMapNode]
    
    @Published
    private(set) var pendingNodeAction:
        GameNodeAction?


    // MARK: - Clock

    private var clockTask:
        Task<Void, Never>?


    // MARK: - Init
    init(
        gameDay:
            GameDay = .today(),

        roadGraph:
            RoadGraph = DenseCityRoadGraph.make(),

        gameNodes:
            [GameMapNode] = SampleGameNodes.make(),

        now:
            Date = .now
    ) {

        self.gameDay =
            gameDay

        self.roadGraph =
            roadGraph

        self.gameNodes =
            gameNodes


        let timeZone =
            TimeZone(
                identifier:
                    gameDay.timeZoneID
            )
            ??
            .autoupdatingCurrent


        self.currentDayTime =
            DayTime.from(
                date:
                    now,
                timeZone:
                    timeZone
            )
    }
    
    func gameNode(
        id: GameNodeID
    ) -> GameMapNode? {

        gameNodes.first {

            $0.id == id
        }
    }
    
    func consumePendingNodeAction() {

        pendingNodeAction =
            nil
    }
    
    // =====================================================
    // MARK: - Game Node Editing
    // =====================================================

    func updateGameNode(
        _ updatedNode: GameMapNode
    ) {

        guard let index =
            gameNodes.firstIndex(
                where: {
                    $0.id ==
                        updatedNode.id
                }
            )
        else {

            return
        }


        gameNodes[index] =
            updatedNode
    }
    
    // =====================================================
    // MARK: - Delete Game Node
    // =====================================================

    func deleteGameNode(
        id: GameNodeID
    ) {

        guard
            gameNodes.contains(
                where: {
                    $0.id ==
                        id
                }
            )
        else {

            return
        }


        gameNodes.removeAll {

            $0.id ==
                id
        }


        // =============================================
        // Clear stale selection
        // =============================================

        if
            selection
                .selectedNodeID
            ==
            id
        {

            selection.clear()
        }


        // =============================================
        // Clear transient action
        // =============================================

        pendingNodeAction =
            nil
    }
    
    // =====================================================
    // MARK: - Add Game Node
    // =====================================================

    func addGameNode(
        _ node: GameMapNode
    ) {

        guard
            !gameNodes.contains(
                where: {
                    $0.id ==
                        node.id
                }
            )
        else {

            return
        }


        gameNodes.append(
            node
        )


        // Select the newly-created node.

        var updatedSelection =
            selection


        updatedSelection
            .selectGameNode(
                node.id
            )


        selection =
            updatedSelection
    }
    
    // =====================================================
    // MARK: - Node / Road Relationship
    // =====================================================

    func roadRelationship(
        for nodeID:
            GameNodeID
    ) -> GameNodeRoadRelationship {

        guard let node =
            gameNode(
                id:
                    nodeID
            )
        else {

            return .offRoad
        }


        return GameNodeRoadRelationshipResolver()
            .resolve(
                node:
                    node,
                graph:
                    roadGraph
            )
    }
    
    func roadRelationship(
        for node:
            GameMapNode
    ) -> GameNodeRoadRelationship {

        GameNodeRoadRelationshipResolver()
            .resolve(
                node:
                    node,
                graph:
                    roadGraph
            )
    }
    
    // =====================================================
    // MARK: - Node / Route Integration
    // =====================================================

    func routeAnchor(
        for nodeID:
            GameNodeID
    ) -> GameNodeRouteAnchor? {

        guard let node =
            gameNode(
                id:
                    nodeID
            )
        else {

            return nil
        }


        return GameNodeRouteAnchorResolver()
            .resolve(
                node:
                    node,
                graph:
                    roadGraph
            )
    }
    
    var routeEligibleGameNodes:
        [GameMapNode] {

        gameNodes.filter { node in

            GameNodeRouteAnchorResolver()
                .resolve(
                    node:
                        node,
                    graph:
                        roadGraph
                )
            != nil
        }
    }
    
    // =====================================================
    // MARK: - Route Construction
    // =====================================================

    func makeUnplannedRoute(
        stopNodeIDs:
            [GameNodeID]
    ) -> GameRoute {

        GameRoute.unplanned(
            stopNodeIDs:
                stopNodeIDs
        )
    }
    
    func validateRoute(
        _ route:
            GameRoute
    ) -> GameRouteValidationResult {

        GameRouteValidator
            .validate(
                route,
                gameNodes:
                    gameNodes,
                roadGraph:
                    roadGraph
            )
    }
    
    @discardableResult
    func setChosenFutureRoute(
        _ route:
            GameRoute
    ) -> Bool {

        let result =
            validateRoute(
                route
            )


        guard
            result.isValid
        else {

            return false
        }


        routeState
            .chosenFutureRoute =
                route


        /*
         A route should not simultaneously remain
         in the alternatives collection.
         */

        routeState
            .alternativeRoutes
            .removeAll {

                $0.id ==
                    route.id
            }


        return true
    }
    
    func setAlternativeRoutes(
        _ routes:
            [GameRoute]
    ) {

        let validRoutes =
            routes.filter {

                validateRoute(
                    $0
                )
                .isValid
            }


        routeState
            .alternativeRoutes =
                validRoutes
                    .filter {

                        $0.id !=
                            routeState
                                .chosenFutureRoute
                                .id
                    }
    }
    
    func setCompletedRoute(
        _ route:
            GameRoute
    ) {

        routeState
            .completedRoute =
                route
    }
    
    func clearFutureRoutes() {

        routeState
            .chosenFutureRoute =
                GameRoute()


        routeState
            .alternativeRoutes =
                []
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
        _ interaction: SceneInteraction
    ) {

        lastSceneInteraction =
            interaction


        switch interaction {

        // =============================================
        // Background
        // =============================================

        case .backgroundTapped:

            pendingNodeAction =
                nil

            selection.clear()


        // =============================================
        // Road Edge
        // =============================================

        case let .roadEdgeTapped(
            edgeID,
            _,
            _
        ):

            pendingNodeAction =
                nil


            var updated =
                selection


            updated.selectRoadEdge(
                edgeID
            )


            selection =
                updated


        // =============================================
        // Road Vertex
        // =============================================

        case let .roadVertexTapped(
            vertexID,
            _,
            _
        ):

            pendingNodeAction =
                nil


            var updated =
                selection


            updated.selectRoadVertex(
                vertexID
            )


            selection =
                updated


        // =============================================
        // Game Node
        // =============================================

        case let .gameNodeTapped(
            nodeID,
            _,
            _
        ):

            var updated =
                selection


            updated.selectGameNode(
                nodeID
            )


            selection =
                updated


            guard let node =
                gameNode(
                    id:
                        nodeID
                )
            else {

                pendingNodeAction =
                    nil

                return
            }


            pendingNodeAction =
                GameNodeActionResolver
                    .action(
                        for:
                            node
                    )
        }
    }
}
