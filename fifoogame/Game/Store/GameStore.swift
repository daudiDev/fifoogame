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
    
    @Published
    private(set) var futureRouteDraft =
        FutureRouteDraft()
    
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
    
    @Published
    private(set) var pendingRouteAction:
    RouteAction?
    
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
    
    func clearFutureRoutes() {
        
        routeState
            .chosenFutureRoute =
        GameRoute()
        
        
        routeState
            .alternativeRoutes =
        []
        
        
        routeState
            .chosenFutureRouteActivatedAt =
        nil
    }
    
    // =====================================================
    // MARK: - Road Path Planning
    // =====================================================
    
    func planRoadPaths(
        for route:
        GameRoute
    ) -> GameRoutePathPlanningResult {
        
        GameRoutePathPlanner(
            timePolicy:
                    .dayMap
        )
        .plan(
            route:
                route,
            gameNodes:
                gameNodes,
            roadGraph:
                roadGraph
        )
    }
    
    @discardableResult
    func planChosenFutureRouteRoadPaths()
    -> GameRoutePathPlanningResult {
        
        let result =
        planRoadPaths(
            for:
                routeState
                .chosenFutureRoute
        )
        
        
        if result.succeeded {
            
            routeState
                .chosenFutureRoute =
            result.route
        }
        
        
        return result
    }
    
    func planRoadPathsIgnoringTime(
        for route:
        GameRoute
    ) -> GameRoutePathPlanningResult {
        
        GameRoutePathPlanner(
            timePolicy:
                nil
        )
        .plan(
            route:
                route,
            gameNodes:
                gameNodes,
            roadGraph:
                roadGraph
        )
    }
    
    // =====================================================
    // MARK: - Future Route Generation
    // =====================================================
    
    @discardableResult
    func generateFutureRoutes(
        stopNodeIDs:
        [GameNodeID],
        maxAlternatives:
        Int = 3
    ) -> FutureRouteGenerationResult {
        
        let planner =
        FutureRoutePlanner(
            timePolicy:
                    .dayMap,
            alternativePolicy:
                AlternativeRouteGenerationPolicy(
                    maxAlternatives:
                        maxAlternatives
                )
        )
        
        
        let result =
        planner.generate(
            stopNodeIDs:
                stopNodeIDs,
            gameNodes:
                gameNodes,
            roadGraph:
                roadGraph
        )
        
        
        /*
         IMPORTANT:
         
         If generation fails, leave the user's existing
         route state untouched.
         */
        
        guard let chosenRoute =
                result.chosenRoute
        else {
            
            return result
        }
        
        
        routeState.chosenFutureRoute =
        chosenRoute
        
        
        routeState.alternativeRoutes =
        result.alternativeRoutes
        
        
        routeState.chosenFutureRouteActivatedAt =
        currentDayTime
        
        
        return result
    }
    
    // =====================================================
    // MARK: - Choose Future Route
    // =====================================================
    
    // =====================================================
    // MARK: - Choose Future Route
    // =====================================================
    
    @discardableResult
    func chooseFutureRoute(
        routeID:
        RouteID
    ) -> Bool {
        
        // =============================================
        // Already chosen
        // =============================================
        
        if
            routeState
                .chosenFutureRoute
                .id
                ==
                routeID
        {
            
            return true
        }
        
        
        // =============================================
        // Find alternative
        // =============================================
        
        guard let index =
                routeState
            .alternativeRoutes
            .firstIndex(
                where: {
                    
                    $0.id ==
                    routeID
                }
            )
        else {
            
            return false
        }
        
        
        // =============================================
        // FIRST freeze current chosen route through now.
        // =============================================
        
        let progression =
        advanceCompletedRoute(
            to:
                currentDayTime
        )
        
        
        guard
            progression.succeeded
        else {
            
            return false
        }
        
        
        let candidate =
        routeState
            .alternativeRoutes[
                index
            ]
        
        
        // =============================================
        // Candidate must begin its future from the
        // user's actual current road position.
        // =============================================
        
        guard
            RouteSwitchCompatibility
                .canSwitch(
                    completedRoute:
                        routeState
                        .completedRoute,
                    to:
                        candidate,
                    at:
                        currentDayTime,
                    gameNodes:
                        gameNodes,
                    roadGraph:
                        roadGraph
                )
        else {
            
            return false
        }
        
        
        // =============================================
        // Perform swap
        // =============================================
        
        let oldChosen =
        routeState
            .chosenFutureRoute
        
        
        let newChosen =
        routeState
            .alternativeRoutes
            .remove(
                at:
                    index
            )
        
        
        routeState
            .chosenFutureRoute =
        newChosen
        
        
        if
            !oldChosen
                .isEmpty,
            
                oldChosen
                .plannedPathSignature
                !=
                newChosen
                .plannedPathSignature
        {
            
            routeState
                .alternativeRoutes
                .append(
                    oldChosen
                )
        }
        
        
        routeState
            .alternativeRoutes =
        uniqueRoutesByPath(
            routeState
                .alternativeRoutes
        )
        
        
        routeState
            .alternativeRoutes
            .sort {
                
                (
                    $0.plannedTotalCost
                    ??
                        .greatestFiniteMagnitude
                )
                
                <
                
                (
                    $1.plannedTotalCost
                    ??
                        .greatestFiniteMagnitude
                )
            }
        
        
        /*
         Only the newly chosen route's path AFTER now
         may become future/completed history.
         */
        
        routeState
            .chosenFutureRouteActivatedAt =
        currentDayTime
        
        
        return true
    }
    
    // =====================================================
    // MARK: - Completed Route Progression
    // =====================================================
    
    @discardableResult
    func advanceCompletedRoute(
        to time:
        DayTime
    ) -> CompletedRouteProgressionResult {
        
        let result =
        CompletedRouteProgressor()
            .advance(
                completedRoute:
                    routeState
                    .completedRoute,
                
                using:
                    routeState
                    .chosenFutureRoute,
                
                routeActivatedAt:
                    routeState
                    .chosenFutureRouteActivatedAt,
                
                to:
                    time,
                
                gameNodes:
                    gameNodes,
                
                roadGraph:
                    roadGraph
            )
        
        
        if result.succeeded {
            
            routeState
                .completedRoute =
            result
                .completedRoute
        }
        
        
        return result
    }
    
    var chosenFutureRouteSnapshot:
    GameRouteProgressSnapshot? {
        
        let route =
        routeState
            .chosenFutureRoute
        
        
        guard
            !route.isEmpty,
            
                route.isFullyPlanned
        else {
            
            return nil
        }
        
        
        return GameRouteProgressResolver
            .snapshot(
                of:
                    route,
                at:
                    currentDayTime,
                gameNodes:
                    gameNodes,
                graph:
                    roadGraph
            )
    }
    
    func futureSnapshot(
        for route:
        GameRoute
    ) -> GameRouteProgressSnapshot {
        
        GameRouteProgressResolver
            .snapshot(
                of:
                    route,
                at:
                    currentDayTime,
                gameNodes:
                    gameNodes,
                graph:
                    roadGraph
            )
    }
    
    var completedRoadSegments:
    [RoadRouteSegment] {
        
        routeState
            .completedRoute
            .segments
    }
    
    private func removeInvalidFutureRoutes() {
        
        // =============================================
        // Chosen Future Route
        // =============================================
        
        if
            !routeState
                .chosenFutureRoute
                .isEmpty,
            
                !validateRoute(
                    routeState
                        .chosenFutureRoute
                )
                .isValid
        {
            
            routeState
                .chosenFutureRoute =
            GameRoute()
            
            
            routeState
                .chosenFutureRouteActivatedAt =
            nil
        }
        
        
        // =============================================
        // Alternatives
        // =============================================
        
        routeState
            .alternativeRoutes =
        routeState
            .alternativeRoutes
            .filter {
                
                validateRoute(
                    $0
                )
                .isValid
            }
    }
    
    // =====================================================
    // MARK: - Route Rendering State
    // =====================================================
    
    var routeRenderState: RouteRenderState {
        
        // =================================================
        // Completed
        // =================================================
        
        let completedSegments:
        [RoadRouteSegment] =
        routeState
            .completedRoute
            .segments
        
        
        // =================================================
        // Chosen Future
        // =================================================
        
        let chosenFuture:
        RouteRenderPath?
        
        
        if
            !routeState
                .chosenFutureRoute
                .isEmpty,
            let snapshot =
                chosenFutureRouteSnapshot,
            !snapshot
                .futureSegments
                .isEmpty
        {
            
            chosenFuture =
            RouteRenderPath(
                routeID:
                    routeState
                    .chosenFutureRoute
                    .id,
                segments:
                    snapshot
                    .futureSegments
            )
            
        } else {
            
            chosenFuture =
            nil
        }
        
        
        // =================================================
        // Alternatives
        // =================================================
        
        var alternativeRenderPaths:
        [RouteRenderPath] = []
        
        
        for route in
                routeState
            .alternativeRoutes
        {
            
            let snapshot =
            futureSnapshot(
                for:
                    route
            )
            
            
            guard
                !snapshot
                    .futureSegments
                    .isEmpty
            else {
                
                continue
            }
            
            
            let renderPath =
            RouteRenderPath(
                routeID:
                    route.id,
                segments:
                    snapshot
                    .futureSegments
            )
            
            
            alternativeRenderPaths.append(
                renderPath
            )
        }
        
        
        // =================================================
        // Build State
        // =================================================
        
        let result =
        RouteRenderState(
            completedSegments:
                completedSegments,
            chosenFuture:
                chosenFuture,
            alternatives:
                alternativeRenderPaths,
            currentBoundary:
                routeState
                .completedRoute
                .boundary
        )
        
        
        return result
    }
    
    func consumePendingRouteAction() {
        
        pendingRouteAction =
        nil
    }
    
    func futureRoute(
        id:
            RouteID
    ) -> GameRoute? {

        if
            routeState
                .chosenFutureRoute
                .id
            ==
            id,
            !routeState
                .chosenFutureRoute
                .isEmpty
        {

            return routeState
                .chosenFutureRoute
        }


        return routeState
            .alternativeRoutes
            .first {

                $0.id ==
                    id
            }
    }
    
    // =====================================================
    // MARK: - Begin New Route Draft
    // =====================================================

    func beginNewFutureRouteDraft() {

        futureRouteDraft =
            FutureRouteDraft(
                source:
                    .newRoute,
                stopNodeIDs:
                    []
            )
    }
    
    // =====================================================
    // MARK: - Edit Chosen Future Route
    // =====================================================

    func beginEditingChosenFutureRoute() {

        guard
            !routeState
                .chosenFutureRoute
                .isEmpty
        else {

            beginNewFutureRouteDraft()

            return
        }


        let snapshot =
            GameRouteProgressResolver
                .snapshot(
                    of:
                        routeState
                            .chosenFutureRoute,
                    at:
                        currentDayTime,
                    gameNodes:
                        gameNodes,
                    graph:
                        roadGraph
                )


        futureRouteDraft =
            FutureRouteDraft(
                source:
                    .existingChosenRoute,
                stopNodeIDs:
                    snapshot
                        .futureNodeIDs
            )
    }
    
    @discardableResult
    func addStopToFutureRouteDraft(
        nodeID:
            GameNodeID
    ) -> Bool {

        // =================================================
        // Already present
        // =================================================

        guard
            !futureRouteDraft
                .stopNodeIDs
                .contains(
                    nodeID
                )
        else {

            return false
        }


        // =================================================
        // Node exists
        // =================================================

        guard let node =
            gameNode(
                id:
                    nodeID
            )
        else {

            return false
        }


        // =================================================
        // Must be enabled
        // =================================================

        guard node.isEnabled else {

            return false
        }


        // =================================================
        // Must actually be road-route eligible
        // =================================================

        let resolver =
            GameNodeRouteAnchorResolver()


        guard
            resolver.resolve(
                node:
                    node,
                graph:
                    roadGraph
            )
            != nil
        else {

            return false
        }


        // =================================================
        // Must not be in the past
        // =================================================

        guard let coordinate =
            GameNodePlacementResolver
                .mapCoordinate(
                    for:
                        node,
                    graph:
                        roadGraph
                )
        else {

            return false
        }


        guard
            coordinate.time >=
                currentDayTime
        else {

            return false
        }


        // =================================================
        // Add
        // =================================================

        futureRouteDraft
            .stopNodeIDs
            .append(
                nodeID
            )


        return true
    }
    
    @discardableResult
    func removeStopFromFutureRouteDraft(
        nodeID:
            GameNodeID
    ) -> Bool {

        guard let index =
            futureRouteDraft
                .stopNodeIDs
                .firstIndex(
                    of:
                        nodeID
                )
        else {

            return false
        }


        futureRouteDraft
            .stopNodeIDs
            .remove(
                at:
                    index
            )


        return true
    }
    
    @discardableResult
    func moveFutureRouteDraftStop(
        from sourceIndex:
            Int,
        to destinationIndex:
            Int
    ) -> Bool {

        guard
            futureRouteDraft
                .stopNodeIDs
                .indices
                .contains(
                    sourceIndex
                )
        else {

            return false
        }


        let nodeID =
            futureRouteDraft
                .stopNodeIDs
                .remove(
                    at:
                        sourceIndex
                )


        let safeDestination =
            min(
                max(
                    destinationIndex,
                    0
                ),
                futureRouteDraft
                    .stopNodeIDs
                    .count
            )


        futureRouteDraft
            .stopNodeIDs
            .insert(
                nodeID,
                at:
                    safeDestination
            )


        return true
    }
    
    func clearFutureRouteDraft() {

        futureRouteDraft =
            FutureRouteDraft()
    }
    
    var futureRouteDraftValidation:
        FutureRouteDraftValidationResult {

        FutureRouteDraftValidator
            .validate(
                futureRouteDraft,
                gameNodes:
                    gameNodes,
                roadGraph:
                    roadGraph,
                currentTime:
                    currentDayTime
            )
    }
    
    var canPlanFutureRouteDraft:
        Bool {

        futureRouteDraftValidation
            .isValid
    }
    
    var futureRouteDraftNodes:
        [GameMapNode] {

        let lookup =
            Dictionary(
                uniqueKeysWithValues:
                    gameNodes.map {

                        (
                            $0.id,
                            $0
                        )
                    }
            )


        return futureRouteDraft
            .stopNodeIDs
            .compactMap {

                lookup[
                    $0
                ]
            }
    }
    
    var availableFutureRouteStopNodes:
        [GameMapNode] {

        let anchorResolver =
            GameNodeRouteAnchorResolver()


        var result:
            [GameMapNode] = []


        for node in
            gameNodes {

            guard
                node.isEnabled
            else {

                continue
            }


            // =============================================
            // Must actually lie on valid road geometry
            // =============================================

            guard
                anchorResolver.resolve(
                    node:
                        node,
                    graph:
                        roadGraph
                )
                != nil
            else {

                continue
            }


            guard let coordinate =
                GameNodePlacementResolver
                    .mapCoordinate(
                        for:
                            node,
                        graph:
                            roadGraph
                    )
            else {

                continue
            }


            // =============================================
            // Future only
            // =============================================

            guard
                coordinate.time >=
                    currentDayTime
            else {

                continue
            }


            result.append(
                node
            )
        }


        // =================================================
        // Display in chronological order
        // =================================================

        result.sort { lhs, rhs in

            guard
                let lhsCoordinate =
                    GameNodePlacementResolver
                        .mapCoordinate(
                            for:
                                lhs,
                            graph:
                                roadGraph
                        ),

                let rhsCoordinate =
                    GameNodePlacementResolver
                        .mapCoordinate(
                            for:
                                rhs,
                            graph:
                                roadGraph
                        )
            else {

                return false
            }


            if lhsCoordinate.time ==
                rhsCoordinate.time {

                return lhs.content.title
                    .localizedCaseInsensitiveCompare(
                        rhs.content.title
                    )
                    ==
                    .orderedAscending
            }


            return lhsCoordinate.time <
                rhsCoordinate.time
        }


        return result
    }
    
    func mapCoordinate(
        for nodeID:
            GameNodeID
    ) -> MapCoordinate? {

        guard let node =
            gameNode(
                id:
                    nodeID
            )
        else {

            return nil
        }


        return GameNodePlacementResolver
            .mapCoordinate(
                for:
                    node,
                graph:
                    roadGraph
            )
    }
    
    //MARK: todo - temp
    func debugPrintFutureRouteDraft() {

        print("")
        print("======================================")
        print("FUTURE ROUTE DRAFT")
        print("======================================")

        print(
            "Source:",
            String(
                describing:
                    futureRouteDraft.source
            )
        )

        print(
            "Stops:",
            futureRouteDraft.stopNodeIDs.count
        )


        for (
            index,
            nodeID
        ) in futureRouteDraft
            .stopNodeIDs
            .enumerated()
        {

            guard let node =
                gameNode(
                    id:
                        nodeID
                )
            else {

                print(
                    "\(index + 1). Missing Node"
                )

                continue
            }


            let coordinate =
                GameNodePlacementResolver
                    .mapCoordinate(
                        for:
                            node,
                        graph:
                            roadGraph
                    )


            print(
                "\(index + 1).",
                node.content.title,
                "|",
                coordinate?
                    .time
                    .displayClockString
                ??
                "Unknown Time"
            )
        }


        let validation =
            futureRouteDraftValidation


        print(
            "Valid:",
            validation.isValid
        )

        print(
            "Issues:",
            validation.issues
        )

        print("======================================")
        print("")
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
            
            // =================================================
            // Route
            // =================================================
            
        case let .routeTapped(
            target,
            _,
            _
        ):
            
            pendingNodeAction =
            nil
            
            
            if let routeID =
                target.routeID {
                
                var updated =
                selection
                
                
                updated.selectRoute(
                    routeID
                )
                
                
                selection =
                updated
            }
            
            
            pendingRouteAction =
            RouteActionResolver
                .action(
                    for:
                        target
                )
        }
    }
}

private extension GameStore {

    func uniqueRoutesByPath(
        _ routes:
            [GameRoute]
    ) -> [GameRoute] {

        var signatures =
            Set<String>()


        var result:
            [GameRoute] = []


        for route in routes {

            guard let signature =
                route
                    .plannedPathSignature
            else {

                continue
            }


            guard
                signatures
                    .insert(
                        signature
                    )
                    .inserted
            else {

                continue
            }


            result.append(
                route
            )
        }


        return result
    }
}

extension GameRoute {

    func costDifference(
        comparedTo other:
            GameRoute
    ) -> Double? {

        guard
            let myCost =
                plannedTotalCost,

            let otherCost =
                other.plannedTotalCost
        else {

            return nil
        }


        return myCost
        -
        otherCost
    }


    func costRatio(
        comparedTo other:
            GameRoute
    ) -> Double? {

        guard
            let myCost =
                plannedTotalCost,

            let otherCost =
                other.plannedTotalCost,

            otherCost >
                0.000_001
        else {

            return nil
        }


        return myCost
        /
        otherCost
    }
}
