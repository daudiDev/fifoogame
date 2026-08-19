//
//  RoadLayerRenderer.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/18/26.
//

import SpriteKit


@MainActor
final class RoadLayerRenderer {

    // MARK: - Root

    let containerNode = SKNode()


    // MARK: - Layers

    private let casingLayer = SKNode()
    private let junctionCasingLayer = SKNode()

    private let surfaceLayer = SKNode()
    private let junctionSurfaceLayer = SKNode()

    private let roundaboutLayer = SKNode()
    private let specialFeatureLayer = SKNode()


    // MARK: - Rendered Lookup

    private var renderedNodes:
        [RoadEdgeID: RenderedRoadEdgeNodes] = [:]

    private(set) var renderedEdgeIDs:
        Set<RoadEdgeID> = []


    // MARK: - Validation

    private(set) var lastValidationResult:
        RoadGraphValidationResult?


    // MARK: - Init

    init() {

        configureLayers()
    }


    private func configureLayers() {

        containerNode.name = "roadRenderer"

        casingLayer.name = "roadCasingLayer"
        junctionCasingLayer.name = "junctionCasingLayer"

        surfaceLayer.name = "roadSurfaceLayer"
        junctionSurfaceLayer.name = "junctionSurfaceLayer"

        roundaboutLayer.name = "roundaboutLayer"
        specialFeatureLayer.name = "specialFeatureLayer"


        casingLayer.zPosition = 0

        junctionCasingLayer.zPosition = 5

        surfaceLayer.zPosition = 10

        junctionSurfaceLayer.zPosition = 15

        roundaboutLayer.zPosition = 20

        specialFeatureLayer.zPosition = 30


        containerNode.addChild(casingLayer)
        containerNode.addChild(junctionCasingLayer)

        containerNode.addChild(surfaceLayer)
        containerNode.addChild(junctionSurfaceLayer)

        containerNode.addChild(roundaboutLayer)
        containerNode.addChild(specialFeatureLayer)
    }
}


// =====================================================
// MARK: - Render
// =====================================================

extension RoadLayerRenderer {

    func render(
        graph: RoadGraph
    ) {

        clear()


        let validation =
            RoadGraphValidator.validate(graph)


        lastValidationResult =
            validation


        guard validation.isValid else {
            return
        }


        let verticesByID =
            Dictionary(
                uniqueKeysWithValues:
                    graph.vertices.map {
                        ($0.id, $0)
                    }
            )


        let roundabouts =
            resolveRoundabouts(
                graph: graph,
                verticesByID: verticesByID
            )


        // MARK: Roads

        for edge in graph.edges {

            guard
                let fromVertex = verticesByID[edge.fromID],
                let toVertex = verticesByID[edge.toID]
            else {
                continue
            }


            let path =
                makePath(
                    for: edge,
                    from: fromVertex,
                    to: toVertex,
                    roundabouts: roundabouts
                )


            let style =
                visualStyle(for: edge)


            let casing =
                makeCasingNode(
                    edge: edge,
                    path: path,
                    style: style
                )


            let surface =
                makeSurfaceNode(
                    edge: edge,
                    path: path,
                    style: style
                )


            /*
             Circle edges remain real domain edges,
             but their visible rendering is replaced
             by one continuous roundabout ring.

             We still retain these nodes for later
             edge lookup / hit-testing work.
             */

            if edge.roadClass != .circle {

                casingLayer.addChild(
                    casing
                )

                surfaceLayer.addChild(
                    surface
                )
            }


            renderedNodes[edge.id] =
                RenderedRoadEdgeNodes(
                    casing: casing,
                    surface: surface
                )


            renderedEdgeIDs.insert(
                edge.id
            )
        }


        // MARK: Unified Junctions

        renderIntersections(
            graph: graph,
            verticesByID: verticesByID
        )


        // MARK: Cul-de-sacs

        renderCulDeSacBulbs(
            graph: graph
        )


        // MARK: Unified Roundabouts

        renderRoundabouts(
            graph: graph,
            roundabouts: roundabouts
        )
    }


    func clear() {

        casingLayer.removeAllChildren()

        junctionCasingLayer
            .removeAllChildren()

        surfaceLayer.removeAllChildren()

        junctionSurfaceLayer
            .removeAllChildren()

        roundaboutLayer
            .removeAllChildren()

        specialFeatureLayer
            .removeAllChildren()


        renderedNodes.removeAll()

        renderedEdgeIDs.removeAll()

        lastValidationResult = nil
    }
}


// =====================================================
// MARK: - Lookup
// =====================================================

extension RoadLayerRenderer {

    func surfaceNode(
        for edgeID: RoadEdgeID
    ) -> SKShapeNode? {

        renderedNodes[edgeID]?
            .surface
    }


    func casingNode(
        for edgeID: RoadEdgeID
    ) -> SKShapeNode? {

        renderedNodes[edgeID]?
            .casing
    }
}


// =====================================================
// MARK: - Road Paths
// =====================================================

private extension RoadLayerRenderer {

    func makePath(
        for edge: RoadEdge,
        from fromVertex: RoadVertex,
        to toVertex: RoadVertex,
        roundabouts: [RoundaboutGeometry]
    ) -> CGPath {

        let start =
            fromVertex.worldPoint.cgPoint

        let end =
            toVertex.worldPoint.cgPoint


        // Roundabout domain edge -> visual arc

        if
            edge.roadClass == .circle,
            let roundabout =
                roundabouts.first(
                    where: {
                        $0.edgeIDs.contains(edge.id)
                    }
                )
        {

            return makeRoundaboutArcPath(
                start: start,
                end: end,
                geometry: roundabout
            )
        }


        let path =
            CGMutablePath()


        path.move(
            to: start
        )


        switch edge.shape {

        case .straight:

            path.addLine(
                to: end
            )


        case let .polyline(
            intermediatePoints
        ):

            for point in intermediatePoints {

                path.addLine(
                    to: point.cgPoint
                )
            }

            path.addLine(
                to: end
            )


        case let .cubicBezier(
            control1,
            control2
        ):

            path.addCurve(
                to: end,
                control1: control1.cgPoint,
                control2: control2.cgPoint
            )
        }


        return path
    }
}


// =====================================================
// MARK: - Road Nodes
// =====================================================

private extension RoadLayerRenderer {

    func makeCasingNode(
        edge: RoadEdge,
        path: CGPath,
        style: RoadVisualStyle
    ) -> SKShapeNode {

        let node =
            SKShapeNode(
                path: path
            )


        node.name =
            nodeName(
                edgeID: edge.id,
                component: "border"
            )


        node.strokeColor =
            style.borderColor


        node.lineWidth =
            style.casingWidth


        node.lineCap = .round

        node.lineJoin = .round

        node.fillColor = .clear

        node.alpha =
            edgeAlpha(for: edge)


        attachRoadMetadata(
            edge: edge,
            to: node
        )


        return node
    }


    func makeSurfaceNode(
        edge: RoadEdge,
        path: CGPath,
        style: RoadVisualStyle
    ) -> SKShapeNode {

        let node =
            SKShapeNode(
                path: path
            )


        node.name =
            nodeName(
                edgeID: edge.id,
                component: "surface"
            )


        node.strokeColor =
            style.surfaceColor


        node.lineWidth =
            style.surfaceWidth


        node.lineCap = .round

        node.lineJoin = .round

        node.fillColor = .clear

        node.alpha =
            edgeAlpha(for: edge)


        attachRoadMetadata(
            edge: edge,
            to: node
        )


        return node
    }
}


// =====================================================
// MARK: - Unified Intersections
// =====================================================

private extension RoadLayerRenderer {

    func renderIntersections(
        graph: RoadGraph,
        verticesByID:
            [RoadVertexID: RoadVertex]
    ) {

        for vertex in graph.vertices {

            let incidentEdges =
                graph.incidentEdges(
                    to: vertex.id,
                    traversableOnly: true
                )


            // The roundabout renderer owns these.
            if incidentEdges.contains(
                where: {
                    $0.roadClass == .circle
                }
            ) {

                continue
            }


            let shouldRender =
                incidentEdges.count >= 3
                ||
                (
                    vertex.kind == .intersection
                    &&
                    incidentEdges.count >= 2
                )


            guard shouldRender else {
                continue
            }


            // MARK: Outer border

            if let casingPath =
                intersectionPatchPath(
                    vertex: vertex,
                    incidentEdges: incidentEdges,
                    verticesByID: verticesByID,
                    component: .casing
                )
            {

                let casing =
                    SKShapeNode(
                        path: casingPath
                    )


                casing.name =
                    """
                    road.vertex.\
                    \(vertex.id.rawValue).\
                    intersection.border
                    """


                casing.fillColor =
                    MapVisualTheme
                        .roadBorderColor


                casing.strokeColor =
                    .clear


                attachVertexMetadata(
                    vertex: vertex,
                    to: casing
                )


                junctionCasingLayer
                    .addChild(
                        casing
                    )
            }


            // MARK: Road surface

            if let surfacePath =
                intersectionPatchPath(
                    vertex: vertex,
                    incidentEdges: incidentEdges,
                    verticesByID: verticesByID,
                    component: .surface
                )
            {

                let surface =
                    SKShapeNode(
                        path: surfacePath
                    )


                surface.name =
                    """
                    road.vertex.\
                    \(vertex.id.rawValue).\
                    intersection.surface
                    """


                surface.fillColor =
                    MapVisualTheme
                        .roadSurfaceColor


                surface.strokeColor =
                    .clear


                attachVertexMetadata(
                    vertex: vertex,
                    to: surface
                )


                junctionSurfaceLayer
                    .addChild(
                        surface
                    )
            }
        }
    }
}

// =====================================================
// MARK: - Intersection Patch Geometry
// =====================================================

private extension RoadLayerRenderer {

    enum IntersectionComponent {

        case casing

        case surface
    }


    func intersectionPatchPath(
        vertex: RoadVertex,
        incidentEdges: [RoadEdge],
        verticesByID:
            [RoadVertexID: RoadVertex],
        component: IntersectionComponent
    ) -> CGPath? {

        let center =
            vertex.worldPoint.cgPoint


        var shoulderPoints:
            [CGPoint] = []


        for edge in incidentEdges {

            guard
                let direction =
                    direction(
                        from: vertex,
                        along: edge,
                        verticesByID:
                            verticesByID
                    )
            else {

                continue
            }


            let style =
                visualStyle(
                    for: edge
                )


            let width: CGFloat


            switch component {

            case .casing:

                width =
                    style.casingWidth


            case .surface:

                width =
                    style.surfaceWidth
            }


            let halfWidth =
                width / 2


            /*
             Extend the intersection patch slightly
             into each road. This hides individual
             line caps and creates one continuous
             paved region.
             */

            let reach =
                max(
                    width * 0.95,
                    18
                )


            let perpendicular =
                CGPoint(
                    x:
                        -direction.y,
                    y:
                        direction.x
                )


            let mouthCenter =
                CGPoint(
                    x:
                        center.x
                        +
                        direction.x * reach,

                    y:
                        center.y
                        +
                        direction.y * reach
                )


            shoulderPoints.append(

                CGPoint(
                    x:
                        mouthCenter.x
                        +
                        perpendicular.x
                        * halfWidth,

                    y:
                        mouthCenter.y
                        +
                        perpendicular.y
                        * halfWidth
                )
            )


            shoulderPoints.append(

                CGPoint(
                    x:
                        mouthCenter.x
                        -
                        perpendicular.x
                        * halfWidth,

                    y:
                        mouthCenter.y
                        -
                        perpendicular.y
                        * halfWidth
                )
            )
        }


        let hull =
            convexHull(
                shoulderPoints
            )


        guard hull.count >= 3 else {
            return nil
        }


        return roundedPolygonPath(
            points: hull,
            cornerRadius:
                component == .casing
                ? 10
                : 8
        )
    }
}

// =====================================================
// MARK: - Road Endpoint Direction
// =====================================================

private extension RoadLayerRenderer {

    func direction(
        from vertex: RoadVertex,
        along edge: RoadEdge,
        verticesByID:
            [RoadVertexID: RoadVertex]
    ) -> CGPoint? {

        let origin =
            vertex.worldPoint.cgPoint


        let target:
            CGPoint?


        if edge.fromID == vertex.id {

            switch edge.shape {

            case .straight:

                target =
                    verticesByID[
                        edge.toID
                    ]?
                    .worldPoint
                    .cgPoint


            case let .polyline(
                intermediatePoints
            ):

                target =
                    intermediatePoints
                        .first?
                        .cgPoint
                    ??
                    verticesByID[
                        edge.toID
                    ]?
                    .worldPoint
                    .cgPoint


            case let .cubicBezier(
                control1,
                _
            ):

                target =
                    control1.cgPoint
            }

        } else if
            edge.toID == vertex.id
        {

            switch edge.shape {

            case .straight:

                target =
                    verticesByID[
                        edge.fromID
                    ]?
                    .worldPoint
                    .cgPoint


            case let .polyline(
                intermediatePoints
            ):

                target =
                    intermediatePoints
                        .last?
                        .cgPoint
                    ??
                    verticesByID[
                        edge.fromID
                    ]?
                    .worldPoint
                    .cgPoint


            case let .cubicBezier(
                _,
                control2
            ):

                target =
                    control2.cgPoint
            }

        } else {

            target = nil
        }


        guard let target else {
            return nil
        }


        return normalized(
            CGPoint(
                x:
                    target.x - origin.x,
                y:
                    target.y - origin.y
            )
        )
    }


    func normalized(
        _ vector: CGPoint
    ) -> CGPoint? {

        let length =
            hypot(
                vector.x,
                vector.y
            )


        guard length > 0.001 else {
            return nil
        }


        return CGPoint(
            x:
                vector.x / length,
            y:
                vector.y / length
        )
    }
}

// =====================================================
// MARK: - Intersection Polygon Helpers
// =====================================================

private extension RoadLayerRenderer {

    func convexHull(
        _ points: [CGPoint]
    ) -> [CGPoint] {

        guard points.count > 2 else {
            return points
        }


        let sorted =
            points.sorted {

                if $0.x == $1.x {
                    return $0.y < $1.y
                }

                return $0.x < $1.x
            }


        var lower:
            [CGPoint] = []


        for point in sorted {

            while
                lower.count >= 2,
                cross(
                    lower[
                        lower.count - 2
                    ],
                    lower[
                        lower.count - 1
                    ],
                    point
                ) <= 0
            {

                lower.removeLast()
            }


            lower.append(
                point
            )
        }


        var upper:
            [CGPoint] = []


        for point in sorted.reversed() {

            while
                upper.count >= 2,
                cross(
                    upper[
                        upper.count - 2
                    ],
                    upper[
                        upper.count - 1
                    ],
                    point
                ) <= 0
            {

                upper.removeLast()
            }


            upper.append(
                point
            )
        }


        lower.removeLast()

        upper.removeLast()


        return lower + upper
    }


    func cross(
        _ origin: CGPoint,
        _ a: CGPoint,
        _ b: CGPoint
    ) -> CGFloat {

        (
            a.x - origin.x
        )
        *
        (
            b.y - origin.y
        )
        -
        (
            a.y - origin.y
        )
        *
        (
            b.x - origin.x
        )
    }


    func roundedPolygonPath(
        points: [CGPoint],
        cornerRadius: CGFloat
    ) -> CGPath {

        let path =
            CGMutablePath()


        let count =
            points.count


        guard count >= 3 else {
            return path
        }


        for index in 0..<count {

            let previous =
                points[
                    (
                        index - 1 + count
                    )
                    % count
                ]


            let current =
                points[index]


            let next =
                points[
                    (
                        index + 1
                    )
                    % count
                ]


            let previousDistance =
                hypot(
                    current.x - previous.x,
                    current.y - previous.y
                )


            let nextDistance =
                hypot(
                    next.x - current.x,
                    next.y - current.y
                )


            let previousAmount =
                min(
                    cornerRadius,
                    previousDistance * 0.25
                )


            let nextAmount =
                min(
                    cornerRadius,
                    nextDistance * 0.25
                )


            let previousDirection =
                CGPoint(
                    x:
                        (
                            previous.x - current.x
                        )
                        / max(
                            previousDistance,
                            0.001
                        ),

                    y:
                        (
                            previous.y - current.y
                        )
                        / max(
                            previousDistance,
                            0.001
                        )
                )


            let nextDirection =
                CGPoint(
                    x:
                        (
                            next.x - current.x
                        )
                        / max(
                            nextDistance,
                            0.001
                        ),

                    y:
                        (
                            next.y - current.y
                        )
                        / max(
                            nextDistance,
                            0.001
                        )
                )


            let start =
                CGPoint(
                    x:
                        current.x
                        +
                        previousDirection.x
                        * previousAmount,

                    y:
                        current.y
                        +
                        previousDirection.y
                        * previousAmount
                )


            let end =
                CGPoint(
                    x:
                        current.x
                        +
                        nextDirection.x
                        * nextAmount,

                    y:
                        current.y
                        +
                        nextDirection.y
                        * nextAmount
                )


            if index == 0 {

                path.move(
                    to: start
                )

            } else {

                path.addLine(
                    to: start
                )
            }


            path.addQuadCurve(
                to: end,
                control: current
            )
        }


        path.closeSubpath()


        return path
    }
}


// =====================================================
// MARK: - Roundabouts
// =====================================================

private extension RoadLayerRenderer {

    func renderRoundabouts(
        graph: RoadGraph,
        roundabouts:
            [RoundaboutGeometry]
    ) {

        for (
            index,
            geometry
        ) in roundabouts.enumerated() {

            guard
                let sampleEdge =
                    graph.edges.first(
                        where: {
                            geometry.edgeIDs
                                .contains(
                                    $0.id
                                )
                        }
                    )
            else {

                continue
            }


            let style =
                visualStyle(
                    for: sampleEdge
                )


            let ringRect =
                CGRect(
                    x:
                        geometry.center.x
                        - geometry.radiusX,

                    y:
                        geometry.center.y
                        - geometry.radiusY,

                    width:
                        geometry.radiusX * 2,

                    height:
                        geometry.radiusY * 2
                )


            // MARK: Border

            let border =
                SKShapeNode(
                    ellipseIn: ringRect
                )


            border.name =
                "road.roundabout.\(index).border"


            border.fillColor = .clear

            border.strokeColor =
                style.borderColor

            border.lineWidth =
                style.casingWidth


            border.zPosition = 0


            roundaboutLayer.addChild(
                border
            )


            // MARK: Road

            let surface =
                SKShapeNode(
                    ellipseIn: ringRect
                )


            surface.name =
                "road.roundabout.\(index).surface"


            surface.fillColor = .clear

            surface.strokeColor =
                style.surfaceColor

            surface.lineWidth =
                style.surfaceWidth


            surface.zPosition = 1


            roundaboutLayer.addChild(
                surface
            )


            // MARK: Island

            let islandRadiusX =
                max(
                    8,
                    geometry.radiusX
                    -
                    style.surfaceWidth
                    * 0.68
                )


            let islandRadiusY =
                max(
                    8,
                    geometry.radiusY
                    -
                    style.surfaceWidth
                    * 0.68
                )


            let islandRect =
                CGRect(
                    x:
                        geometry.center.x
                        - islandRadiusX,

                    y:
                        geometry.center.y
                        - islandRadiusY,

                    width:
                        islandRadiusX * 2,

                    height:
                        islandRadiusY * 2
                )


            let island =
                SKShapeNode(
                    ellipseIn:
                        islandRect
                )


            island.name =
                "road.roundabout.\(index).island"


            island.fillColor =
                MapVisualTheme
                    .roundaboutIslandColor


            island.strokeColor =
                MapVisualTheme
                    .roundaboutIslandBorderColor


            island.lineWidth = 1.5

            island.zPosition = 2


            roundaboutLayer.addChild(
                island
            )
        }
    }
}

// =====================================================
// MARK: - Roundabout Resolution
// =====================================================

private extension RoadLayerRenderer {

    func resolveRoundabouts(
        graph: RoadGraph,
        verticesByID:
            [RoadVertexID: RoadVertex]
    ) -> [RoundaboutGeometry] {

        let circleEdges =
            graph.edges.filter {
                $0.roadClass == .circle
            }


        guard !circleEdges.isEmpty else {
            return []
        }


        let edgesByID =
            Dictionary(
                uniqueKeysWithValues:
                    circleEdges.map {
                        ($0.id, $0)
                    }
            )


        var edgesByVertex:
            [RoadVertexID: [RoadEdgeID]]
            = [:]


        for edge in circleEdges {

            edgesByVertex[
                edge.fromID,
                default: []
            ]
            .append(edge.id)


            edgesByVertex[
                edge.toID,
                default: []
            ]
            .append(edge.id)
        }


        var unvisited =
            Set(
                circleEdges.map(\.id)
            )


        var result:
            [RoundaboutGeometry] = []


        while let firstEdgeID =
            unvisited.first {

            var stack =
                [firstEdgeID]


            var edgeIDs =
                Set<RoadEdgeID>()


            var vertexIDs =
                Set<RoadVertexID>()


            while let edgeID =
                stack.popLast() {

                guard
                    edgeIDs
                        .insert(edgeID)
                        .inserted,
                    let edge =
                        edgesByID[edgeID]
                else {

                    continue
                }


                unvisited.remove(
                    edgeID
                )


                vertexIDs.insert(
                    edge.fromID
                )

                vertexIDs.insert(
                    edge.toID
                )


                for vertexID in [
                    edge.fromID,
                    edge.toID
                ] {

                    for neighbor in
                        edgesByVertex[
                            vertexID,
                            default: []
                        ] {

                        if !edgeIDs
                            .contains(
                                neighbor
                            )
                        {

                            stack.append(
                                neighbor
                            )
                        }
                    }
                }
            }


            let points =
                vertexIDs.compactMap {

                    verticesByID[$0]?
                        .worldPoint
                        .cgPoint
                }


            guard points.count >= 3 else {
                continue
            }


            let center =
                averagePoint(
                    points
                )


            let radiusX =
                points.map {
                    abs(
                        $0.x - center.x
                    )
                }
                .max()
                ?? 1


            let radiusY =
                points.map {
                    abs(
                        $0.y - center.y
                    )
                }
                .max()
                ?? 1


            result.append(

                RoundaboutGeometry(
                    vertexIDs:
                        vertexIDs,
                    edgeIDs:
                        edgeIDs,
                    center:
                        center,
                    radiusX:
                        radiusX,
                    radiusY:
                        radiusY
                )
            )
        }


        return result
    }


    func averagePoint(
        _ points: [CGPoint]
    ) -> CGPoint {

        guard !points.isEmpty else {
            return .zero
        }


        var x: CGFloat = 0
        var y: CGFloat = 0


        for point in points {

            x += point.x
            y += point.y
        }


        let count =
            CGFloat(points.count)


        return CGPoint(
            x: x / count,
            y: y / count
        )
    }
}

// =====================================================
// MARK: - Roundabout Edge Arc
// =====================================================

private extension RoadLayerRenderer {

    func makeRoundaboutArcPath(
        start: CGPoint,
        end: CGPoint,
        geometry:
            RoundaboutGeometry
    ) -> CGPath {

        let path =
            CGMutablePath()


        path.move(
            to: start
        )


        let radiusX =
            max(
                geometry.radiusX,
                1
            )


        let radiusY =
            max(
                geometry.radiusY,
                1
            )


        let startAngle =
            atan2(
                Double(
                    (
                        start.y
                        - geometry.center.y
                    )
                    / radiusY
                ),
                Double(
                    (
                        start.x
                        - geometry.center.x
                    )
                    / radiusX
                )
            )


        let endAngle =
            atan2(
                Double(
                    (
                        end.y
                        - geometry.center.y
                    )
                    / radiusY
                ),
                Double(
                    (
                        end.x
                        - geometry.center.x
                    )
                    / radiusX
                )
            )


        var delta =
            endAngle - startAngle


        while delta > Double.pi {

            delta -=
                2 * Double.pi
        }


        while delta < -Double.pi {

            delta +=
                2 * Double.pi
        }


        let k =
            CGFloat(
                (4.0 / 3.0)
                *
                tan(
                    delta / 4.0
                )
            )


        let startDerivative =
            CGPoint(
                x:
                    -radiusX
                    *
                    CGFloat(
                        sin(
                            startAngle
                        )
                    ),

                y:
                    radiusY
                    *
                    CGFloat(
                        cos(
                            startAngle
                        )
                    )
            )


        let endDerivative =
            CGPoint(
                x:
                    -radiusX
                    *
                    CGFloat(
                        sin(
                            endAngle
                        )
                    ),

                y:
                    radiusY
                    *
                    CGFloat(
                        cos(
                            endAngle
                        )
                    )
            )


        let control1 =
            CGPoint(
                x:
                    start.x
                    +
                    startDerivative.x * k,

                y:
                    start.y
                    +
                    startDerivative.y * k
            )


        let control2 =
            CGPoint(
                x:
                    end.x
                    -
                    endDerivative.x * k,

                y:
                    end.y
                    -
                    endDerivative.y * k
            )


        path.addCurve(
            to: end,
            control1: control1,
            control2: control2
        )


        return path
    }
}

// =====================================================
// MARK: - Cul-de-sacs
// =====================================================

private extension RoadLayerRenderer {

    func renderCulDeSacBulbs(
        graph: RoadGraph
    ) {

        for vertex in graph.vertices
        where vertex.kind == .culDeSacEnd {

            guard
                let edge =
                    graph.incidentEdges(
                        to: vertex.id,
                        traversableOnly: true
                    )
                    .first
            else {

                continue
            }


            let style =
                visualStyle(
                    for: edge
                )


            let point =
                vertex.worldPoint.cgPoint


            let border =
                SKShapeNode(
                    circleOfRadius:
                        style.casingWidth
                        * 0.72
                )


            border.position =
                point


            border.fillColor =
                style.borderColor


            border.strokeColor =
                .clear


            junctionCasingLayer
                .addChild(border)


            let surface =
                SKShapeNode(
                    circleOfRadius:
                        style.surfaceWidth
                        * 0.72
                )


            surface.position =
                point


            surface.fillColor =
                style.surfaceColor


            surface.strokeColor =
                .clear


            junctionSurfaceLayer
                .addChild(surface)
        }
    }
}

// =====================================================
// MARK: - Visual Styles
// =====================================================

private extension RoadLayerRenderer {

    func visualStyle(
        for edge: RoadEdge
    ) -> RoadVisualStyle {

        switch edge.roadClass {

        case .local:

            return RoadVisualStyle(
                casingWidth: 15,
                surfaceWidth: 13,
                borderColor:
                    MapVisualTheme.roadBorderColor,
                surfaceColor:
                    MapVisualTheme.roadSurfaceColor
            )


        case .connector:

            return RoadVisualStyle(
                casingWidth: 18,
                surfaceWidth: 14,
                borderColor:
                    MapVisualTheme.roadBorderColor,
                surfaceColor:
                    MapVisualTheme.roadSurfaceColor
            )


        case .culDeSac:

            return RoadVisualStyle(
                casingWidth: 16,
                surfaceWidth: 13,
                borderColor:
                    MapVisualTheme.roadBorderColor,
                surfaceColor:
                    MapVisualTheme.roadSurfaceColor
            )


        case .arterial:

            return RoadVisualStyle(
                casingWidth: 23,
                surfaceWidth: 20,
                borderColor:
                    MapVisualTheme.roadBorderColor,
                surfaceColor:
                    MapVisualTheme.roadSurfaceColor
            )


        case .circle:

            return RoadVisualStyle(
                casingWidth: 24,
                surfaceWidth: 20,
                borderColor:
                    MapVisualTheme.roadBorderColor,
                surfaceColor:
                    MapVisualTheme.roadSurfaceColor
            )


        case .highway:

            return RoadVisualStyle(
                casingWidth: 33,
                surfaceWidth: 28,
                borderColor:
                    MapVisualTheme.roadBorderColor,
                surfaceColor:
                    MapVisualTheme.highwaySurfaceColor
            )
        }
    }


    func edgeAlpha(
        for edge: RoadEdge
    ) -> CGFloat {

        guard
            edge.attributes.isTraversable,
            edge.travelDirection != .closed
        else {

            return 0.30
        }

        return 1
    }
}

// =====================================================
// MARK: - Metadata
// =====================================================

private extension RoadLayerRenderer {

    func nodeName(
        edgeID: RoadEdgeID,
        component: String
    ) -> String {

        "road.edge.\(edgeID.rawValue).\(component)"
    }


    func attachRoadMetadata(
        edge: RoadEdge,
        to node: SKNode
    ) {

        node.userData =
            NSMutableDictionary(
                dictionary: [
                    "roadEdgeID":
                        edge.id.rawValue,

                    "roadClass":
                        edge.roadClass.rawValue
                ]
            )
    }


    func attachVertexMetadata(
        vertex: RoadVertex,
        to node: SKNode
    ) {

        node.userData =
            NSMutableDictionary(
                dictionary: [
                    "roadVertexID":
                        vertex.id.rawValue,

                    "roadVertexKind":
                        vertex.kind.rawValue
                ]
            )
    }
}


// =====================================================
// MARK: - Types
// =====================================================

private struct RenderedRoadEdgeNodes {

    let casing: SKShapeNode

    let surface: SKShapeNode
}


private struct RoadVisualStyle {

    let casingWidth: CGFloat

    let surfaceWidth: CGFloat

    let borderColor: SKColor

    let surfaceColor: SKColor
}


private struct RoundaboutGeometry {

    let vertexIDs:
        Set<RoadVertexID>

    let edgeIDs:
        Set<RoadEdgeID>

    let center: CGPoint

    let radiusX: CGFloat

    let radiusY: CGFloat
}
