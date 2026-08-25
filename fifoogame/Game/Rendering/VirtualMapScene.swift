//
//  VirtualMapScene.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/24/26.
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


    // =====================================================
    // MARK: - Domain Input
    // =====================================================

    private let roadGraph:
        RoadGraph


    private var gameNodes:
        [GameMapNode]


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
        roadGraph:
            RoadGraph,
        gameNodes:
            [GameMapNode]
    ) {

        self.currentTime =
            initialTime


        self.roadGraph =
            roadGraph


        self.gameNodes =
            gameNodes


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


        self.roadGraph =
            GridRoadGraph.make()


        self.gameNodes =
            SampleGameNodes.make()


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
            RouteRenderState
    ) {

        currentRouteRenderState =
            state


        routeRenderer.render(
            state,
            graph:
                roadGraph,
            selectedRouteID:
                currentSelection
                    .selectedRouteID
        )
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


        routeRenderer
            .renderPreview(
                state,
                graph:
                    roadGraph
            )
    }
    
    func clearRoutePreview() {

        currentRoutePreviewRenderState =
            .empty


        routeRenderer
            .clearPreview()
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


        // Step 3: the scene itself is the continuous road surface.
        // Rounded land islands are rendered above it by MapGridRenderer.
        backgroundColor =
            MapVisualTheme
                .roadSurfaceColor


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


        // The road surface is rendered by MapGridRenderer. The semantic
        // roadLayer remains available for future road-specific overlays but
        // no legacy RoadLayerRenderer is attached.
        
        routeRenderer.attach(
              to:
                  routeLayer
        )


        nodeLayer.addChild(
            gameNodeRenderer
                .containerNode
        )


        timeIndicatorLayer.addChild(
            currentTimeRenderer
                .containerNode
        )


        selectionLayer.addChild(
            roadSelectionRenderer
                .containerNode
        )
    }
}

// =====================================================
// MARK: - Cartesian Grid Foundation
// =====================================================

private extension VirtualMapScene {

    func configureCoordinateGrid() {

        // Step 3 resets the old debug grid and prepares the dynamic
        // rounded-island / road-dash renderer.
        gridRenderer.rebuild()
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

        gameNodeRenderer.render(
            nodes:
                gameNodes,
            roadGraph:
                roadGraph
        )
    }
}


// =====================================================
// MARK: - Current Time
// =====================================================

private extension VirtualMapScene {

    func configureCurrentTimeIndicator() {

        currentTimeRenderer.render(
            time:
                currentTime
        )
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


        gameNodeRenderer.render(
            nodes:
                gameNodes,
            roadGraph:
                roadGraph
        )


        gameNodeRenderer
            .renderSelection(
                selectedNodeID:
                    currentSelection
                        .selectedNodeID
            )
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


        currentTimeRenderer.render(
            time:
                time
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

        // =================================================
        // Store Current Selection
        // =================================================

        currentSelection =
            selection


        // =================================================
        // Road Edge / Vertex Selection
        // =================================================

        // Road/intersection taps are now creation anchors, not selections.
        // Keep the legacy renderer allocated for source compatibility, but do
        // not draw a road-selection halo/color change.
        roadSelectionRenderer.clear()


        // =================================================
        // Game Node Selection
        // =================================================

        // Do NOT rebuild game nodes just because selection changed.
        // Rebuilding cancels remote image tasks and can cause marker flicker.
        // Selection is a cheap visual toggle on the already-rendered nodes.
        gameNodeRenderer
            .renderSelection(
                selectedNodeID:
                    selection
                        .selectedNodeID
            )


        // =================================================
        // Route Selection
        // =================================================

        routeRenderer.render(
            currentRouteRenderState,
            graph:
                roadGraph,
            selectedRouteID:
                selection
                    .selectedRouteID
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


        let tolerance =
            worldHitTolerance(
                touch:
                    touch,
                screenPoints:
                    18
            )


        // =========================================
        // 1. Game Node
        // =========================================

        if let nodeID =
            gameNodeHitTester
                .hitTest(
                    at:
                        point,
                    nodes:
                        gameNodes,
                    roadGraph:
                        roadGraph,
                    tolerance:
                        tolerance
                )
        {

            emit(
                .gameNodeTapped(
                    nodeID:
                        nodeID,
                    worldPoint:
                        worldPoint,
                    mapCoordinate:
                        mapCoordinate
                )
            )


            return
        }
        
        // =====================================================
        // 2. ROUTE
        // =====================================================

        if let routeTarget =
            routeHitTester.hitTest(
                at:
                    point,
                state:
                    currentRouteRenderState,
                graph:
                    roadGraph,
                tolerance:
                    tolerance
            )
        {

            emit(
                .routeTapped(
                    target:
                        routeTarget,
                    worldPoint:
                        worldPoint,
                    mapCoordinate:
                        mapCoordinate
                )
            )


            return
        }


        // =========================================
        // 2. Road Geometry
        // =========================================

        let roadHit =
            roadHitTester
                .hitTest(
                    at:
                        point,
                    graph:
                        roadGraph,
                    tolerance:
                        tolerance
                )


        switch roadHit {

        case let .vertex(
            id: vertexID,
            worldPoint: resolvedWorldPoint,
            mapCoordinate: resolvedMapCoordinate
        ):

            emit(
                .roadVertexTapped(
                    vertexID:
                        vertexID,
                    worldPoint:
                        resolvedWorldPoint,
                    mapCoordinate:
                        resolvedMapCoordinate
                )
            )


        case let .edge(
            id: edgeID,
            worldPoint: resolvedWorldPoint,
            mapCoordinate: resolvedMapCoordinate
        ):

            emit(
                .roadEdgeTapped(
                    edgeID:
                        edgeID,
                    worldPoint:
                        resolvedWorldPoint,
                    mapCoordinate:
                        resolvedMapCoordinate
                )
            )


        case nil:

            emit(
                .backgroundTapped(
                    worldPoint:
                        worldPoint,
                    mapCoordinate:
                        mapCoordinate
                )
            )
        }
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

