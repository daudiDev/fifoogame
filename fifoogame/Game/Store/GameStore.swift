//
//  GameStore.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/24/26.
//



import Foundation
import Combine


struct RoadNodeAddRequest:
    Identifiable,
    Equatable,
    Sendable {

    let id:
        UUID

    let coordinate:
        MapCoordinate


    init(
        coordinate: MapCoordinate
    ) {

        self.id =
            UUID()

        self.coordinate =
            coordinate
    }
}


/// Stop content supplied by the application for a specific empty path card.
///
/// This is deliberately real `GameNodeContent`, not a display-only teaser.
/// Accepting the suggestion therefore creates the same `GameMapNode` model
/// used everywhere else in the day map. The backend/app can populate these
/// suggestions later without changing the map interaction contract.
struct SuggestedPathStop:
    Identifiable,
    Equatable,
    Sendable {

    let id:
        UUID

    var content:
        GameNodeContent


    init(
        id: UUID = UUID(),
        content: GameNodeContent
    ) {

        self.id = id
        self.content = content
    }


    func makeGameNode(
        at coordinate: MapCoordinate
    ) -> GameMapNode {

        GameMapNode(
            placement:
                .coordinate(
                    coordinate
                ),
            time:
                coordinate.time,
            content:
                content
        )
    }
}


/// Presentation request emitted only when an empty path card has actual
/// app-provided suggested content. Empty path cards with no suggestion bypass
/// this request and use the normal Add Stop flow immediately.
struct SuggestedPathStopRequest:
    Identifiable,
    Equatable,
    Sendable {

    let id:
        UUID

    let cellID:
        GridCellID

    let coordinate:
        MapCoordinate

    let routeTarget:
        RouteInteractionTarget

    let suggestion:
        SuggestedPathStop


    init(
        cellID: GridCellID,
        coordinate: MapCoordinate,
        routeTarget: RouteInteractionTarget,
        suggestion: SuggestedPathStop
    ) {

        self.id = UUID()
        self.cellID = cellID
        self.coordinate = coordinate
        self.routeTarget = routeTarget
        self.suggestion = suggestion
    }
}


@MainActor
final class GameStore: ObservableObject {
    
#if DEBUG

@Published
private(set) var debugRouteScenario:
    DebugRouteScenario?

/// Render-only alternative paths used by the DEBUG route-render demo.
///
/// This is intentionally separate from `routeState.alternativeRoutes` so the
/// renderer can be tested deterministically even when the real alternative
/// route generator legitimately produces zero or near-overlapping options.
@Published
var debugAlternativeRenderPaths:
    [RouteRenderPath]?

/// Complete render-state override used by deterministic DEBUG fixtures.
///
/// Unlike `debugAlternativeRenderPaths`, this can replace Completed, Chosen,
/// Alternatives, and the current route boundary together. It exists only to
/// test renderer behavior without depending on production planning data.
@Published
var debugRouteRenderStateOverride:
    RouteRenderState?

#endif
    
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

    /// Explicitly revealed cards. This is presentation/gameplay state rather
    /// than road state and can be persisted by the backend in a later step.
    @Published
    private(set) var revealedTileIDs:
        Set<GridCellID> = []

    /// When non-nil, the day map temporarily isolates exactly one alternate
    /// route alongside completed history. The first tap on an alternate node
    /// sets this focus; a later tap on a node belonging to the focused route
    /// opens that node normally. Background/other-route interactions clear it.
    @Published
    private(set) var focusedAlternativeRouteID:
        RouteID? = nil

    /// Pass 3 defaults to the discovery-first behavior from the product
    /// concept. Keeping the policy explicit makes it easy to run legacy/debug
    /// fixtures without changing renderer code.
    let tileRevealPolicy:
        DayMapTileRevealPolicy
    
    @Published
    private(set) var pendingNodeAction:
    GameNodeAction?

    /// Set when a revealed day-map tile contains multiple stops at the exact
    /// same semantic point. SwiftUI consumes this to present the fan-out
    /// chooser before any one stop's normal detail sheet is opened.
    @Published
    private(set) var pendingStackedNodeSelection:
        StackedDayTileSelectionRequest?
    
    @Published
    private(set) var pendingRouteAction:
    RouteAction?

    /// A road/intersection tap is now an Add Node request rather than a
    /// persistent road selection. A unique ID ensures repeated taps at the
    /// same semantic coordinate can still present the sheet again.
    @Published
    private(set) var pendingRoadNodeAddRequest:
        RoadNodeAddRequest?

    /// Application-provided suggestions keyed to exact day-map cards. Empty
    /// cards without an entry here behave exactly like ordinary Add Stop cards.
    @Published
    private(set) var suggestedPathStopsByCell:
        [GridCellID: SuggestedPathStop] = [:]

    /// Cells whose suggestion has already been accepted or rejected for the
    /// currently loaded Day Map. Both decisions consume the suggestion so a
    /// provider must not offer the same card again after reconnect/relaunch.
    @Published
    private(set) var consumedSuggestedPathStopCellIDs:
        Set<GridCellID> = []

    /// Emitted only when the tapped empty path card has supplied suggestion
    /// content. DayMapView presents that content directly for review.
    @Published
    private(set) var pendingSuggestedPathStopRequest:
        SuggestedPathStopRequest?
    
    @Published
    private(set) var futureRouteDraftPlan:
        FutureRouteDraftPlanningResult?
    
    @Published
    private(set) var futureRoutePreview:
        FutureRoutePreview?
    
    // =====================================================
    // MARK: - Game Clock
    // =====================================================

    @Published
    private(set) var currentDayTime:
        DayTime =
            DayTime.from(
                date: Date(),
                timeZone: .current
            )


    @Published
    private(set) var currentGameDayID =
        GameDayID()


    @Published
    private(set) var currentCalendarDay =
        CalendarDayKey(
            date: Date(),
            timeZone: .current
        )


    @Published
    private(set) var currentClockDate =
        Date()


    @Published
    private(set) var gameClockMode:
        GameClockMode =
            .realTime


    @Published
    private(set) var isGameClockRunning =
        false


    @Published
    private(set) var isSimulationPaused =
        false


    @Published
    private(set) var simulationSpeed:
        Double = 60


    @Published
    private(set) var clockTimeZoneIdentifier =
        TimeZone.current.identifier


    @Published
    private(set) var lastCompletedDaySnapshot:
        CompletedGameDaySnapshot?
    
    // =====================================================
    // MARK: - Progress / Scoring
    // =====================================================

    @Published
    private(set) var progressState =
        DayProgressState(
            startingProgress:
                MapProgress(0)
        )


    @Published
    private(set) var nodeProgressScoringRules:
        [GameNodeID: ProgressScoringRule] = [:]


    @Published
    private(set) var dailyStartingProgress =
        MapProgress(0)


    private var clockTask:
        Task<Void, Never>?


    private var lastWallTickDate:
        Date?


    private var simulatedDate =
        Date()


    var gameClockTimeZone:
        TimeZone {

        TimeZone(
            identifier:
                clockTimeZoneIdentifier
        )
        ??
        .current
    }
    
    var currentProgress:
        MapProgress {

        progressState
            .currentProgress
    }


    var currentProgressPercent:
        Double {

        currentProgress.percent
    }


    var currentProgressCoordinate:
        MapCoordinate {

        MapCoordinate(
            time:
                currentDayTime,
            progress:
                currentProgress
        )
    }
    
    
    // MARK: - Init
    init(
        gameDay:
        GameDay = .today(),
        
        roadGraph:
        RoadGraph = GridRoadGraph.make(),
        
        gameNodes:
        [GameMapNode] = [],

        tileRevealPolicy:
        DayMapTileRevealPolicy = .discoveryFirst,
        
        now:
        Date = .now
    ) {
        
        self.gameDay =
        gameDay
        
        self.roadGraph =
        roadGraph

        self.tileRevealPolicy =
        tileRevealPolicy
        
        self.gameNodes =
        gameNodes.map { node in

            var synchronized =
                node

            if case let .roadVertex(
                vertexID
            ) = node.placement,
               let vertex =
                roadGraph.vertex(
                    id:
                        vertexID
                )
            {

                synchronized.setPlacement(
                    .roadVertex(
                        vertexID
                    ),
                    resolvedRoadTime:
                        vertex.coordinate.time
                )
            }

            return synchronized
        }


        switch tileRevealPolicy {

        case .discoveryFirst:

            // Ordinary nodes begin hidden. Route/preview cards are exposed by
            // DayMapTileResolver without mutating this explicit discovery set.
            self.revealedTileIDs = []

        case .revealAllNodes:

            self.revealedTileIDs =
                Set(
                    self.gameNodes.compactMap { node in

                        guard let coordinate =
                            GameNodePlacementResolver
                                .mapCoordinate(
                                    for: node,
                                    graph: roadGraph
                                )
                        else {
                            return nil
                        }

                        return GridMapGeometry
                            .cellID(
                                containing: coordinate
                            )
                    }
                )
        }
        
        
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

    func consumePendingStackedNodeSelection() {

        pendingStackedNodeSelection =
            nil
    }

    func consumePendingRoadNodeAddRequest() {

        pendingRoadNodeAddRequest =
            nil
    }


    func consumePendingSuggestedPathStopRequest() {

        pendingSuggestedPathStopRequest =
            nil
    }


    // =====================================================
    // MARK: - Suggested Path Stops
    // =====================================================

    /// Supplies real stop content for one otherwise-empty path card. The app
    /// or future socket payload can call this when it has a suggestion.
    func setSuggestedPathStop(
        _ suggestion: SuggestedPathStop,
        for cellID: GridCellID
    ) {

        guard !consumedSuggestedPathStopCellIDs.contains(cellID) else {
            return
        }

        suggestedPathStopsByCell[cellID] =
            suggestion
    }


    func suggestedPathStop(
        for cellID: GridCellID
    ) -> SuggestedPathStop? {

        suggestedPathStopsByCell[cellID]
    }


    func clearSuggestedPathStop(
        for cellID: GridCellID
    ) {

        suggestedPathStopsByCell.removeValue(
            forKey: cellID
        )
    }


    /// Marks a suggestion as consumed immediately for optimistic UI behavior.
    /// The next authoritative snapshot replaces this set with server state.
    func markSuggestedPathStopConsumed(
        _ cellID: GridCellID
    ) {

        consumedSuggestedPathStopCellIDs.insert(cellID)
        clearSuggestedPathStop(for: cellID)
    }


    /// Applies the authoritative accepted/rejected suggestion cells for the
    /// currently selected Day Map. Any provider-supplied suggestion already
    /// cached for one of these cells is removed immediately.
    func replaceConsumedSuggestedPathStopCellsFromServer(
        _ cellIDs: Set<GridCellID>
    ) {

        consumedSuggestedPathStopCellIDs = cellIDs

        for cellID in cellIDs {
            suggestedPathStopsByCell.removeValue(forKey: cellID)
        }
    }


    /// Clears date-scoped suggestion state before loading another Day Map.
    /// Suggestion providers can repopulate the new date after its snapshot.
    func prepareSuggestedPathStopsForDayReload() {

        suggestedPathStopsByCell.removeAll()
        consumedSuggestedPathStopCellIDs.removeAll()
        pendingSuggestedPathStopRequest = nil
    }


    /// Programmatic equivalent of tapping a map node. Search and other
    /// non-SpriteKit entry points use this so node selection/action resolution
    /// remains in the domain store rather than being reimplemented in SwiftUI.
    func requestGameNodeAction(
        id nodeID: GameNodeID
    ) {

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
    
    // =====================================================
    // MARK: - Tile Reveal State
    // =====================================================

    func revealTile(
        _ id: GridCellID
    ) {

        revealedTileIDs.insert(id)
    }


    func hideTile(
        _ id: GridCellID
    ) {

        revealedTileIDs.remove(id)
    }


    // =====================================================
    // MARK: - Alternate Route Focus
    // =====================================================

    /// True when this alternate route is already the route isolated by the
    /// user's first tap. SocketManager uses the same query so application
    /// action logging mirrors the store's two-stage interaction semantics.
    func isAlternativeRouteFocused(
        _ routeID: RouteID
    ) -> Bool {

        focusedAlternativeRouteID == routeID
    }


    func focusAlternativeRoute(
        _ routeID: RouteID
    ) {

        focusedAlternativeRouteID = routeID
    }


    func clearAlternativeRouteFocus() {

        focusedAlternativeRouteID = nil
    }


    /// Ends the temporary alternate-route preview and returns the board to
    /// its normal chosen-route presentation. Selection is cleared so the
    /// alternate card does not retain a secondary selection highlight after
    /// the preview overlay disappears.
    func closeAlternativeRoutePreview() {

        focusedAlternativeRouteID =
            nil


        selection.clear()


        pendingNodeAction =
            nil


        pendingStackedNodeSelection =
            nil


        pendingRouteAction =
            nil
    }


    /// The preview percentage is the progress coordinate of the last
    /// resolvable GameNode on the focused alternate route. The Fifoo day map
    /// already defines X as progress, so this gives the overlay a meaningful
    /// route-end progress preview without introducing a second scoring model.
    var focusedAlternativePreviewProgressPercent:
        Double? {

        guard
            let routeID = focusedAlternativeRouteID,
            let route = futureRoute(
                id: routeID
            )
        else {
            return nil
        }


        for nodeID in
            route.stopNodeIDs.reversed() {

            guard
                let node = gameNode(
                    id: nodeID
                ),
                let coordinate =
                    GameNodePlacementResolver
                        .mapCoordinate(
                            for: node,
                            graph: roadGraph
                        )
            else {
                continue
            }


            return coordinate
                .progress
                .percent
        }


        return currentProgressPercent
    }


    private func revealTileContaining(
        _ node: GameMapNode
    ) {

        guard
            let coordinate =
                GameNodePlacementResolver
                    .mapCoordinate(
                        for: node,
                        graph: roadGraph
                    ),
            let id =
                GridMapGeometry
                    .cellID(
                        containing: coordinate
                    )
        else {
            return
        }

        revealedTileIDs.insert(id)
    }


    // =====================================================
    // MARK: - Game Node Editing
    // =====================================================
    
    private func synchronizedNodeTime(
        _ node: GameMapNode
    ) -> GameMapNode {

        var synchronized =
            node

        guard case let .roadVertex(
            vertexID
        ) = node.placement,
              let vertex =
                roadGraph.vertex(
                    id:
                        vertexID
                )
        else {

            return synchronized
        }

        synchronized.setPlacement(
            .roadVertex(
                vertexID
            ),
            resolvedRoadTime:
                vertex.coordinate.time
        )

        return synchronized
    }


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
        
        
        let synchronized =
        synchronizedNodeTime(
            updatedNode
        )

        gameNodes[index] =
        synchronized

        revealTileContaining(
            synchronized
        )
        
        invalidateDraftPlanIfNeeded(
            changedNodeID:
                updatedNode.id
        )
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
        
        invalidateDraftPlanIfNeeded(
            changedNodeID:
                id
        )
        
        removeDeletedNodeFromFutureRouteDraft(id)
        
        
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
        
        
        let synchronized =
        synchronizedNodeTime(
            node
        )

        gameNodes.append(
            synchronized
        )

        revealTileContaining(
            synchronized
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
    
    private func invalidateRouteDraftIfSourceRouteNoLongerExists() {

        guard let originalRouteID =
            futureRouteDraft
                .originalRouteID
        else {

            return
        }


        guard
            routeState
                .chosenFutureRoute
                .id
            !=
            originalRouteID
            ||
            routeState
                .chosenFutureRoute
                .isEmpty
        else {

            return
        }


        futureRouteDraft =
            FutureRouteDraft()


        futureRouteDraftPlan =
            nil


        futureRoutePreview =
            nil
    }
    
    // =====================================================
    // MARK: - Route Rendering State
    // =====================================================
    
    var routeRenderState: RouteRenderState {

        #if DEBUG

        if let debugRouteRenderStateOverride {
            return applyingAlternativeRouteFocus(
                to: debugRouteRenderStateOverride
            )
        }

        #endif
        
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
        
        #if DEBUG

        let renderedAlternatives =
            debugAlternativeRenderPaths
            ??
            alternativeRenderPaths

        #else

        let renderedAlternatives =
            alternativeRenderPaths

        #endif


        let result =
        RouteRenderState(
            completedSegments:
                completedSegments,
            chosenFuture:
                chosenFuture,
            alternatives:
                renderedAlternatives,
            currentBoundary:
                routeState
                .completedRoute
                .boundary
        )
        
        
        return applyingAlternativeRouteFocus(
            to: result
        )
    }


    /// Focus mode intentionally preserves completed history but removes the
    /// chosen route and every unrelated alternate from the presentation. If
    /// the focused route no longer exists, fall back to the normal render
    /// state instead of leaving the map stranded in an empty focus mode.
    private func applyingAlternativeRouteFocus(
        to state: RouteRenderState
    ) -> RouteRenderState {

        guard
            let focusedRouteID = focusedAlternativeRouteID,
            let focusedAlternative = state.alternatives.first(
                where: { $0.routeID == focusedRouteID }
            )
        else {
            return state
        }

        return RouteRenderState(
            completedSegments: state.completedSegments,
            chosenFuture: nil,
            alternatives: [focusedAlternative],
            currentBoundary: state.currentBoundary
        )
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


        futureRouteDraftPlan =
            nil


        futureRoutePreview =
            nil
    }
    
    // =====================================================
    // MARK: - Edit Chosen Future Route
    // =====================================================
    @discardableResult
    func beginEditingChosenFutureRoute() -> Bool {

        let route =
            routeState
                .chosenFutureRoute


        guard
            !route.isEmpty,
            route.isFullyPlanned
        else {

            return false
        }


        // =================================================
        // Only copy stops that remain in the future.
        // Completed/past stops are NOT editable.
        // =================================================

        let snapshot =
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


        futureRouteDraft =
            FutureRouteDraft(
                source:
                    .existingChosenRoute(
                        routeID:
                            route.id
                    ),
                stopNodeIDs:
                    snapshot
                        .futureNodeIDs
            )


        futureRouteDraftPlan =
            nil


        futureRoutePreview =
            nil


        return true
    }
    
    // =====================================================
    // MARK: - Add Stop To Future Route Draft
    // =====================================================


    @discardableResult
    func addStopToFutureRouteDraft(
        _ nodeID: GameNodeID
    ) -> Bool {

        // =================================================
        // 1. Node must exist.
        //
        // We intentionally do NOT check:
        //
        // - road eligibility
        // - time validity
        // - whether the node is in the past
        //
        // FutureRouteDraftValidator handles those.
        // =================================================

        guard
            gameNode(
                id:
                    nodeID
            )
            != nil
        else {

            print(
                "❌ addStopToFutureRouteDraft: Stop does not exist."
            )

            return false
        }


        // =================================================
        // 2. Prevent duplicate stops.
        // =================================================

        guard
            !futureRouteDraft
                .stopNodeIDs
                .contains(
                    nodeID
                )
        else {

            print(
                "⚠️ addStopToFutureRouteDraft: Stop is already in the draft."
            )

            return false
        }


        // =================================================
        // 3. Copy the value-type draft.
        // =================================================

        var updatedDraft =
            futureRouteDraft


        // =================================================
        // 4. Add stop.
        // =================================================

        updatedDraft
            .stopNodeIDs
            .append(
                nodeID
            )


        // =================================================
        // 5. Publish updated draft.
        // =================================================

        futureRouteDraft =
            updatedDraft


        // =================================================
        // 6. Existing planning results are now stale.
        // =================================================

        futureRouteDraftPlan =
            nil


        futureRoutePreview =
            nil


        #if DEBUG

        print(
            "✅ Added path stop:",
            nodeID
        )

        print(
            "Draft stop count:",
            futureRouteDraft
                .stopNodeIDs
                .count
        )

        #endif


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
        
        
        var updatedDraft =
        futureRouteDraft
        
        
        updatedDraft
            .stopNodeIDs
            .remove(
                at:
                    index
            )
        
        
        futureRouteDraft =
        updatedDraft
        
        
        invalidateFutureRouteDraftPlan()
        
        
        return true
        
    }
    
    @discardableResult
    func moveFutureRouteDraftStop(
        from sourceIndex: Int,
        to destinationIndex: Int
    ) -> Bool {

        let original =
            futureRouteDraft.stopNodeIDs


        guard
            original.indices.contains(
                sourceIndex
            )
        else {

            return false
        }


        guard
            destinationIndex >= 0,
            destinationIndex < original.count
        else {

            return false
        }


        guard
            sourceIndex != destinationIndex
        else {

            return true
        }


        var reordered =
            original


        let nodeID =
            reordered.remove(
                at:
                    sourceIndex
            )


        let safeDestination =
            min(
                max(
                    destinationIndex,
                    0
                ),
                reordered.count
            )


        reordered.insert(
            nodeID,
            at:
                safeDestination
        )


        var updatedDraft =
            futureRouteDraft


        updatedDraft.stopNodeIDs =
            reordered


        futureRouteDraft =
            updatedDraft


        invalidateFutureRouteDraftPlan()


        return true
    }
    
    func clearFutureRouteDraft() {

        futureRouteDraft =
            FutureRouteDraft()


        futureRouteDraftPlan =
            nil


        futureRoutePreview =
            nil
        
        clearFutureRouteEditingState()
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
        print("FUTURE PATH DRAFT")
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
                    "\(index + 1). Missing Stop"
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
    
    // =====================================================
    // MARK: - Reorder Future Route Draft Stops
    // =====================================================

    @discardableResult
    func moveFutureRouteDraftStops(
        fromIndices sourceIndices: [Int],
        toOffset destinationOffset: Int
    ) -> Bool {

        let original =
            futureRouteDraft.stopNodeIDs


        guard !original.isEmpty else {
            return false
        }


        let sortedIndices =
            Array(
                Set(sourceIndices)
            )
            .sorted()


        guard !sortedIndices.isEmpty else {
            return false
        }


        // =================================================
        // Make sure every source index exists.
        // =================================================

        guard sortedIndices.allSatisfy({
            original.indices.contains($0)
        }) else {

            return false
        }


        guard
            destinationOffset >= 0,
            destinationOffset <= original.count
        else {

            return false
        }


        // =================================================
        // Items being moved
        // =================================================

        let movingNodeIDs =
            sortedIndices.map {
                original[$0]
            }


        let sourceSet =
            Set(sortedIndices)


        // =================================================
        // Everything that stays behind
        // =================================================

        var remainingNodeIDs: [GameNodeID] =
            original
                .enumerated()
                .compactMap { index, nodeID in

                    sourceSet.contains(index)
                    ? nil
                    : nodeID
                }


        /*
         SwiftUI's destination offset refers to the
         collection BEFORE the moving elements are removed.

         So if we move:

             A B C D

         A -> offset 3

         SwiftUI expects:

             B C A D

         not:

             B C D A
        */

        let removedBeforeDestination =
            sortedIndices.filter {
                $0 < destinationOffset
            }
            .count


        let adjustedDestination =
            destinationOffset
            -
            removedBeforeDestination


        let safeDestination =
            min(
                max(
                    adjustedDestination,
                    0
                ),
                remainingNodeIDs.count
            )


        remainingNodeIDs.insert(
            contentsOf:
                movingNodeIDs,
            at:
                safeDestination
        )


        // =================================================
        // Reassign the struct so @Published definitely emits.
        // =================================================

        var updatedDraft =
            futureRouteDraft


        updatedDraft.stopNodeIDs =
            remainingNodeIDs


        futureRouteDraft =
            updatedDraft


        return true
    }
    
    // =====================================================
    // MARK: - Plan Future Route Draft
    // =====================================================

    @discardableResult
    func planFutureRouteDraft()
        -> FutureRouteDraftPlanningResult {

        // =================================================
        // Any previous preview is now obsolete.
        // =================================================

        futureRoutePreview =
            nil


        // =================================================
        // 1. Validate the user's draft.
        // =================================================

        let validation =
            futureRouteDraftValidation


        guard validation.isValid else {

            let result =
                FutureRouteDraftPlanningResult(
                    validation:
                        validation,
                    plannedRoute:
                        nil,
                    planningIssues:
                        [],
                    start:
                        nil,
                    failure:
                        .invalidDraft
                )


            futureRouteDraftPlan =
                result


            return result
        }


        // =================================================
        // 2. We should have at least two stops because the
        //    validator currently requires two.
        // =================================================

        guard
            futureRouteDraft
                .stopNodeIDs
                .count
            >=
            2
        else {

            let result =
                FutureRouteDraftPlanningResult(
                    validation:
                        validation,
                    plannedRoute:
                        nil,
                    planningIssues:
                        [],
                    start:
                        nil,
                    failure:
                        .invalidDraft
                )


            futureRouteDraftPlan =
                result


            return result
        }


        // =================================================
        // 3. Resolve the user's ACTUAL current road position.
        //
        //    This comes from completed-route history.
        //
        //    We DO NOT:
        //
        //    - use nearest road
        //    - snap current progress to a road
        //    - create a fake GameMapNode
        // =================================================

        let currentRouteAnchor =
            CurrentRoutePositionResolver
                .resolve(
                    completedRoute:
                        routeState
                            .completedRoute,
                    currentTime:
                        currentDayTime,
                    graph:
                        roadGraph
                )


        // =================================================
        // 4. If we HAVE a stored completed boundary but
        //    cannot resolve that boundary into a routing
        //    anchor, something is wrong.
        //
        //    Do not silently fall back to the first stop.
        // =================================================

        if
            routeState
                .completedRoute
                .boundary
            != nil,
            currentRouteAnchor == nil
        {

            let result =
                FutureRouteDraftPlanningResult(
                    validation:
                        validation,
                    plannedRoute:
                        nil,
                    planningIssues:
                        [],
                    start:
                        nil,
                    failure:
                        .currentRoutePositionUnavailable
                )


            futureRouteDraftPlan =
                result


            return result
        }


        // =================================================
        // 5. Construct the unplanned route.
        // =================================================

        let unplannedRoute:
            GameRoute


        let planStart:
            FutureRouteDraftPlanStart


        if let currentRouteAnchor {

            // =============================================
            // The day has already progressed along a route.
            //
            // Route starts at the exact current road
            // position, which may be partway through an
            // edge.
            //
            // CURRENT POSITION
            //       ↓
            //   entryLeg
            //       ↓
            // first future stop
            //       ↓
            // second future stop
            // =============================================

            unplannedRoute =
                GameRoute.unplanned(
                    startingAt:
                        currentRouteAnchor,
                    stopNodeIDs:
                        futureRouteDraft
                            .stopNodeIDs
                )


            planStart =
                .currentRoutePosition(
                    currentRouteAnchor
                )

        } else {

            // =============================================
            // No completed route boundary exists yet.
            //
            // The first selected node becomes the route's
            // normal starting stop.
            // =============================================

            unplannedRoute =
                GameRoute.unplanned(
                    stopNodeIDs:
                        futureRouteDraft
                            .stopNodeIDs
                )


            planStart =
                .firstSelectedStop
        }


        // =================================================
        // 6. Create the actual time-aware road planner.
        // =================================================

        let planner =
            GameRoutePathPlanner(
                timePolicy:
                    .dayMap,
                routingOptions:
                    .standard
            )


        // =================================================
        // 7. Plan:
        //
        //    current position -> first stop   [if entry leg]
        //
        //    first stop -> second stop
        //
        //    second stop -> third stop
        //
        //    etc.
        //
        //    Step 5 directional rules are enforced by RoadPathfinder:
        //    LEFT / RIGHT / DOWN are allowed; UP is never allowed.
        //    The search also penalizes unnecessary turns and horizontal
        //    direction changes while rejecting loops/reversals.
        // =================================================

        let planningResult =
            planner.plan(
                route:
                    unplannedRoute,
                gameNodes:
                    gameNodes,
                roadGraph:
                    roadGraph
            )


        // =================================================
        // 8. Pathfinding failed.
        // =================================================

        guard
            planningResult.succeeded,
            planningResult
                .route
                .isFullyPlanned
        else {

            let result =
                FutureRouteDraftPlanningResult(
                    validation:
                        validation,
                    plannedRoute:
                        nil,
                    planningIssues:
                        planningResult
                            .issues,
                    start:
                        planStart,
                    failure:
                        .noValidRoadPath
                )


            futureRouteDraftPlan =
                result


            return result
        }


        // =================================================
        // 9. Successful draft plan.
        //
        //    IMPORTANT:
        //
        //    We still do NOT modify:
        //
        //    routeState.chosenFutureRoute
        //
        //    This is only an editor plan.
        // =================================================

        let result =
            FutureRouteDraftPlanningResult(
                validation:
                    validation,
                plannedRoute:
                    planningResult
                        .route,
                planningIssues:
                    [],
                start:
                    planStart,
                failure:
                    nil
            )


        futureRouteDraftPlan =
            result


        return result
    }
    
    private func invalidateFutureRouteDraftPlan() {

        futureRouteDraftPlan =
            nil


        futureRoutePreview =
            nil
    }
    
    func clearFutureRoutePreview() {

        futureRoutePreview =
            nil
    }
    
    // =====================================================
    // MARK: - Generate Future Route Preview
    // =====================================================

    @discardableResult
    func generateFutureRoutePreview(
        maxAlternatives:
            Int = 3
    ) -> Bool {

        // =================================================
        // Must already have a successful 6D plan.
        // =================================================

        guard
            let draftPlan =
                futureRouteDraftPlan,

            draftPlan.succeeded,

            let primaryRoute =
                draftPlan.plannedRoute,

            primaryRoute.isFullyPlanned
        else {

            futureRoutePreview =
                nil

            return false
        }


        // =================================================
        // Generate alternatives from EXACT same start.
        // =================================================

        let policy =
            AlternativeRouteGenerationPolicy(
                maxAlternatives:
                    maxAlternatives
            )


        let generator =
            AlternativeRouteGenerator(
                policy:
                    policy
            )


        let alternatives =
            generator.generate(
                from:
                    primaryRoute,
                gameNodes:
                    gameNodes,
                roadGraph:
                    roadGraph,
                timePolicy:
                    .dayMap
            )


        // =================================================
        // Create temporary preview.
        // =================================================

        futureRoutePreview =
            FutureRoutePreview(
                primaryRoute:
                    primaryRoute,
                alternativeRoutes:
                    alternatives,
                selectedRouteID:
                    primaryRoute.id
            )


        return true
    }
    
    // =====================================================
    // MARK: - Generate Future Route Preview Alternatives
    // =====================================================
    @discardableResult
    func generateFutureRoutePreviewAlternatives(
        maximumAlternatives:
            Int = 3
    ) -> FutureRoutePreview? {

        // =================================================
        // 1. A successfully planned draft must exist.
        // =================================================

        guard let planningResult =
            futureRouteDraftPlan
        else {

            print(
                "❌ generateFutureRoutePreviewAlternatives: No future path draft plan."
            )

            futureRoutePreview =
                nil

            return nil
        }


        guard
            planningResult.succeeded
        else {

            print(
                "❌ generateFutureRoutePreviewAlternatives: Draft planning did not succeed."
            )

            futureRoutePreview =
                nil

            return nil
        }


        // =================================================
        // 2. Extract primary planned route.
        // =================================================

        guard let primaryRoute =
            planningResult
                .plannedRoute
        else {

            print(
                "❌ generateFutureRoutePreviewAlternatives: Planning result contains no path."
            )

            futureRoutePreview =
                nil

            return nil
        }


        guard
            primaryRoute
                .isFullyPlanned
        else {

            print(
                "❌ generateFutureRoutePreviewAlternatives: Primary path is not fully planned."
            )

            futureRoutePreview =
                nil

            return nil
        }


        // =================================================
        // 3. Generate alternate routes using the actual
        //    AlternativeRouteGenerator API.
        //
        // Your generator internally:
        //
        // - penalizes selected road edges
        // - calls unplannedPreservingStart()
        // - replans through GameRoutePathPlanner
        // - rejects duplicate paths
        // - checks cost ratios
        // - assigns new RouteIDs
        // =================================================

        let generator =
            AlternativeRouteGenerator(
                policy:
                    .interactivePreview(
                        maxAlternatives:
                            maximumAlternatives
                    )
            )


        let generatedAlternatives =
            generator.generate(
                from:
                    primaryRoute,

                gameNodes:
                    gameNodes,

                roadGraph:
                    roadGraph,

                timePolicy:
                    .dayMap
            )


        // =================================================
        // 4. Keep only fully planned alternatives.
        //
        // The generator already guarantees this in normal
        // operation, but this protects FutureRoutePreview
        // from invalid state.
        // =================================================

        let plannedAlternatives =
            generatedAlternatives
                .filter {

                    $0.isFullyPlanned
                }


        // =================================================
        // 5. Remove anything that somehow duplicates the
        //    primary route.
        //
        // AlternativeRouteGenerator already performs this
        // check, but keeping the boundary defensive here is
        // useful because preview state should never contain
        // duplicate paths.
        // =================================================

        let primarySignature =
            primaryRoute
                .plannedPathSignature


        let nonPrimaryAlternatives =
            plannedAlternatives
                .filter { alternative in

                    guard
                        let alternativeSignature =
                            alternative
                                .plannedPathSignature
                    else {

                        return false
                    }


                    guard
                        let primarySignature
                    else {

                        return true
                    }


                    return
                        alternativeSignature
                        !=
                        primarySignature
                }


        // =================================================
        // 6. Remove duplicate alternatives.
        //
        // uniqueRoutesByPath(...) comes from the existing
        // Section 6 route architecture.
        // =================================================

        let uniqueAlternatives =
            uniqueRoutesByPath(
                nonPrimaryAlternatives
            )


        // =================================================
        // 7. Sort cheapest first.
        //
        // Your generator already sorts them, but doing it
        // here guarantees preview ordering remains stable
        // even if the generator changes later.
        // =================================================

        let sortedAlternatives =
            uniqueAlternatives
                .sorted {

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


        // =================================================
        // 8. Respect requested preview limit.
        //
        // The generator's own policy may produce more or
        // fewer routes. This controls only how many routes
        // we expose in the preview.
        // =================================================

        let requestedCount =
            max(
                0,
                maximumAlternatives
            )


        let alternatives =
            Array(
                sortedAlternatives
                    .prefix(
                        requestedCount
                    )
            )


        // =================================================
        // 9. Create preview.
        //
        // Primary route is selected initially.
        // =================================================

        let preview =
            FutureRoutePreview(
                primaryRoute:
                    primaryRoute,

                alternativeRoutes:
                    alternatives,

                selectedRouteID:
                    primaryRoute.id
            )


        futureRoutePreview =
            preview


        // =================================================
        // 10. Debug
        // =================================================

        #if DEBUG

        print("")
        print("========== FUTURE PATH PREVIEW ==========")

        print(
            "Primary path:",
            primaryRoute.id
        )


        print(
            "Primary cost:",
            primaryRoute.plannedTotalCost
            as Any
        )


        print(
            "Generated alternatives:",
            generatedAlternatives.count
        )


        print(
            "Preview alternatives:",
            alternatives.count
        )


        for (
            index,
            route
        ) in alternatives.enumerated() {

            print(
                """
                Alternative \(index + 1):
                  ID: \(route.id)
                  Cost: \(String(describing: route.plannedTotalCost))
                  Edges: \(route.orderedUniqueRoadEdgeIDs.count)
                """
            )
        }


        print("==========================================")
        print("")

        #endif


        return preview
    }

    @discardableResult
    func selectFutureRoutePreview(
        routeID:
            RouteID
    ) -> Bool {

        guard var preview =
            futureRoutePreview
        else {

            return false
        }


        guard
            preview
                .allRoutes
                .contains(
                    where: {

                        $0.id ==
                            routeID
                    }
                )
        else {

            return false
        }


        preview.selectedRouteID =
            routeID


        futureRoutePreview =
            preview


        return true
    }
    
    // =====================================================
    // MARK: - Commit Future Route Preview
    // =====================================================

    @discardableResult
    func commitFutureRoutePreview()
        -> FutureRouteCommitResult {

        // =================================================
        // 1. Preview must still exist.
        // =================================================

        guard let preview =
            futureRoutePreview
        else {

            return .failure(
                .noPreview
            )
        }


        // =================================================
        // 2. Preview must have a selected route.
        // =================================================

        guard let selectedRoute =
            preview.selectedRoute
        else {

            return .failure(
                .selectedRouteUnavailable
            )
        }


        // =================================================
        // 3. Selected route must still be fully planned.
        // =================================================

        guard
            selectedRoute
                .isFullyPlanned
        else {

            return .failure(
                .selectedRouteNotPlanned
            )
        }


        // =================================================
        // 4. If this editor started from an existing chosen
        //    route, verify that same route is STILL live.
        //
        //    Example:
        //
        //    Edit Route A
        //         ↓
        //    something else changes live route to B
        //         ↓
        //    old Route A editor tries to commit
        //
        //    REJECT.
        // =================================================

        switch
            futureRouteDraft
                .source
        {

        case .newRoute:

            break


        case let .existingChosenRoute(
            originalRouteID
        ):

            guard
                !routeState
                    .chosenFutureRoute
                    .isEmpty,
                routeState
                    .chosenFutureRoute
                    .id
                ==
                originalRouteID
            else {

                return .failure(
                    .sourceRouteChanged
                )
            }
        }


        // =================================================
        // 5. Freeze CURRENT live route history through NOW.
        //
        //    THIS MUST HAPPEN BEFORE:
        //
        //    routeState.chosenFutureRoute = selectedRoute
        //
        //    Otherwise we could accidentally record the new
        //    route as historical travel.
        // =================================================

        let progression =
            advanceCompletedRoute(
                to:
                    currentDayTime
            )


        guard
            progression
                .succeeded
        else {

            return .failure(
                .timeMovedBackward
            )
        }


        // =================================================
        // 6. Verify that the proposed route STILL passes
        //    through the user's actual current road position.
        //
        //    This matters because time may have advanced
        //    while Route Preview was open.
        // =================================================

        if let completedBoundary =
            routeState
                .completedRoute
                .boundary
        {

            // =============================================
            // Determine where the proposed route says the
            // user should be at CURRENT time.
            // =============================================

            let candidateSnapshot =
                GameRouteProgressResolver
                    .snapshot(
                        of:
                            selectedRoute,
                        at:
                            currentDayTime,
                        gameNodes:
                            gameNodes,
                        graph:
                            roadGraph
                    )


            guard let candidateBoundary =
                candidateSnapshot
                    .boundary
            else {

                return .failure(
                    .currentPositionChanged
                )
            }


            // =============================================
            // Must be the same actual road location.
            //
            // This properly handles:
            //
            // .vertex(...)
            //
            // and:
            //
            // .edge(edgeID:fraction:)
            // =============================================

            guard
                RoadLocationCanonicalizer
                    .equivalent(
                        completedBoundary,
                        candidateBoundary,
                        graph:
                            roadGraph
                    )
            else {

                return .failure(
                    .currentPositionChanged
                )
            }
        }


        // =================================================
        // 7. Build the new live alternative route set.
        //
        //    Every preview route OTHER than the selected
        //    route becomes an alternative.
        // =================================================

        var newAlternativeRoutes:
            [GameRoute] = []


        for route in
            preview
                .allRoutes
        {

            // =============================================
            // Selected route is becoming chosen.
            // =============================================

            guard
                route.id
                !=
                selectedRoute.id
            else {

                continue
            }


            // =============================================
            // Don't preserve an identical road traversal
            // under a different RouteID.
            // =============================================

            guard
                route
                    .plannedPathSignature
                !=
                selectedRoute
                    .plannedPathSignature
            else {

                continue
            }


            // =============================================
            // Only install valid planned alternatives.
            // =============================================

            guard
                route.isFullyPlanned
            else {

                continue
            }


            newAlternativeRoutes
                .append(
                    route
                )
        }


        // =================================================
        // 8. Defensive duplicate removal.
        // =================================================

        newAlternativeRoutes =
            uniqueRoutesByPath(
                newAlternativeRoutes
            )


        // =================================================
        // 9. Sort alternatives from cheapest to most
        //    expensive.
        // =================================================

        newAlternativeRoutes
            .sort { lhs, rhs in

                let lhsCost =
                    lhs.plannedTotalCost
                    ??
                    .greatestFiniteMagnitude


                let rhsCost =
                    rhs.plannedTotalCost
                    ??
                    .greatestFiniteMagnitude


                return lhsCost <
                    rhsCost
            }


        // =================================================
        // 10. Install the selected preview as the LIVE
        //     future route.
        //
        //     Notice that completedRoute is NOT assigned
        //     here.
        //
        //     It was only advanced normally in step 5.
        // =================================================

        routeState
            .chosenFutureRoute =
                selectedRoute


        routeState
            .alternativeRoutes =
                newAlternativeRoutes


        // =================================================
        // 11. The newly installed route owns history only
        //     from this moment forward.
        // =================================================

        routeState
            .chosenFutureRouteActivatedAt =
                currentDayTime


        // =================================================
        // 12. Clear an old route selection if that route
        //     disappeared during replacement.
        // =================================================

        if let selectedRouteID =
            selection
                .selectedRouteID
        {

            let selectedRouteStillExists =
                futureRoute(
                    id:
                        selectedRouteID
                )
                != nil


            if !selectedRouteStillExists {

                selection
                    .clear()
            }
        }


        // =================================================
        // 13. Clear all temporary editing state.
        //
        //     Do this only AFTER the live route was
        //     successfully installed.
        // =================================================

        futureRouteDraft =
            FutureRouteDraft()


        futureRouteDraftPlan =
            nil


        futureRoutePreview =
            nil


        // =================================================
        // 14. Success
        // =================================================

        return .success
    }
    
    var routePreviewRenderState:
        RoutePreviewRenderState {

        guard let preview =
            futureRoutePreview
        else {

            return .empty
        }


        var renderPaths:
            [RoutePreviewRenderPath] = []


        for route in
            preview.allRoutes {

            guard
                route.isFullyPlanned
            else {

                continue
            }


            let snapshot =
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


            guard
                !snapshot
                    .futureSegments
                    .isEmpty
            else {

                continue
            }


            renderPaths.append(
                RoutePreviewRenderPath(
                    routeID:
                        route.id,
                    segments:
                        snapshot.futureSegments,
                    isSelected:
                        route.id ==
                        preview.selectedRouteID
                )
            )
        }


        return RoutePreviewRenderState(
            routes:
                renderPaths
        )
    }
    
    // =====================================================
    // MARK: - Route Draft Validation Messages
    // =====================================================

    func message(
        for issue:
            FutureRouteDraftValidationIssue
    ) -> String {

        switch issue {

        case .tooFewStops:

            return "Select at least two future path stops."


        case let .duplicateStop(
            nodeID
        ):

            return
                "\(routeNodeTitle(nodeID)) is included more than once."


        case let .nodeNotFound(
            nodeID
        ):

            return
                "A selected path stop no longer exists: \(routeNodeTitle(nodeID))."


        case let .nodeDisabled(
            nodeID
        ):

            return
                "\(routeNodeTitle(nodeID)) is currently disabled."


        case let .nodeNotRouteEligible(
            nodeID
        ):

            return
                "\(routeNodeTitle(nodeID)) is not connected to a valid road path."


        case let .stopIsInPast(
            nodeID
        ):

            return
                "\(routeNodeTitle(nodeID)) is already in the past."


        case let .stopsOutOfTimeOrder(
            earlierNodeID,
            laterNodeID
        ):

            return
                "\(routeNodeTitle(laterNodeID)) occurs before \(routeNodeTitle(earlierNodeID)). Path stops must move forward through the day."
        }
    }
    
    private func routeNodeTitle(
        _ nodeID:
            GameNodeID
    ) -> String {

        gameNode(
            id:
                nodeID
        )?
        .content
        .title
        ??
        "Unknown Stop"
    }
    
    var futureRouteDraftValidationMessages:
        [String] {

        futureRouteDraftValidation
            .issues
            .map {

                message(
                    for:
                        $0
                )
            }
    }
    
    var isFutureRoutePreviewStale:
        Bool {

        guard
            let preview =
                futureRoutePreview,

            let selectedRoute =
                preview.selectedRoute
        else {

            return false
        }


        // =================================================
        // Existing source route changed
        // =================================================

        if case let .existingChosenRoute(
            originalRouteID
        ) =
            futureRouteDraft.source
        {

            if
                routeState
                    .chosenFutureRoute
                    .id
                !=
                originalRouteID
            {

                return true
            }
        }


        // =================================================
        // No completed boundary means there is currently
        // nothing geometric to compare.
        // =================================================

        guard let completedBoundary =
            routeState
                .completedRoute
                .boundary
        else {

            return false
        }


        let snapshot =
            GameRouteProgressResolver
                .snapshot(
                    of:
                        selectedRoute,
                    at:
                        currentDayTime,
                    gameNodes:
                        gameNodes,
                    graph:
                        roadGraph
                )


        guard let candidateBoundary =
            snapshot.boundary
        else {

            return true
        }


        return
            !RoadLocationCanonicalizer
                .equivalent(
                    completedBoundary,
                    candidateBoundary,
                    graph:
                        roadGraph
                )
    }
    
    private func invalidateDraftPlanIfNeeded(
        changedNodeID:
            GameNodeID
    ) {

        guard
            futureRouteDraft
                .stopNodeIDs
                .contains(
                    changedNodeID
                )
        else {

            return
        }


        futureRouteDraftPlan =
            nil


        futureRoutePreview =
            nil
    }
    
    private func removeDeletedNodeFromFutureRouteDraft(
        _ nodeID:
            GameNodeID
    ) {

        guard
            futureRouteDraft
                .stopNodeIDs
                .contains(
                    nodeID
                )
        else {

            return
        }


        var updated =
            futureRouteDraft


        updated.stopNodeIDs.removeAll {
            $0 == nodeID
        }


        futureRouteDraft =
            updated


        futureRouteDraftPlan =
            nil


        futureRoutePreview =
            nil
    }
    
    private func clearFutureRouteEditingState() {

        futureRouteDraft =
            FutureRouteDraft()


        futureRouteDraftPlan =
            nil


        futureRoutePreview =
            nil
    }
    
    // =====================================================
    // MARK: - Start / Stop Clock
    // =====================================================

    func startGameClock() {

        guard
            !isGameClockRunning
        else {

            return
        }


        isGameClockRunning =
            true


        lastWallTickDate =
            Date()


        // Synchronize immediately rather than waiting
        // for the first one-second tick.
        performClockTick()


        clockTask =
            Task { [weak self] in

                while !Task.isCancelled {

                    try? await Task.sleep(
                        for:
                            .seconds(1)
                    )


                    guard
                        !Task.isCancelled,
                        let self
                    else {

                        return
                    }


                    self.performClockTick()
                }
            }
    }


    func stopGameClock() {

        clockTask?
            .cancel()


        clockTask =
            nil


        isGameClockRunning =
            false


        lastWallTickDate =
            nil
    }
    
    private func performClockTick() {

        let wallNow =
            Date()


        defer {

            lastWallTickDate =
                wallNow
        }


        switch gameClockMode {

        // =================================================
        // REAL TIME
        // =================================================

        case .realTime:

            applyClockDate(
                wallNow
            )


        // =================================================
        // SIMULATED TIME
        // =================================================

        case .simulated:

            guard
                !isSimulationPaused
            else {

                return
            }


            let previousWallDate =
                lastWallTickDate
                ??
                wallNow


            let elapsed =
                max(
                    0,
                    wallNow.timeIntervalSince(
                        previousWallDate
                    )
                )


            let simulatedElapsed =
                elapsed
                *
                simulationSpeed


            simulatedDate =
                simulatedDate
                    .addingTimeInterval(
                        simulatedElapsed
                    )


            applyClockDate(
                simulatedDate
            )
        }
    }
    
    private func applyClockDate(
        _ date:
            Date
    ) {

        let timeZone =
            gameClockTimeZone


        let newDay =
            CalendarDayKey(
                date:
                    date,
                timeZone:
                    timeZone
            )


        let newDayTime =
            GameClockCalendar
                .dayTime(
                    for:
                        date,
                    timeZone:
                        timeZone
                )


        // =================================================
        // New calendar day
        // =================================================

        if newDay !=
            currentCalendarDay
        {

            transitionToNewGameDay(
                date:
                    date,
                day:
                    newDay,
                time:
                    newDayTime
            )


            return
        }


        // =================================================
        // Same day
        //
        // Completed route history never rewinds.
        // This also protects against DST clock fallback.
        // =================================================

        let safeTime =
            max(
                currentDayTime,
                newDayTime
            )


        currentClockDate =
            date


        let progression =
            advanceCompletedRoute(
                to:
                    safeTime
            )


        guard
            progression.succeeded
        else {

            return
        }


        currentDayTime =
            safeTime
    }
    
    private func transitionToNewGameDay(
        date:
            Date,
        day:
            CalendarDayKey,
        time:
            DayTime
    ) {

        // =================================================
        // Finish yesterday's route.
        // =================================================

        let finalProgression =
            advanceCompletedRoute(
                to:
                    .endOfDay
            )


        if finalProgression.succeeded {

            lastCompletedDaySnapshot =
                CompletedGameDaySnapshot(
                    gameDayID:
                        currentGameDayID,
                    calendarDay:
                        currentCalendarDay,
                    completedRoute:
                        finalProgression
                            .completedRoute,
                    progressState:
                        progressState
                )
        }


        // =================================================
        // New game day
        // =================================================

        currentGameDayID =
            GameDayID()


        currentCalendarDay =
            day


        currentClockDate =
            date


        currentDayTime =
            time


        // =================================================
        // Reset route state.
        // =================================================

        routeState =
            DayRouteState()


        clearFutureRouteEditingState()


        selection.clear()


        // =================================================
        // Reset daily scoring.
        // =================================================

        progressState =
            DayProgressState(
                startingProgress:
                    dailyStartingProgress
            )


        // =================================================
        // Begin new day's time progression.
        // =================================================

        _ =
            advanceCompletedRoute(
                to:
                    time
            )
    }
    
    @discardableResult
    func updateCurrentDayTime(
        _ newTime:
            DayTime
    ) -> CompletedRouteProgressionResult {

        let result =
            advanceCompletedRoute(
                to:
                    newTime
            )


        guard
            result.succeeded
        else {

            return result
        }


        currentDayTime =
            newTime


        if let date =
            GameClockCalendar.date(
                for:
                    currentCalendarDay,
                at:
                    newTime,
                timeZone:
                    gameClockTimeZone
            )
        {

            currentClockDate =
                date


            if gameClockMode ==
                .simulated
            {

                simulatedDate =
                    date
            }
        }


        return result
    }
    
    func useRealTimeClock() {

        gameClockMode =
            .realTime


        isSimulationPaused =
            false


        lastWallTickDate =
            Date()


        applyClockDate(
            Date()
        )
    }
    
    func useSimulatedClock(
        speed:
            Double = 60
    ) {

        gameClockMode =
            .simulated


        simulationSpeed =
            max(
                0.1,
                min(
                    speed,
                    3_600
                )
            )


        simulatedDate =
            currentClockDate


        isSimulationPaused =
            false


        lastWallTickDate =
            Date()
    }
    
    func setSimulationSpeed(
        _ speed:
            Double
    ) {

        simulationSpeed =
            max(
                0.1,
                min(
                    speed,
                    3_600
                )
            )
    }


    func pauseSimulation() {

        guard
            gameClockMode ==
                .simulated
        else {

            return
        }


        isSimulationPaused =
            true
    }


    func resumeSimulation() {

        guard
            gameClockMode ==
                .simulated
        else {

            return
        }


        lastWallTickDate =
            Date()


        isSimulationPaused =
            false
    }
    
    @discardableResult
    func advanceSimulatedTime(
        by seconds:
            TimeInterval
    ) -> Bool {

        guard
            gameClockMode ==
                .simulated,
            seconds >= 0
        else {

            return false
        }


        simulatedDate =
            simulatedDate
                .addingTimeInterval(
                    seconds
                )


        lastWallTickDate =
            Date()


        applyClockDate(
            simulatedDate
        )


        return true
    }
    
    @discardableResult
    func setSimulatedTime(
        _ time:
            DayTime
    ) -> Bool {

        guard
            gameClockMode ==
                .simulated
        else {

            return false
        }


        // Historical route state is append-only.
        guard
            time >=
                currentDayTime
        else {

            return false
        }


        guard let date =
            GameClockCalendar.date(
                for:
                    currentCalendarDay,
                at:
                    time,
                timeZone:
                    gameClockTimeZone
            )
        else {

            return false
        }


        simulatedDate =
            date


        lastWallTickDate =
            Date()


        applyClockDate(
            date
        )


        return true
    }
    
    func resetSimulationDay(
        to time:
            DayTime
    ) {

        guard let date =
            GameClockCalendar.date(
                for:
                    currentCalendarDay,
                at:
                    time,
                timeZone:
                    gameClockTimeZone
            )
        else {

            return
        }


        gameClockMode =
            .simulated


        isSimulationPaused =
            false


        currentGameDayID =
            GameDayID()


        // =================================================
        // Reset route state.
        // =================================================

        routeState =
            DayRouteState()


        clearFutureRouteEditingState()


        selection.clear()


        // =================================================
        // Reset progress state.
        // =================================================

        progressState =
            DayProgressState(
                startingProgress:
                    dailyStartingProgress
            )


        // =================================================
        // Reset time.
        // =================================================

        currentClockDate =
            date


        currentDayTime =
            time


        simulatedDate =
            date


        lastWallTickDate =
            Date()


        _ =
            advanceCompletedRoute(
                to:
                    time
            )
    }
    
    func setGameClockTimeZone(
        _ timeZone:
            TimeZone
    ) {

        clockTimeZoneIdentifier =
            timeZone.identifier


        switch gameClockMode {

        case .realTime:

            applyClockDate(
                Date()
            )


        case .simulated:

            applyClockDate(
                simulatedDate
            )
        }
    }
    
    // =====================================================
    // MARK: - Node Scoring Rules
    // =====================================================

    @discardableResult
    func setProgressScoringRule(
        _ rule:
            ProgressScoringRule,
        for nodeID:
            GameNodeID
    ) -> Bool {

        guard
            gameNode(
                id:
                    nodeID
            )
            != nil
        else {

            return false
        }


        nodeProgressScoringRules[
            nodeID
        ] =
            rule


        return true
    }


    func removeProgressScoringRule(
        for nodeID:
            GameNodeID
    ) {

        nodeProgressScoringRules[
            nodeID
        ] =
            nil
    }


    func progressScoringRule(
        for nodeID:
            GameNodeID
    ) -> ProgressScoringRule? {

        nodeProgressScoringRules[
            nodeID
        ]
    }
    
    // =====================================================
    // MARK: - Apply Progress Change
    // =====================================================

    @discardableResult
    func applyProgressChange(
        delta:
            Double,
        reason:
            ProgressChangeReason,
        nodeID:
            GameNodeID? = nil,
        note:
            String? = nil,
        at time:
            DayTime? = nil
    ) -> ProgressLedgerEntry? {

        let occurredAt =
            time
            ??
            currentDayTime


        // =================================================
        // Progress history must remain chronological.
        // =================================================

        if let lastEntry =
            progressState
                .entries
                .last
        {

            guard
                occurredAt >=
                    lastEntry.occurredAt
            else {

                return nil
            }
        }


        let before =
            progressState
                .currentProgress


        let after =
            MapProgress(
                before.percent
                +
                delta
            )


        let entry =
            ProgressLedgerEntry(
                occurredAt:
                    occurredAt,
                delta:
                    delta,
                progressBefore:
                    before,
                progressAfter:
                    after,
                reason:
                    reason,
                nodeID:
                    nodeID,
                note:
                    note
            )


        var updated =
            progressState


        updated.currentProgress =
            after


        updated.entries.append(
            entry
        )


        progressState =
            updated


        return entry
    }
    
    
    // =====================================================
    // MARK: - Apply Node Outcome
    // =====================================================

    @discardableResult
    func setProgressOutcome(
        _ outcome:
            NodeProgressOutcome,
        for nodeID:
            GameNodeID
    ) -> ProgressOutcomeApplyResult {

        // =================================================
        // Node must exist.
        // =================================================

        guard let node =
            gameNode(
                id:
                    nodeID
            )
        else {

            return .failed(
                .nodeNotFound
            )
        }


        guard node.isEnabled else {

            return .failed(
                .nodeDisabled
            )
        }


        // =================================================
        // Node must explicitly have a scoring rule.
        //
        // Not every GameNode affects progress.
        // =================================================

        guard let rule =
            nodeProgressScoringRules[
                nodeID
            ]
        else {

            return .failed(
                .scoringRuleUnavailable
            )
        }


        let newDelta =
            rule.delta(
                for:
                    outcome
            )


        // =================================================
        // Node has already received an outcome.
        // =================================================

        if let existing =
            progressState
                .nodeOutcomes[
                    nodeID
                ]
        {

            // Same outcome twice does nothing.

            if existing.outcome ==
                outcome
            {

                return .unchanged
            }


            // =============================================
            // Correct previous outcome without deleting
            // history.
            //
            // Example:
            //
            // skipped = -5
            // then corrected to completed = +10
            //
            // correction = +15
            //
            // Ledger remains append-only.
            // =============================================

            let correctionDelta =
                newDelta
                -
                existing.appliedDelta


            guard let entry =
                applyProgressChange(
                    delta:
                        correctionDelta,
                    reason:
                        .nodeOutcomeCorrection,
                    nodeID:
                        nodeID,
                    note:
                        "\(existing.outcome.rawValue) → \(outcome.rawValue)"
                )
            else {

                return .failed(
                    .invalidTimestamp
                )
            }


            var updated =
                progressState


            updated.nodeOutcomes[
                nodeID
            ] =
                AppliedNodeProgressOutcome(
                    outcome:
                        outcome,
                    appliedDelta:
                        newDelta,
                    occurredAt:
                        currentDayTime
                )


            progressState =
                updated


            return .corrected(
                entry
            )
        }


        // =================================================
        // First outcome for this node.
        // =================================================

        let reason:
            ProgressChangeReason


        switch outcome {

        case .completed:

            reason =
                .nodeCompleted


        case .skipped:

            reason =
                .nodeSkipped


        case .missed:

            reason =
                .nodeMissed
        }


        guard let entry =
            applyProgressChange(
                delta:
                    newDelta,
                reason:
                    reason,
                nodeID:
                    nodeID
            )
        else {

            return .failed(
                .invalidTimestamp
            )
        }


        var updated =
            progressState


        updated.nodeOutcomes[
            nodeID
        ] =
            AppliedNodeProgressOutcome(
                outcome:
                    outcome,
                appliedDelta:
                    newDelta,
                occurredAt:
                    currentDayTime
            )


        progressState =
            updated


        return .applied(
            entry
        )
    }
    
    // =====================================================
    // MARK: - Bonus
    // =====================================================

    @discardableResult
    func awardProgressBonus(
        _ amount:
            Double,
        note:
            String? = nil
    ) -> ProgressLedgerEntry? {

        applyProgressChange(
            delta:
                abs(amount),
            reason:
                .bonus,
            note:
                note
        )
    }


    // =====================================================
    // MARK: - Penalty
    // =====================================================

    @discardableResult
    func applyProgressPenalty(
        _ amount:
            Double,
        note:
            String? = nil
    ) -> ProgressLedgerEntry? {

        applyProgressChange(
            delta:
                -abs(amount),
            reason:
                .penalty,
            note:
                note
        )
    }


    // =====================================================
    // MARK: - Manual Adjustment
    // =====================================================

    @discardableResult
    func adjustProgress(
        by amount:
            Double,
        note:
            String? = nil
    ) -> ProgressLedgerEntry? {

        applyProgressChange(
            delta:
                amount,
            reason:
                .manualAdjustment,
            note:
                note
        )
    }
    
    func setDailyStartingProgress(
        _ progress:
            MapProgress
    ) {

        dailyStartingProgress =
            progress


        // Only modify today's live value if nothing
        // has happened yet.

        guard
            !progressState
                .hasChanges
        else {

            return
        }


        progressState =
            DayProgressState(
                startingProgress:
                    progress
            )
    }
    
    
    
    
    
    
    
    
    
    
    //MARK: xxxxx end of main func
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

            pendingRouteAction =
            nil

            clearAlternativeRouteFocus()
            
            selection.clear()


            // =============================================
            // Day Tile
            // =============================================

        case let .dayTileTapped(
            cellID,
            nodeID,
            routeTarget,
            isRevealed,
            _,
            mapCoordinate
        ):

            pendingNodeAction = nil
            pendingRouteAction = nil

            if !isRevealed {

                clearAlternativeRouteFocus()

                // Every concealed card, including a truly empty stop card,
                // uses the same first-tap discovery mechanic. The first tap
                // only flips/reveals the card; it never opens a sheet.
                revealTile(
                    cellID
                )

            } else if
                let nodeID,
                let routeTarget,
                case let .alternative(routeID) = routeTarget
            {

                // Alternate nodes use a deliberate two-stage interaction:
                // first tap isolates one route through the node; once that
                // route is already focused, the next tap opens node details.
                if isAlternativeRouteFocused(routeID) {

                    requestGameNodeAction(
                        id: nodeID
                    )

                } else {

                    focusAlternativeRoute(routeID)

                    var updated = selection
                    updated.selectRoute(routeID)
                    selection = updated
                }

            } else if let nodeID {

                clearAlternativeRouteFocus()

                requestGameNodeAction(
                    id: nodeID
                )

            } else if let routeTarget {

                // A revealed empty path card exposes an explicit Add Stop
                // label. Tapping that label always opens the existing Add
                // Stop sheet at this exact semantic card coordinate.
                clearAlternativeRouteFocus()

                if let routeID = routeTarget.routeID {

                    var updated = selection
                    updated.selectRoute(routeID)
                    selection = updated

                } else {

                    selection.clear()
                }

                pendingRoadNodeAddRequest =
                    RoadNodeAddRequest(
                        coordinate: mapCoordinate
                    )

            } else {

                clearAlternativeRouteFocus()

                selection.clear()

                // Compatibility bridge: DayMapView already observes this
                // request to present AddGameNodeView. The type can be renamed
                // once the backend/UI migration is complete.
                pendingRoadNodeAddRequest =
                    RoadNodeAddRequest(
                        coordinate: mapCoordinate
                    )
            }
            

            // =============================================
            // Stacked Day Tile
            // =============================================

        case let .stackedDayTileTapped(
            cellID,
            nodePreviews,
            routeTarget,
            _,
            _
        ):

            pendingNodeAction = nil
            pendingRouteAction = nil

            guard nodePreviews.count > 1 else {

                if let nodeID = nodePreviews.first?.nodeID {
                    requestGameNodeAction(id: nodeID)
                }

                break
            }

            if let routeTarget,
               case let .alternative(routeID) = routeTarget,
               !isAlternativeRouteFocused(routeID)
            {
                // Preserve the existing alternate-route first-tap behavior.
                // Once the route is focused, the next tap fans out the stops.
                focusAlternativeRoute(routeID)

                var updated = selection
                updated.selectRoute(routeID)
                selection = updated

            } else {

                if routeTarget == nil {
                    clearAlternativeRouteFocus()
                    selection.clear()
                }

                pendingStackedNodeSelection =
                    StackedDayTileSelectionRequest(
                        cellID: cellID,
                        nodePreviews: nodePreviews
                    )
            }

            
            // =============================================
            // Road Edge
            // =============================================
            
        case let .roadEdgeTapped(
            _,
            _,
            mapCoordinate
        ):
            
            pendingNodeAction =
            nil

            pendingRouteAction =
            nil

            // Road taps are no longer selections, so there is no visual road
            // color/halo state to render. Clear any previous selection and
            // turn the resolved road coordinate into an Add Node request.
            selection.clear()

            pendingRoadNodeAddRequest =
                RoadNodeAddRequest(
                    coordinate:
                        mapCoordinate
                )
            
            
            // =============================================
            // Road Vertex
            // =============================================
            
        case let .roadVertexTapped(
            _,
            _,
            mapCoordinate
        ):
            
            pendingNodeAction =
            nil

            pendingRouteAction =
            nil

            selection.clear()

            pendingRoadNodeAddRequest =
                RoadNodeAddRequest(
                    coordinate:
                        mapCoordinate
                )
            
            
            // =============================================
            // Game Node
            // =============================================
            
        case let .gameNodeTapped(
            nodeID,
            _,
            _
        ):

            requestGameNodeAction(
                id:
                    nodeID
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


#if DEBUG

extension GameStore {

    func debugRouteTestVertices()
        -> [RoadVertex] {

        // =====================================================
        // Use one known continuous vertical road.
        //
        // Each edge continues directly into the next:
        //
        // r05 → r06
        // r06 → r07
        // r07 → r08
        // r08 → r09
        // r09 → r10
        //
        // We use each edge's destination vertex.
        // =====================================================

        let edgeIDs: [String] = [

            "street.v.c04.r05-06",
            "street.v.c04.r06-07",
            "street.v.c04.r07-08",
            "street.v.c04.r08-09",
            "street.v.c04.r09-10"
        ]


        var result: [RoadVertex] = []


        print("")
        print("========== DEBUG PATH CORRIDOR ==========")

        print(
            "Current time:",
            currentDayTime.displayClockString
        )


        for edgeIDString in edgeIDs {

            // =================================================
            // Find the actual RoadEdge.
            // =================================================

            guard let edge =
                roadGraph
                    .edges
                    .first(
                        where: {

                            $0.id.rawValue
                            ==
                            edgeIDString
                        }
                    )
            else {

                print(
                    "❌ Missing debug edge:",
                    edgeIDString
                )

                continue
            }


            // =================================================
            // Use the lower / destination vertex.
            //
            // GridRoadGraph's vertical roads are authored
            // top → bottom, which corresponds to forward time.
            // =================================================

            guard let vertex =
                roadGraph
                    .vertices
                    .first(
                        where: {

                            $0.id
                            ==
                            edge.toID
                        }
                    )
            else {

                print(
                    "❌ Missing destination vertex for:",
                    edgeIDString
                )

                continue
            }


            // =================================================
            // Extra safety:
            // test fixture must remain in the future.
            // =================================================

            guard
                vertex
                    .coordinate
                    .time
                    .secondsFromMidnight
                >
                currentDayTime
                    .secondsFromMidnight
            else {

                print(
                    "⚠️ Skipping past vertex:",
                    edgeIDString,
                    vertex.coordinate.time.displayClockString
                )

                continue
            }


            result.append(
                vertex
            )


            print(
                """
                ✅ \(edgeIDString)
                   vertex: \(vertex.id)
                   time: \(vertex.coordinate.time.displayClockString)
                   progress: \(vertex.coordinate.progress.percent)
                """
            )
        }


        print(
            "Selected vertices:",
            result.count
        )

        print("==========================================")
        print("")


        return result
    }
}

#endif

#if DEBUG

extension GameStore {

    func printDebugRouteVertices() {

        let vertices =
            debugRouteTestVertices()


        print("")
        print("========== PATH TEST VERTICES ==========")


        for (
            index,
            vertex
        ) in vertices.enumerated() {

            print(
                """
                \(index):
                ID: \(vertex.id)
                Time: \(vertex.coordinate.time.displayClockString)
                Progress: \(vertex.coordinate.progress.percent)
                """
            )
        }


        print("=========================================")
        print("")
    }
}

#endif

#if DEBUG

private extension GameStore {

    func makeDebugRouteNode(
        vertex:
            RoadVertex,

        title:
            String,

        symbol _legacySymbol:
            String
    ) -> GameMapNode {

        let activityID =
            "debug-" +
            title
                .lowercased()
                .replacingOccurrences(
                    of:
                        " ",
                    with:
                        "-"
                )


        return GameMapNode(
            id:
                GameNodeID(),

            placement:
                .roadVertex(
                    vertex.id
                ),

            time:
                vertex.coordinate.time,

            content:
                .activity(
                    ActivityNodeContent(
                        activityID:
                            activityID,

                        title:
                            title,

                        description:
                            "Debug day-map path fixture",

                        image:
                            nil
                    )
                ),

            isEnabled:
                true
        )
    }
}

#endif

#if DEBUG

extension GameStore {

    @discardableResult
    func installDebugRouteScenario()
        -> DebugRouteScenario? {

        // =====================================================
        // 1. Predictable test time.
        // =====================================================

        resetSimulationDay(
            to:
                DayTime(
                    secondsFromMidnight:
                        8
                        *
                        3600
                )
        )


        print("")
        print("==========================================")
        print("        INSTALL DEBUG PATH FIXTURE")
        print("==========================================")

        print(
            "Current game time:",
            currentDayTime.displayClockString
        )


        // =====================================================
        // 2. Resolve specifications into real graph vertices.
        // =====================================================

        var allNodeIDs:
            [GameNodeID] = []


        var routeStopIDs:
            [GameNodeID] = []


        var previousRouteStopTime:
            TimeInterval?


        for spec in
            debugRouteNodeSpecs {

            guard let vertex =
                debugDestinationVertex(
                    forEdgeID:
                        spec.edgeID
                )
            else {

                print(
                    "❌ Fixture installation aborted."
                )

                return nil
            }


            let vertexTime =
                vertex
                    .coordinate
                    .time
                    .secondsFromMidnight


            // =================================================
            // Every fixture node should be in the future.
            // =================================================

            guard
                vertexTime
                >
                currentDayTime
                    .secondsFromMidnight
            else {

                print(
                    """
                    ❌ Debug stop is not in future.
                    Title: \(spec.title)
                    Time: \(vertex.coordinate.time.displayClockString)
                    """
                )

                return nil
            }


            // =================================================
            // Route stops must move forward through time.
            // =================================================

            if spec.isRouteStop {

                if let previousRouteStopTime {

                    guard
                        vertexTime
                        >
                        previousRouteStopTime
                    else {

                        print(
                            """
                            ❌ Debug path-stop time order invalid.
                            Stop: \(spec.title)
                            Time: \(vertex.coordinate.time.displayClockString)
                            """
                        )

                        return nil
                    }
                }


                previousRouteStopTime =
                    vertexTime
            }


            // =================================================
            // Create node.
            // =================================================

            let node =
                makeDebugRouteNode(
                    vertex:
                        vertex,

                    title:
                        spec.title,

                    symbol:
                        spec.symbol
                )


            // =================================================
            // Add using normal GameStore API.
            // =================================================

            addGameNode(
                node
            )


            allNodeIDs.append(
                node.id
            )


            if spec.isRouteStop {

                routeStopIDs.append(
                    node.id
                )
            }


            print(
                """
                \(spec.isRouteStop ? "🟢 PATH STOP" : "⚪ MAP STOP")
                \(spec.title)
                Edge: \(spec.edgeID)
                Time: \(vertex.coordinate.time.displayClockString)
                Progress: \(vertex.coordinate.progress.percent)
                """
            )
        }


        // =====================================================
        // 3. Verify expected fixture sizes.
        // =====================================================

        guard
            allNodeIDs.count
            ==
            12
        else {

            print(
                "❌ Expected 12 debug stops; got:",
                allNodeIDs.count
            )

            return nil
        }


        guard
            routeStopIDs.count
            ==
            6
        else {

            print(
                "❌ Expected 6 path stops; got:",
                routeStopIDs.count
            )

            return nil
        }


        // =====================================================
        // 4. Publish scenario.
        // =====================================================

        let scenario =
            DebugRouteScenario(
                allNodeIDs:
                    allNodeIDs,

                routeStopNodeIDs:
                    routeStopIDs
            )


        debugRouteScenario =
            scenario


        print("")
        print(
            "✅ Debug path scenario installed."
        )

        print(
            "Visible stops:",
            scenario.nodeCount
        )

        print(
            "Chosen-path waypoints:",
            scenario.routeStopCount
        )

        print("==========================================")
        print("")


        return scenario
    }
}

#endif

#if DEBUG

extension GameStore {

    func buildDebugChosenRoute() {

        // =====================================================
        // 1. Require installed fixture.
        // =====================================================

        guard let scenario =
            debugRouteScenario
        else {

            print(
                "❌ Install debug path scenario first."
            )

            return
        }


        guard
            scenario.routeStopNodeIDs.count
            >=
            2
        else {

            print(
                "❌ Debug scenario has too few path stops."
            )

            return
        }


        print("")
        print("==========================================")
        print("       BUILD DEBUG CHOSEN PATH")
        print("==========================================")


        // =====================================================
        // 2. Start fresh draft.
        // =====================================================

        beginNewFutureRouteDraft()


        // =====================================================
        // 3. Add route waypoint nodes.
        //
        // The other debug nodes remain visible on the map,
        // but do not constrain route planning.
        // =====================================================

        for nodeID in
            scenario.routeStopNodeIDs {

            let added =
                addStopToFutureRouteDraft(
                    nodeID
                )


            guard added else {

                print(
                    "❌ Could not add debug path stop:",
                    nodeID
                )

                return
            }
        }


        print(
            "Draft stops:",
            futureRouteDraft
                .stopNodeIDs
                .count
        )


        // =====================================================
        // 4. Plan primary / chosen route.
        // =====================================================

        let planningResult =
            planFutureRouteDraft()


        guard
            planningResult.succeeded
        else {

            print("")
            print("❌ DEBUG PATH PLANNING FAILED")

            print(
                planningResult
            )

            print("")

            return
        }


        guard let plannedRoute =
            planningResult
                .plannedRoute
        else {

            print(
                "❌ Planning succeeded but plannedRoute is nil."
            )

            return
        }


        guard
            plannedRoute
                .isFullyPlanned
        else {

            print(
                "❌ Debug path is not fully planned."
            )

            return
        }


        print("")
        print("✅ PRIMARY PATH PLANNED")

        print(
            "Path:",
            plannedRoute.id
        )

        print(
            "Edges:",
            plannedRoute
                .orderedUniqueRoadEdgeIDs
                .count
        )

        print(
            "Cost:",
            plannedRoute
                .plannedTotalCost
            as Any
        )


        // =====================================================
        // 5. Generate preview + up to 2 alternatives.
        //
        // IMPORTANT:
        //
        // Do not inspect FutureRoutePreview.alternatives here.
        // Your FutureRoutePreview model does not expose such
        // a property.
        // =====================================================

        guard
            generateFutureRoutePreviewAlternatives(
                maximumAlternatives:
                    2
            )
            != nil
        else {

            print(
                "❌ Failed to generate future path preview."
            )

            return
        }
        
        print("")
        print(
            "✅ Future path preview generated."
        )


        // =====================================================
        // TEST:
        // Commit the preview into authoritative route state,
        // THEN remove the temporary preview.
        //
        // Expected:
        //   - chosen route remains visible
        //   - 2 alternatives remain visible
        //   - preview geometry disappears
        //
        // This lets us compare normal route rendering against
        // preview rendering.
        // =====================================================

        let commitResult =
            commitFutureRoutePreview()


        print("")
        print(
            "Commit result:",
            commitResult
        )


        // =====================================================
        // Clear ONLY the temporary preview after commit.
        // =====================================================

        futureRoutePreview =
            nil


        print(
            "🧪 Preview cleared after commit."
        )


        // =====================================================
        // Verify authoritative routes still exist.
        // =====================================================

        print("")
        print("========== POST-COMMIT PATH STATE ==========")

        print(
            "Chosen:",
            routeState
                .chosenFutureRoute
                .id
        )

        print(
            "Chosen edges:",
            routeState
                .chosenFutureRoute
                .orderedUniqueRoadEdgeIDs
                .count
        )

        print(
            "Alternatives:",
            routeState
                .alternativeRoutes
                .count
        )

        for (
            index,
            route
        ) in routeState
            .alternativeRoutes
            .enumerated()
        {

            print(
                """
                Alternative \(index + 1)
                  ID: \(route.id)
                  Edges: \(route.orderedUniqueRoadEdgeIDs.count)
                """
            )
        }

        print("=============================================")
        print("")

        // =====================================================
        // 7. Read ACTUAL stored route state.
        // =====================================================

        let chosenRoute =
            routeState
                .chosenFutureRoute


        let alternatives =
            routeState
                .alternativeRoutes


        print("")
        print("========== FINAL DEBUG PATH STATE ==========")


        // =====================================================
        // Chosen
        // =====================================================

        print(
            "Chosen ID:",
            chosenRoute.id
        )


        print(
            "Chosen edges:",
            chosenRoute
                .orderedUniqueRoadEdgeIDs
                .count
        )


        print(
            "Chosen cost:",
            chosenRoute
                .plannedTotalCost
            as Any
        )


        // =====================================================
        // Alternatives
        // =====================================================

        print(
            "Alternative count:",
            alternatives.count
        )


        for (
            index,
            route
        ) in alternatives.enumerated() {

            print(
                """
                Alternative \(index + 1)
                  ID: \(route.id)
                  Edges: \(route.orderedUniqueRoadEdgeIDs.count)
                  Cost: \(String(describing: route.plannedTotalCost))
                """
            )
        }


        // =====================================================
        // 8. Test expectation.
        // =====================================================

        if alternatives.count >= 2 {

            print("")
            print(
                "✅ TEST FIXTURE READY: 1 chosen + at least 2 alternatives."
            )

        } else {

            print("")
            print(
                """
                ⚠️ TEST FIXTURE GENERATED ONLY \(alternatives.count) ALTERNATIVE(S).

                The chosen path is valid, but AlternativeRouteGenerator
                did not find two sufficiently different valid paths.
                """
            )
        }


        print("============================================")
        print("")
    }
}

#endif

#if DEBUG

extension GameStore {

    func printDebugRouteState() {

        print("")
        print("========== PATH STATE ==========")

        print(
            "Completed segments:",
            routeState
                .completedRoute
                .segments
                .count
        )


        print(
            "Chosen:",
            routeState
                .chosenFutureRoute
                .id
        )


        print(
            "Alternatives:",
            routeState
                .alternativeRoutes
                .count
        )


        if let preview =
            futureRoutePreview
        {

            print(
                "Preview selected:",
                preview.selectedRouteID
            )


            print(
                "Preview alternatives:",
                preview.alternativeRoutes.count
            )
        }


        print("=================================")
        print("")
    }
    
}

#endif

#if DEBUG

private struct DebugRouteNodeSpec {

    let edgeID:
        String

    let title:
        String

    let symbol:
        String

    let isRouteStop:
        Bool
}

#endif

#if DEBUG

private extension GameStore {

    var debugRouteNodeSpecs:
        [DebugRouteNodeSpec] {

        [

            // =================================================
            // DESTINATION ROW 6 — 9:00 AM
            // =================================================

            DebugRouteNodeSpec(
                edgeID:
                    "street.v.c01.r05-06",
                title:
                    "Morning Walk",
                symbol:
                    "figure.walk",
                isRouteStop:
                    true
            ),

            DebugRouteNodeSpec(
                edgeID:
                    "street.v.c04.r05-06",
                title:
                    "Coffee Stop",
                symbol:
                    "cup.and.saucer.fill",
                isRouteStop:
                    false
            ),


            // =================================================
            // DESTINATION ROW 7 — 10:30 AM
            // =================================================

            DebugRouteNodeSpec(
                edgeID:
                    "street.v.c05.r06-07",
                title:
                    "Breakfast",
                symbol:
                    "fork.knife",
                isRouteStop:
                    false
            ),

            DebugRouteNodeSpec(
                edgeID:
                    "street.v.c07.r06-07",
                title:
                    "Gym",
                symbol:
                    "figure.strengthtraining.traditional",
                isRouteStop:
                    true
            ),


            // =================================================
            // DESTINATION ROW 8 — 12:00 PM
            // =================================================

            DebugRouteNodeSpec(
                edgeID:
                    "street.v.c02.r07-08",
                title:
                    "Lunch",
                symbol:
                    "takeoutbag.and.cup.and.straw.fill",
                isRouteStop:
                    true
            ),

            DebugRouteNodeSpec(
                edgeID:
                    "street.v.c05.r07-08",
                title:
                    "Park",
                symbol:
                    "tree.fill",
                isRouteStop:
                    false
            ),


            // =================================================
            // DESTINATION ROW 9 — 1:30 PM
            // =================================================

            DebugRouteNodeSpec(
                edgeID:
                    "street.v.c04.r08-09",
                title:
                    "Coffee Break",
                symbol:
                    "mug.fill",
                isRouteStop:
                    false
            ),

            DebugRouteNodeSpec(
                edgeID:
                    "street.v.c08.r08-09",
                title:
                    "Work Session",
                symbol:
                    "briefcase.fill",
                isRouteStop:
                    true
            ),


            // =================================================
            // DESTINATION ROW 10 — 3:00 PM
            // =================================================

            DebugRouteNodeSpec(
                edgeID:
                    "street.v.c03.r09-10",
                title:
                    "Evening Run",
                symbol:
                    "figure.run",
                isRouteStop:
                    true
            ),

            DebugRouteNodeSpec(
                edgeID:
                    "street.v.c06.r09-10",
                title:
                    "Grocery Stop",
                symbol:
                    "cart.fill",
                isRouteStop:
                    false
            ),


            // =================================================
            // DESTINATION ROW 11 — 4:30 PM
            // =================================================

            DebugRouteNodeSpec(
                edgeID:
                    "street.v.c05.r10-11",
                title:
                    "Friend Meetup",
                symbol:
                    "person.2.fill",
                isRouteStop:
                    false
            ),

            DebugRouteNodeSpec(
                edgeID:
                    "street.v.c07.r10-11",
                title:
                    "Dinner",
                symbol:
                    "fork.knife.circle.fill",
                isRouteStop:
                    true
            )
        ]
    }
}

#endif

#if DEBUG

private extension GameStore {

    func debugDestinationVertex(
        forEdgeID edgeID:
            String
    ) -> RoadVertex? {

        // =====================================================
        // Find road edge.
        // =====================================================

        guard let edge =
            roadGraph
                .edges
                .first(
                    where: {

                        $0.id.rawValue
                        ==
                        edgeID
                    }
                )
        else {

            print(
                "❌ Debug edge does not exist:",
                edgeID
            )

            return nil
        }


        // =====================================================
        // Get its destination vertex.
        //
        // For:
        //
        // street.v.c01.r03-04
        //
        // this gives us the intersection at row 04.
        // =====================================================

        guard let vertex =
            roadGraph
                .vertices
                .first(
                    where: {

                        $0.id
                        ==
                        edge.toID
                    }
                )
        else {

            print(
                "❌ Destination vertex missing for:",
                edgeID
            )

            return nil
        }


        return vertex
    }
}

#endif




// =====================================================
// MARK: - Backend Synchronization
// =====================================================

extension GameStore {

    /// Replaces explicit discovery/reveal state from the authoritative day
    /// snapshot. Route/user-created tiles may still resolve as revealed through
    /// DayMapTile projection rules even when they are not present in this set.
    func replaceRevealedTilesFromServer(
        _ cellIDs: Set<GridCellID>
    ) {

        revealedTileIDs = cellIDs
    }


    /// Applies one cross-device reveal state update without disturbing other
    /// revealed tiles.
    func setTileRevealFromServer(
        _ cellID: GridCellID,
        isRevealed: Bool
    ) {

        if isRevealed {
            revealedTileIDs.insert(cellID)
        } else {
            revealedTileIDs.remove(cellID)
        }
    }


    /// Replaces the current map node collection with the server snapshot while
    /// preserving the existing road graph as the local geometry source.
    func replaceGameNodesFromServer(
        _ nodes: [GameMapNode]
    ) {

        gameNodes =
            nodes.map {
                synchronizedNodeTime(
                    $0
                )
            }

        if tileRevealPolicy == .revealAllNodes {

            for node in gameNodes {
                revealTileContaining(node)
            }
        }

        selection.clear()
        pendingNodeAction = nil
        pendingStackedNodeSelection = nil
    }


    /// Inserts a server node if it does not exist, otherwise replaces the
    /// cached version. Incoming state is normalized against the local road
    /// graph before becoming visible to SpriteKit/SwiftUI.
    func upsertGameNodeFromServer(
        _ node: GameMapNode
    ) {

        let synchronized =
            synchronizedNodeTime(
                node
            )

        if let index =
            gameNodes.firstIndex(
                where: {
                    $0.id == node.id
                }
            ) {

            gameNodes[index] =
                synchronized

        } else {

            gameNodes.append(
                synchronized
            )
        }

        if tileRevealPolicy == .revealAllNodes {

            revealTileContaining(
                synchronized
            )
        }
    }


    func deleteGameNodeFromServer(
        id: GameNodeID
    ) {

        deleteGameNode(
            id: id
        )
    }


    /// Server route state is already a validated semantic model. The map's
    /// deterministic grid remains responsible for rendering the geometry.
    func replaceRouteStateFromServer(
        _ newRouteState: DayRouteState
    ) {

        routeState =
            newRouteState

        futureRouteDraft =
            FutureRouteDraft()

        futureRouteDraftPlan =
            nil

        futureRoutePreview =
            nil

        pendingRouteAction =
            nil
    }
}
