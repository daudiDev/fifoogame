//
//  VirtualMapScene.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/25/26.
//



import SpriteKit


@MainActor
final class VirtualMapScene: SKScene {
    
    private let timeAxisRenderer =
        TimeAxisRenderer()
    
    // =====================================================
    // MARK: - Interaction
    // =====================================================

    weak var interactionDelegate:
        SceneInteractionDelegate?


    /// Semantic taps can be suppressed independently from the camera
    /// gestures. Alternate-route preview mode uses this so the user can keep
    /// panning and pinching the map while every card/node interaction is
    /// temporarily disabled.
    private var semanticTapsEnabled =
        true


    func setSemanticTapsEnabled(
        _ isEnabled: Bool
    ) {

        semanticTapsEnabled =
            isEnabled
    }


    // =====================================================
    // MARK: - Domain Input
    // =====================================================

    private let roadGraph:
        RoadGraph


    private var gameNodes:
        [GameMapNode]

    private var revealedTileIDs:
        Set<GridCellID>

    /// Non-nil only while one alternate route is temporarily isolated after
    /// the user's first tap on an alternate GameNode card. The tile resolver
    /// uses this to restore join lines and expose that route's transit cells.
    private var focusedAlternativeRouteID:
        RouteID? = nil


    // =====================================================
    // MARK: - Scene Layers
    // =====================================================

    private let backgroundLayer =
        SKNode()

    private let gridLayer =
        SKNode()

    private let roadLayer =
        SKNode()

    private let routeLayer =
        SKNode()

    private let nodeLayer =
        SKNode()

    private let timeIndicatorLayer =
        SKNode()

    private let selectionLayer =
        SKNode()

    private let debugLayer =
        SKNode()


    // =====================================================
    // MARK: - Renderers
    // =====================================================

    private let gridRenderer =
        MapGridRenderer()


    private let roadSelectionRenderer =
        RoadSelectionRenderer()


    private let currentTimeRenderer =
        CurrentTimeRenderer()


    private let gameNodeRenderer =
        GameNodeRenderer()
    
    private let routeRenderer =
        RouteLayerRenderer()
    
    private var currentRouteRenderState:
        RouteRenderState =
            .empty
    
    private var currentRoutePreviewRenderState:
        RoutePreviewRenderState =
            .empty


    // =====================================================
    // MARK: - Hit Testing
    // =====================================================

    private let roadHitTester =
        RoadHitTester()


    private let gameNodeHitTester =
        GameNodeHitTester()
    
    private let routeHitTester =
        RouteHitTester()


    // =====================================================
    // MARK: - Camera
    // =====================================================

    private let cameraController =
        MapCameraController()


    // =====================================================
    // MARK: - Scene State
    // =====================================================

    private var currentTime:
        DayTime

    private var currentProgressPercent:
        Double


    /*
     Keep the current semantic selection in the scene.

     GameStore remains authoritative.

     This copy only lets us restore the visual selection
     when nodes are re-rendered.
     */
    private var currentSelection =
        SelectionState()


    // =====================================================
    // MARK: - Touch State
    // =====================================================

    private var touchBeganWhileMomentumWasActive =
        false


    private var gestureContainsMultipleTouches =
        false


    // =====================================================
    // MARK: - Init
    // =====================================================

    init(
        initialTime:
            DayTime,
        initialProgressPercent:
            Double = 0,
        roadGraph:
            RoadGraph,
        gameNodes:
            [GameMapNode],
        revealedTileIDs:
            Set<GridCellID> = []
    ) {

        self.currentTime =
            initialTime

        self.currentProgressPercent =
            initialProgressPercent


        self.roadGraph =
            roadGraph


        self.gameNodes =
            gameNodes

        self.revealedTileIDs =
            revealedTileIDs


        super.init(
            size:
                MapWorldConfiguration
                    .sceneSize
        )


        commonInit()
    }


    required init?(
        coder aDecoder:
            NSCoder
    ) {

        self.currentTime =
            .noon

        self.currentProgressPercent =
            0


        self.roadGraph =
            GridRoadGraph.make()


        self.gameNodes =
            []

        self.revealedTileIDs =
            []


        super.init(
            coder:
                aDecoder
        )


        commonInit()
    }
    
    // =====================================================
    // MARK: - Route Rendering
    // =====================================================

    func renderRoutes(
        _ state:
            RouteRenderState,
        focusedAlternativeRouteID:
            RouteID? = nil,
        currentUserAvatarAssetName:
            String? = nil
    ) {

        // The semantic road/pathfinding system remains authoritative, but
        // route geometry is now visualized as tile boundaries rather than
        // painted road lines. The avatar argument remains for source/API
        // compatibility while the migration is staged.
        _ = currentUserAvatarAssetName

        currentRouteRenderState =
            state

        self.focusedAlternativeRouteID =
            focusedAlternativeRouteID

        refreshTilePresentation()
    }
    
    // =====================================================
    // MARK: - Route Preview Rendering
    // =====================================================

    func renderRoutePreview(
        _ state:
            RoutePreviewRenderState
    ) {

        currentRoutePreviewRenderState =
            state

        refreshTilePresentation()
    }
    
    func clearRoutePreview() {

        currentRoutePreviewRenderState =
            .empty

        refreshTilePresentation()
    }
    
    private func updateTimeAxis() {

        guard
            let camera,
            let view
        else {

            return
        }


        timeAxisRenderer.update(
            scene: self,
            camera: camera,
            view: view
        )
    }
    
    

    
}


// =====================================================
// MARK: - Initial Configuration
// =====================================================

private extension VirtualMapScene {

    func commonInit() {

        #if DEBUG
        MapCoordinateConverter
            .debugAssertCartesianScale()

        GridMapGeometry
            .debugAssertGeometry()

        GridRoadTopology
            .debugAssertTopology()

        if roadGraph.id == GridRoadGraph.graphID {
            GridRoadGraph
                .debugAssertGraph(
                    roadGraph
                )
        }
        #endif


        // MARK: Coordinate System

        /*
         Fifoo world:

         top-left:
             (0, 0)

         bottom:
             y = -MapWorldConfiguration.height

         With the Cartesian redesign this is currently:
             y = -2000
         */

        anchorPoint =
            CGPoint(
                x: 0,
                y: 1
            )


        scaleMode =
            .aspectFit


        // Tile redesign: roads are no longer a visible map layer. The scene
        // is a quiet continuous backdrop behind deterministic square cards.
        backgroundColor =
            MapVisualTheme
                .tileMapBackgroundColor


        /*
         Build all scene content immediately.

         None of these operations require SKView.
         */

        configureLayers()

        configureCoordinateGrid()

        // Step 4: GridRoadGraph is now the active road topology.
        // The visible road surface remains the Step 3 grid renderer; the
        // graph supplies deterministic intersections/edges for nodes, taps,
        // routes, and future pathfinding.

        configureGameNodes()

//        configureCurrentTimeIndicator() //MARK: hide for now

//        configureDiagnostics()
    }
}


// =====================================================
// MARK: - Lifecycle
// =====================================================

extension VirtualMapScene {

    override func didMove(
        to view:
            SKView
    ) {

        super.didMove(
            to:
                view
        )
        
        // Step 4: legacy procedural road topology/artwork is no longer
        // active. MapGridRenderer is the visible world and GridRoadGraph is
        // the semantic road network underneath it.

        cameraController.install(
            in:
                self,
            view:
                view,
            initialFocusTime:
                currentTime
        )


        // =====================================================
        // Step 3 — Initialize Visible Cartesian Grid Rendering
        // =====================================================

        gridRenderer
            .updateVisibleRegion(
                scene: self,
                view: view
            )
        
        guard
            let camera = camera
        else {

            return
        }
        
        timeAxisRenderer.attach(
            to: camera
        )

        // Step 8 positions the persistent labels immediately so there is no
        // one-frame flash at the camera origin before didFinishUpdate().
        timeAxisRenderer.update(
            scene: self,
            camera: camera,
            view: view
        )
        
        // Legacy road labels remain intentionally hidden. The Cartesian
        // roads are uniform and unlabeled.
        
    }


    override func willMove(
        from view:
            SKView
    ) {

        /*
         Remove UIKit gesture recognizers before
         the SpriteKit view goes away.
         */

        cameraController
            .detachGestures(
                from:
                    view
            )


        resetTouchState()


        super.willMove(
            from:
                view
        )
    }
    
    override func didFinishUpdate() {

        super.didFinishUpdate()


        guard
            let camera,
            let view
        else {

            return
        }


        // =====================================================
        // Step 7 — Camera Integration Safety
        // =====================================================

        // Pan, pinch and momentum already clamp during gestures. Re-clamping
        // here also covers view-size/orientation changes from SwiftUI without
        // requiring the user to touch the map again.
        cameraController
            .clampCamera(
                in: self,
                view: view
            )


        // =====================================================
        // Visible Cartesian Grid Rendering
        // =====================================================

        gridRenderer
            .updateVisibleRegion(
                scene: self,
                view: view
            )


        // =====================================================
        // Persistent Time Axis
        // =====================================================

        timeAxisRenderer.update(
            scene:
                self,

            camera:
                camera,

            view:
                view
        )


        // Step 8 renderers internally skip work while the camera is
        // stationary. When it moves, the visible grid reuses pooled cells
        // and the time axis recalculates only its five semantic labels.
    }
    
}

// =====================================================
// MARK: - SpriteKit Frame Update
// =====================================================

extension VirtualMapScene {

    override func update(
        _ currentFrameTime:
            TimeInterval
    ) {

        super.update(
            currentFrameTime
        )


        cameraController
            .updateMomentum(
                currentTime:
                    currentFrameTime
            )
        
    }
}

// =====================================================
// MARK: - Layers
// =====================================================

private extension VirtualMapScene {

    func configureLayers() {

        // MARK: Names

        backgroundLayer.name =
            "backgroundLayer"

        gridLayer.name =
            "gridLayer"

        roadLayer.name =
            "roadLayer"

        routeLayer.name =
            "routeLayer"

        nodeLayer.name =
            "nodeLayer"

        timeIndicatorLayer.name =
            "timeIndicatorLayer"

        selectionLayer.name =
            "selectionLayer"

        debugLayer.name =
            "debugLayer"


        // MARK: Z Order

        // Step 7 makes the scene hierarchy explicit and uses MapLayerZ as
        // the single source of truth. The old mixed local/global values
        // could place selection overlays above nodes or make renderer-local
        // zPositions accidentally double-count.

        backgroundLayer.zPosition =
            MapLayerZ.terrain

        // The Cartesian island renderer owns land + road markings. Its
        // internal ordering handles shadow -> island -> dash.
        gridLayer.zPosition =
            MapLayerZ.blocks

        // Reserved for semantic road overlays. The visible road surface is
        // still the scene background / exposed space between islands.
        roadLayer.zPosition =
            MapLayerZ.roads

        // Road selection belongs above road markings but below routes.
        selectionLayer.zPosition =
            MapLayerZ.roadSelection

        routeLayer.zPosition =
            MapLayerZ.routes

        // Current-time graphics, when enabled, should not cover game nodes.
        timeIndicatorLayer.zPosition =
            MapLayerZ.routes + 75

        nodeLayer.zPosition =
            MapLayerZ.nodes

        debugLayer.zPosition =
            MapLayerZ.nodes + 10_000


        // MARK: Scene Hierarchy

        addChild(
            backgroundLayer
        )


        addChild(
            gridLayer
        )


        addChild(
            roadLayer
        )


        addChild(
            routeLayer
        )


        addChild(
            nodeLayer
        )


        addChild(
            timeIndicatorLayer
        )


        addChild(
            selectionLayer
        )


        addChild(
            debugLayer
        )


        // MARK: Renderer Hierarchy

        gridLayer.addChild(
            gridRenderer
                .containerNode
        )


        // Road, route-line, and map-marker renderers intentionally remain
        // detached. Their domain logic is retained elsewhere, while the card
        // renderer owns visible nodes, route state, and selection styling.

        // Pass 5.61: no live-position label/marker is rendered. The layer is
        // retained for compatibility but intentionally has no children.
    }
}

// =====================================================
// MARK: - Cartesian Grid Foundation
// =====================================================

private extension VirtualMapScene {

    func configureCoordinateGrid() {

        // Preserve the deterministic Cartesian cell pitch, but render each
        // cell as a standalone card rather than an island between roads.
        gridRenderer.rebuild()
        refreshTilePresentation(animated: false)
    }
}


// =====================================================
// MARK: - Road Network
// =====================================================

private extension VirtualMapScene {

    func configureRoadNetwork() {

        // Intentionally empty visually.
        //
        // Step 4 uses GridRoadGraph for semantic road topology while the
        // Step 3 grid/island renderer supplies the visible street surface.
    }
}


// =====================================================
// MARK: - Game Nodes
// =====================================================

private extension VirtualMapScene {

    func configureGameNodes() {

        refreshTilePresentation(
            animated: false
        )
    }
}


// =====================================================
// MARK: - Current Time
// =====================================================

private extension VirtualMapScene {

    func configureCurrentTimeIndicator() {

        // Intentionally empty. Current-time emphasis is conveyed only by the
        // 130% sizing of real stops in the current clock hour.
    }
}

// =====================================================
// MARK: - Game Node API
// =====================================================

extension VirtualMapScene {

    func renderGameNodes(
        _ nodes:
            [GameMapNode]
    ) {

        gameNodes =
            nodes

        refreshTilePresentation()
    }
}

// =====================================================
// MARK: - Tile Reveal API
// =====================================================

extension VirtualMapScene {

    func renderRevealedTiles(
        _ ids: Set<GridCellID>
    ) {

        revealedTileIDs =
            ids

        refreshTilePresentation()
    }
}


// =====================================================
// MARK: - Current Time API
// =====================================================

extension VirtualMapScene {

    func renderCurrentTime(
        _ time:
            DayTime
    ) {

        currentTime =
            time


        // Tile mode enlarges all real stops scheduled inside the current
        // clock hour by 30%. No separate live-position label is rendered.
        gridRenderer.renderCurrentTime(
            time
        )
    }


    func renderCurrentProgress(
        _ percent: Double
    ) {

        guard currentProgressPercent != percent else {
            return
        }

        currentProgressPercent =
            percent

        refreshTilePresentation(
            animated: false
        )
    }


    func centerCameraOnCurrentTime(
        animated:
            Bool = true
    ) {

        guard let view else {

            return
        }


        cameraController.center(
            on:
                currentTime,
            in:
                self,
            view:
                view,
            animated:
                animated
        )
    }
}

// =====================================================
// MARK: - Selection API
// =====================================================

extension VirtualMapScene {

    func renderSelection(
        _ selection:
            SelectionState
    ) {

        currentSelection =
            selection

        // Legacy road-selection and marker-selection layers are intentionally
        // empty in tile mode. Selection is expressed by the tile perimeter.
        roadSelectionRenderer.clear()

        refreshTilePresentation(
            animated: false
        )
    }
}

// =====================================================
// MARK: - Tile Presentation
// =====================================================

private extension VirtualMapScene {

    func refreshTilePresentation(
        animated: Bool = true
    ) {

        let state =
            DayMapTileResolver
                .makeRenderState(
                    gameNodes:
                        gameNodes,
                    roadGraph:
                        roadGraph,
                    routes:
                        currentRouteRenderState,
                    preview:
                        currentRoutePreviewRenderState,
                    selection:
                        currentSelection,
                    revealedCellIDs:
                        revealedTileIDs,
                    currentProgressPercent:
                        currentProgressPercent,
                    focusedAlternativeRouteID:
                        focusedAlternativeRouteID
                )


        gridRenderer.render(
            state,
            animated: animated
        )
    }
}


// =====================================================
// MARK: - Diagnostics
// =====================================================

private extension VirtualMapScene {

    func configureDiagnostics() {

        debugLayer
            .removeAllChildren()


        drawWorldBoundary()

        drawCenterReferencePoint()
    }


    func drawWorldBoundary() {

        drawExplorationBoundary()

        drawReferenceProgressBoundary()
    }


    func drawExplorationBoundary() {

        let rect =
            CGRect(
                x:
                    MapWorldConfiguration
                        .minimumExplorableX,
                y:
                    -MapWorldConfiguration
                        .height,
                width:
                    MapWorldConfiguration
                        .explorableWorldWidth,
                height:
                    MapWorldConfiguration
                        .height
            )


        let boundary =
            SKShapeNode(
                rect:
                    rect
            )


        boundary.name =
            "explorationBoundary"


        boundary.strokeColor =
            .systemTeal


        boundary.lineWidth =
            8


        boundary.fillColor =
            .clear


        debugLayer.addChild(
            boundary
        )
    }


    func drawReferenceProgressBoundary() {

        let rect =
            CGRect(
                x: 0,
                y:
                    -MapWorldConfiguration
                        .height,
                width:
                    MapWorldConfiguration
                        .width,
                height:
                    MapWorldConfiguration
                        .height
            )


        let boundary =
            SKShapeNode(
                rect:
                    rect
            )


        boundary.name =
            "referenceProgressBoundary"


        boundary.strokeColor =
            MapVisualTheme
                .referenceBoundaryColor


        boundary.lineWidth =
            4


        boundary.fillColor =
            .clear


        debugLayer.addChild(
            boundary
        )
    }


    func drawCenterReferencePoint() {

        let coordinate =
            MapCoordinate(
                time:
                    .noon,
                progress:
                    MapProgress(
                        50
                    )
            )


        let worldPoint =
            MapCoordinateConverter
                .worldPoint(
                    for:
                        coordinate
                )


        let marker =
            SKShapeNode(
                circleOfRadius:
                    28
            )


        marker.name =
            "centerReferenceMarker"


        marker.position =
            worldPoint.cgPoint


        marker.fillColor =
            .systemYellow


        marker.strokeColor =
            .white


        marker.lineWidth =
            5


        debugLayer.addChild(
            marker
        )


        let label =
            SKLabelNode(
                fontNamed:
                    "HelveticaNeue-Bold"
            )


        label.text =
            "50% • 12 PM"


        label.fontSize =
            30


        label.fontColor =
            .white


        label.position =
            CGPoint(
                x:
                    worldPoint.x,
                y:
                    worldPoint.y - 65
            )


        label.horizontalAlignmentMode =
            .center


        debugLayer.addChild(
            label
        )
    }
}

// =====================================================
// MARK: - Touch Handling
// =====================================================

extension VirtualMapScene {

    override func touchesBegan(
        _ touches:
            Set<UITouch>,
        with event:
            UIEvent?
    ) {

        super.touchesBegan(
            touches,
            with:
                event
        )


        let activeCount =
            event?
                .allTouches?
                .filter {

                    $0.phase !=
                        .ended

                    &&

                    $0.phase !=
                        .cancelled
                }
                .count

            ??
            touches.count


        gestureContainsMultipleTouches =
            activeCount > 1


        touchBeganWhileMomentumWasActive =
            cameraController
                .isMomentumActive


        /*
         Touching a coasting map immediately
         grabs/stops the map.
         */

        cameraController
            .cancelMomentum()
    }

    override func touchesEnded(
        _ touches:
            Set<UITouch>,
        with event:
            UIEvent?
    ) {

        super.touchesEnded(
            touches,
            with:
                event
        )


        defer {

            resetTouchState()
        }


        // =========================================
        // Touch was used to stop momentum
        // =========================================

        guard
            !touchBeganWhileMomentumWasActive
        else {

            return
        }


        // =========================================
        // Ignore camera gestures
        // =========================================

        guard
            !gestureContainsMultipleTouches,
            !cameraController.isPinching,
            !cameraController.isPanning
        else {

            return
        }


        // =========================================
        // Semantic Tap
        // =========================================

        // Alternate-route preview mode disables only semantic map taps.
        // Camera pan/pinch handling has already happened above, so those
        // gestures remain fully available while the preview overlay is shown.
        guard semanticTapsEnabled else {
            return
        }


        guard let touch =
            touches.first
        else {

            return
        }


        emitSemanticTap(
            for:
                touch
        )
    }


    override func touchesCancelled(
        _ touches:
            Set<UITouch>,
        with event:
            UIEvent?
    ) {

        super.touchesCancelled(
            touches,
            with:
                event
        )


        resetTouchState()
    }
    
    
}

// =====================================================
// MARK: - Touch State
// =====================================================

private extension VirtualMapScene {

    func resetTouchState() {

        touchBeganWhileMomentumWasActive =
            false


        gestureContainsMultipleTouches =
            false
    }
}

// =====================================================
// MARK: - Semantic Hit Testing
// =====================================================

private extension VirtualMapScene {

    func emitSemanticTap(
        for touch:
            UITouch
    ) {

        let point =
            touch.location(
                in:
                    self
            )


        let worldPoint =
            WorldPoint(
                x:
                    point.x,
                y:
                    point.y
            )


        let mapCoordinate =
            MapCoordinateConverter
                .mapCoordinate(
                    for:
                        worldPoint
                )


        // =====================================================
        // Tile/Card Interaction
        // =====================================================

        guard let cellID =
            gridRenderer
                .tileCellID(
                    hitByWorldPoint:
                        point
                )
        else {

            emit(
                .backgroundTapped(
                    worldPoint:
                        worldPoint,
                    mapCoordinate:
                        mapCoordinate
                )
            )

            return
        }


        let snapshot =
            gridRenderer
                .snapshot(
                    for: cellID
                )


        // Once an empty card has been revealed, only the Add Stop label at
        // the bottom of that face emits a semantic action. The rest of the
        // empty face is informational (time / Piper / progress delta).
        if snapshot.revealState == .revealed,
           !snapshot.hasNode,
           !gridRenderer.isAddStopActionHit(
                worldPoint: point,
                in: cellID
           )
        {
            return
        }


        // Taps resolve to the semantic center of the card rather than the
        // exact finger position. This keeps Add Node placement deterministic
        // and aligns every created item with the square-card UI.
        let tileCoordinate =
            GridMapGeometry
                .mapCoordinateAtTileCenter(
                    for: cellID
                )


        if snapshot.revealState == .revealed,
           snapshot.nodePreviews.count > 1
        {
            emit(
                .stackedDayTileTapped(
                    cellID:
                        cellID,
                    nodePreviews:
                        snapshot.nodePreviews,
                    routeTarget:
                        snapshot.routeInteractionTarget,
                    worldPoint:
                        worldPoint,
                    mapCoordinate:
                        tileCoordinate
                )
            )

            return
        }


        emit(
            .dayTileTapped(
                cellID:
                    cellID,
                nodeID:
                    snapshot.primaryNodeID,
                routeTarget:
                    snapshot.routeInteractionTarget,
                isRevealed:
                    snapshot.revealState == .revealed,
                worldPoint:
                    worldPoint,
                mapCoordinate:
                    tileCoordinate
            )
        )
    }


    func emit(
        _ interaction:
            SceneInteraction
    ) {

        interactionDelegate?
            .sceneDidEmit(
                interaction
            )
    }
}

// =====================================================
// MARK: - Screen -> World Hit Tolerance
// =====================================================

private extension VirtualMapScene {

    func worldHitTolerance(
        touch:
            UITouch,
        screenPoints:
            CGFloat
    ) -> CGFloat {

        guard let view else {

            return 20
        }


        let viewPoint =
            touch.location(
                in:
                    view
            )


        let origin =
            convertPoint(
                fromView:
                    viewPoint
            )


        let horizontal =
            convertPoint(
                fromView:
                    CGPoint(
                        x:
                            viewPoint.x
                            +
                            screenPoints,
                        y:
                            viewPoint.y
                    )
            )


        let vertical =
            convertPoint(
                fromView:
                    CGPoint(
                        x:
                            viewPoint.x,
                        y:
                            viewPoint.y
                            +
                            screenPoints
                    )
            )


        let horizontalDistance =
            hypot(
                horizontal.x
                -
                origin.x,
                horizontal.y
                -
                origin.y
            )


        let verticalDistance =
            hypot(
                vertical.x
                -
                origin.x,
                vertical.y
                -
                origin.y
            )


        return max(
            horizontalDistance,
            verticalDistance
        )
    }
}

