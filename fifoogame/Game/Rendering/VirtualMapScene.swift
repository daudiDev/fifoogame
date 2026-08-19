//
//  VirtualMapScene.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/18/26.
//


//
//  VirtualMapScene.swift
//  Fifoo
//

import SpriteKit


@MainActor
final class VirtualMapScene:
    SKScene {

    // MARK: - Interaction

    weak var interactionDelegate:
        SceneInteractionDelegate?


    // MARK: - Domain Input

    private let roadGraph:
        RoadGraph


    // MARK: - Layers

    private let backgroundLayer =
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


    // MARK: - Renderers
    
    private let roadHitTester =
        RoadHitTester()


    private let roadSelectionRenderer =
        RoadSelectionRenderer()

    private let gridRenderer =
        MapGridRenderer()


    private let roadRenderer =
        RoadLayerRenderer()


    private let currentTimeRenderer =
        CurrentTimeRenderer()


    // MARK: - Camera

    private let cameraController =
        MapCameraController()


    // MARK: - Time

    private var currentTime:
        DayTime


    // MARK: - Scene State

    private var hasConfiguredScene =
        false


    // MARK: - Tap State

    private var touchBeganWhileMomentumWasActive =
        false


    private var gestureContainsMultipleTouches =
        false


    // MARK: - Init

    init(
        initialTime:
            DayTime,
        roadGraph:
            RoadGraph
    ) {

        self.currentTime =
            initialTime


        self.roadGraph =
            roadGraph


        super.init(
            size:
                MapWorldConfiguration.sceneSize
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
            SampleRoadGraph.make()


        super.init(
            coder:
                aDecoder
        )


        commonInit()
    }


    private func commonInit() {

        anchorPoint =
            CGPoint(
                x:
                    0,
                y:
                    1
            )


        scaleMode =
            .aspectFit

        backgroundColor =
            MapVisualTheme.landColor
        
    }


    // MARK: - Lifecycle

    override func didMove(
        to view:
            SKView
    ) {

        super.didMove(
            to:
                view
        )


        if !hasConfiguredScene {

            hasConfiguredScene =
                true


            configureLayers()


            configureCoordinateGrid()


            configureRoadNetwork()


            configureCurrentTimeIndicator()


            configureDiagnostics()
        }


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

        super.willMove(
            from:
                view
        )


        cameraController
            .detachGestures(
                from:
                    view
            )
    }


    // MARK: - SpriteKit Frame Update

    override func update(
        _ currentTime:
            TimeInterval
    ) {

        super.update(
            currentTime
        )


        cameraController
            .updateMomentum(
                currentTime:
                    currentTime
            )
    }


    // MARK: - Time API

    func renderCurrentTime(
        _ time:
            DayTime
    ) {

        currentTime =
            time


        guard
            hasConfiguredScene
        else {

            return
        }


        currentTimeRenderer
            .render(
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


    // MARK: - Layers

    private func configureLayers() {

        backgroundLayer.name =
            "backgroundLayer"


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


        backgroundLayer.zPosition =
            0


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


        addChild(
            backgroundLayer
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
        
        selectionLayer.addChild(
            roadSelectionRenderer
                .containerNode
        )


        addChild(
            debugLayer
        )
    }


    // MARK: - Coordinate Grid

    private func configureCoordinateGrid() {

        backgroundLayer.addChild(
            gridRenderer
                .containerNode
        )


        gridRenderer.rebuild()
    }


    // MARK: - Roads

    private func configureRoadNetwork() {

        roadLayer.addChild(
            roadRenderer
                .containerNode
        )


        roadRenderer.render(
            graph:
                roadGraph
        )
    }


    // MARK: - Current Time

    private func configureCurrentTimeIndicator() {

        timeIndicatorLayer.addChild(
            currentTimeRenderer
                .containerNode
        )


        currentTimeRenderer.render(
            time:
                currentTime
        )
    }


    // MARK: - Diagnostics

    private func configureDiagnostics() {

        drawWorldBoundary()


        drawCenterReferencePoint()
    }
    
    func renderRoadSelection(
        _ selection:
            SelectionState
    ) {

        guard hasConfiguredScene else {

            return
        }


        roadSelectionRenderer
            .render(
                selection:
                    selection,
                graph:
                    roadGraph,
                roadRenderer:
                    roadRenderer
            )
    }
}


// MARK: - World Diagnostics

private extension VirtualMapScene {

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
                    -MapWorldConfiguration.height,

                width:
                    MapWorldConfiguration
                        .explorableWorldWidth,

                height:
                    MapWorldConfiguration.height
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
                x:
                    0,

                y:
                    -MapWorldConfiguration.height,

                width:
                    MapWorldConfiguration.width,

                height:
                    MapWorldConfiguration.height
            )


        let boundary =
            SKShapeNode(
                rect:
                    rect
            )


        boundary.name =
            "referenceProgressBoundary"


        boundary.strokeColor =
            SKColor.white
                .withAlphaComponent(
                    0.25
                )


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

// MARK: - Touch Handling

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

                    $0.phase != .ended
                    &&
                    $0.phase != .cancelled
                }
                .count
            ?? touches.count


        gestureContainsMultipleTouches =
            activeCount > 1


        touchBeganWhileMomentumWasActive =
            cameraController
                .isMomentumActive


        /*
         Touching a coasting map grabs it
         immediately.
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

            touchBeganWhileMomentumWasActive =
                false


            gestureContainsMultipleTouches =
                false
        }


        guard
            !touchBeganWhileMomentumWasActive
        else {

            return
        }


        guard
            !gestureContainsMultipleTouches,
            !cameraController.isPinching,
            !cameraController.isPanning
        else {

            return
        }


        guard
            let touch =
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


        touchBeganWhileMomentumWasActive =
            false


        gestureContainsMultipleTouches =
            false
    }
}


    // MARK: - Semantic Hit Testing

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
        
        
        let hit =
        roadHitTester
            .hitTest(
                at:
                    point,
                graph:
                    roadGraph,
                tolerance:
                    tolerance
            )
        
        
        switch hit {
            
            // =========================================
            // Intersection / Vertex
            // =========================================
            
        case let .vertex(
            vertexID
        ):
            
            interactionDelegate?
                .sceneDidEmit(
                    
                    .roadVertexTapped(
                        vertexID:
                            vertexID,
                        worldPoint:
                            worldPoint,
                        mapCoordinate:
                            mapCoordinate
                    )
                )
            
            
            // =========================================
            // Road
            // =========================================
            
        case let .edge(
            edgeID
        ):
            
            interactionDelegate?
                .sceneDidEmit(
                    
                    .roadEdgeTapped(
                        edgeID:
                            edgeID,
                        worldPoint:
                            worldPoint,
                        mapCoordinate:
                            mapCoordinate
                    )
                )
            
            
            // =========================================
            // Background
            // =========================================
            
        case nil:
            
            interactionDelegate?
                .sceneDidEmit(
                    
                    .backgroundTapped(
                        worldPoint:
                            worldPoint,
                        mapCoordinate:
                            mapCoordinate
                    )
                )
        }
    }
}

// MARK: - Screen -> World Hit Tolerance

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
