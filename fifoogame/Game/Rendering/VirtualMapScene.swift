//
//  VirtualMapScene.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/18/26.
//

import SpriteKit


@MainActor
final class VirtualMapScene: SKScene {

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


    private let roadRenderer =
        RoadLayerRenderer()


    private let roadSelectionRenderer =
        RoadSelectionRenderer()


    private let currentTimeRenderer =
        CurrentTimeRenderer()


    private let gameNodeRenderer =
        GameNodeRenderer()


    // =====================================================
    // MARK: - Hit Testing
    // =====================================================

    private let roadHitTester =
        RoadHitTester()


    private let gameNodeHitTester =
        GameNodeHitTester()


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
            DenseCityRoadGraph.make()


        self.gameNodes =
            SampleGameNodes.make()


        super.init(
            coder:
                aDecoder
        )


        commonInit()
    }

    
}


// =====================================================
// MARK: - Initial Configuration
// =====================================================

private extension VirtualMapScene {

    func commonInit() {

        // MARK: Coordinate System

        /*
         Fifoo world:

         top-left:
             (0, 0)

         bottom:
             y = -2400
         */

        anchorPoint =
            CGPoint(
                x: 0,
                y: 1
            )


        scaleMode =
            .aspectFit


        backgroundColor =
            MapVisualTheme
                .landColor


        /*
         Build all scene content immediately.

         None of these operations require SKView.
         */

        configureLayers()

        configureCoordinateGrid()

        configureRoadNetwork()

        configureGameNodes()

        configureCurrentTimeIndicator()

        configureDiagnostics()
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


        cameraController.install(
            in:
                self,
            view:
                view,
            initialFocusTime:
                currentTime
        )
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

        backgroundLayer.zPosition =
            0

        gridLayer.zPosition =
            25

        roadLayer.zPosition =
            100

        routeLayer.zPosition =
            200

        nodeLayer.zPosition =
            300

        timeIndicatorLayer.zPosition =
            350

        selectionLayer.zPosition =
            400

        debugLayer.zPosition =
            1000


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


        roadLayer.addChild(
            roadRenderer
                .containerNode
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
// MARK: - Coordinate Grid
// =====================================================

private extension VirtualMapScene {

    func configureCoordinateGrid() {

        gridRenderer.rebuild()
    }
}


// =====================================================
// MARK: - Road Network
// =====================================================

private extension VirtualMapScene {

    func configureRoadNetwork() {

        roadRenderer.render(
            graph:
                roadGraph
        )
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

        currentSelection =
            selection


        // MARK: Roads

        roadSelectionRenderer
            .render(
                selection:
                    selection,
                graph:
                    roadGraph,
                roadRenderer:
                    roadRenderer
            )


        // MARK: Game Nodes

        gameNodeRenderer
            .renderSelection(
                selectedNodeID:
                    selection
                        .selectedNodeID
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
            vertexID
        ):

            emit(
                .roadVertexTapped(
                    vertexID:
                        vertexID,
                    worldPoint:
                        worldPoint,
                    mapCoordinate:
                        mapCoordinate
                )
            )


        case let .edge(
            edgeID
        ):

            emit(
                .roadEdgeTapped(
                    edgeID:
                        edgeID,
                    worldPoint:
                        worldPoint,
                    mapCoordinate:
                        mapCoordinate
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

