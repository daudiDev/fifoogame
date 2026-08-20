//
//  RouteLayerRenderer.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/19/26.
//

//

import SpriteKit
import CoreGraphics


@MainActor
final class RouteLayerRenderer {

    // =====================================================
    // MARK: - Layers
    // =====================================================

    private let container =
        SKNode()


    private let alternativeLayer =
        SKNode()


    private let chosenLayer =
        SKNode()


    private let completedLayer =
        SKNode()


    private let boundaryLayer =
        SKNode()
    
    private let previewLayer =
        SKNode()


    // =====================================================
    // MARK: - Configuration
    // =====================================================

    private let geometrySamples =
        96


    // =====================================================
    // MARK: - Attach
    // =====================================================

    func attach(
        to parent:
            SKNode
    ) {

        guard
            container.parent ==
                nil
        else {

            return
        }


        container.name =
            "routes.container"


        alternativeLayer.name =
            "routes.alternatives"

        chosenLayer.name =
            "routes.chosen"

        completedLayer.name =
            "routes.completed"

        boundaryLayer.name =
            "routes.boundary"
        
        previewLayer.name =
            "routes.preview"


        // =============================================
        // Internal route z-order
        // =============================================

        alternativeLayer.zPosition =
            0

        chosenLayer.zPosition =
            10

        completedLayer.zPosition =
            20

        boundaryLayer.zPosition =
            30
        
        previewLayer.zPosition =
            40


        container.addChild(
            alternativeLayer
        )

        container.addChild(
            chosenLayer
        )

        container.addChild(
            completedLayer
        )

        container.addChild(
            boundaryLayer
        )
        
        
        container.addChild(
            previewLayer
        )


        parent.addChild(
            container
        )
    }


    // =====================================================
    // MARK: - Clear
    // =====================================================

    func clearLiveRoutes() {

        alternativeLayer
            .removeAllChildren()


        chosenLayer
            .removeAllChildren()


        completedLayer
            .removeAllChildren()


        boundaryLayer
            .removeAllChildren()
    }


    func clearPreview() {

        previewLayer
            .removeAllChildren()
    }


    func clearAll() {

        clearLiveRoutes()

        clearPreview()
    }


    // =====================================================
    // MARK: - Render
    // =====================================================

    func render(
        _ state:
            RouteRenderState,
        graph:
            RoadGraph,
        selectedRouteID:
            RouteID? = nil
    ) {

        
        clearLiveRoutes()

        renderAlternatives(
            state.alternatives,
            graph:
                graph,
            selectedRouteID:
                selectedRouteID
        )


        if let chosen =
            state.chosenFuture {

            renderChosen(
                chosen,
                graph:
                    graph,
                isSelected:
                    chosen.routeID ==
                    selectedRouteID
            )
        }


        renderCompleted(
            state.completedSegments,
            graph:
                graph
        )


        if let boundary =
            state.currentBoundary {

            renderBoundary(
                boundary,
                graph:
                    graph
            )
        }
    }
    
    func renderPreview(
        _ state:
            RoutePreviewRenderState,
        graph:
            RoadGraph
    ) {

        previewLayer
            .removeAllChildren()


        guard
            !state.isEmpty
        else {

            return
        }


        // =================================================
        // Draw unselected previews first.
        // =================================================

        for route in
            state.routes
        where
            !route.isSelected
        {

            renderPreviewRoute(
                route,
                graph:
                    graph
            )
        }


        // =================================================
        // Selected preview on top.
        // =================================================

        if let selected =
            state.routes.first(
                where: {

                    $0.isSelected
                }
            )
        {

            renderPreviewRoute(
                selected,
                graph:
                    graph
            )
        }
    }
    
    private func renderPreviewRoute(
        _ route:
            RoutePreviewRenderPath,
        graph:
            RoadGraph
    ) {

        let routeNode =
            SKNode()


        routeNode.name =
            "route.preview.\(route.routeID.rawValue.uuidString)"


        for segment in
            route.segments {

            if route.isSelected {

                // =========================================
                // Halo
                // =========================================

                if let halo =
                    routeShapeNode(
                        for:
                            segment,
                        graph:
                            graph,
                        color:
                            RouteVisualTheme
                                .previewSelectedHaloColor,
                        lineWidth:
                            RouteVisualTheme
                                .previewSelectedHaloWidth
                    )
                {

                    routeNode.addChild(
                        halo
                    )
                }


                // =========================================
                // Selected preview
                // =========================================

                if let shape =
                    routeShapeNode(
                        for:
                            segment,
                        graph:
                            graph,
                        color:
                            RouteVisualTheme
                                .previewSelectedColor,
                        lineWidth:
                            RouteVisualTheme
                                .previewSelectedWidth
                    )
                {

                    routeNode.addChild(
                        shape
                    )
                }

            } else {

                // =========================================
                // Alternative preview
                // =========================================

                if let shape =
                    routeShapeNode(
                        for:
                            segment,
                        graph:
                            graph,
                        color:
                            RouteVisualTheme
                                .previewAlternativeColor,
                        lineWidth:
                            RouteVisualTheme
                                .previewAlternativeWidth
                    )
                {

                    routeNode.addChild(
                        shape
                    )
                }
            }
        }


        previewLayer.addChild(
            routeNode
        )
    }
    
    
}


// =====================================================
// MARK: - Alternatives
// =====================================================

private extension RouteLayerRenderer {

    func renderAlternatives(
        _ routes:
            [RouteRenderPath],
        graph:
            RoadGraph,
        selectedRouteID:
            RouteID?
    ) {

        for (
            routeIndex,
            route
        ) in routes.enumerated() {

            let isSelected =
                route.routeID ==
                selectedRouteID


            let routeNode =
                SKNode()


            routeNode.name =
                "route.alternative.\(route.routeID.rawValue.uuidString)"


            routeNode.alpha =
                isSelected
                ? 1
                : max(
                    0.28,
                    1
                    -
                    CGFloat(routeIndex)
                    *
                    0.12
                )


            for segment in
                route.segments {

                // =========================================
                // Selected Halo
                // =========================================

                if
                    isSelected,
                    let halo =
                        routeShapeNode(
                            for:
                                segment,
                            graph:
                                graph,
                            color:
                                RouteVisualTheme
                                    .chosenHaloColor,
                            lineWidth:
                                RouteVisualTheme
                                    .chosenHaloWidth
                        )
                {

                    routeNode.addChild(
                        halo
                    )
                }


                // =========================================
                // Route
                // =========================================

                if let shape =
                    routeShapeNode(
                        for:
                            segment,
                        graph:
                            graph,
                        color:
                            isSelected
                            ? RouteVisualTheme
                                .chosenColor
                            : RouteVisualTheme
                                .alternativeColor,
                        lineWidth:
                            isSelected
                            ? RouteVisualTheme
                                .chosenWidth
                            : RouteVisualTheme
                                .alternativeWidth
                    )
                {

                    routeNode.addChild(
                        shape
                    )
                }
            }


            alternativeLayer.addChild(
                routeNode
            )
        }
    }
}

// =====================================================
// MARK: - Chosen Future
// =====================================================

private extension RouteLayerRenderer {

        func renderChosen(
            _ route:
                RouteRenderPath,
            graph:
                RoadGraph,
            isSelected:
                Bool
        ) {

            let routeNode =
                SKNode()


            routeNode.name =
                "route.chosen.\(route.routeID.rawValue.uuidString)"


            for segment in
                route.segments {

                if let halo =
                    routeShapeNode(
                        for:
                            segment,
                        graph:
                            graph,
                        color:
                            RouteVisualTheme
                                .chosenHaloColor,
                        lineWidth:
                            isSelected
                            ? RouteVisualTheme
                                .chosenHaloWidth + 4
                            : RouteVisualTheme
                                .chosenHaloWidth
                    )
                {

                    routeNode.addChild(
                        halo
                    )
                }


                if let shape =
                    routeShapeNode(
                        for:
                            segment,
                        graph:
                            graph,
                        color:
                            RouteVisualTheme
                                .chosenColor,
                        lineWidth:
                            isSelected
                            ? RouteVisualTheme
                                .chosenWidth + 2
                            : RouteVisualTheme
                                .chosenWidth
                    )
                {

                    routeNode.addChild(
                        shape
                    )
                }
            }


            chosenLayer.addChild(
                routeNode
            )
        }
}

// =====================================================
// MARK: - Completed
// =====================================================

private extension RouteLayerRenderer {

    func renderCompleted(
        _ segments:
            [RoadRouteSegment],
        graph:
            RoadGraph
    ) {

        guard
            !segments.isEmpty
        else {

            return
        }


        let routeNode =
            SKNode()


        routeNode.name =
            "route.completed"


        for segment in
            segments {

            // =========================================
            // Halo
            // =========================================

            if let halo =
                routeShapeNode(
                    for:
                        segment,
                    graph:
                        graph,
                    color:
                        RouteVisualTheme
                            .completedHaloColor,
                    lineWidth:
                        RouteVisualTheme
                            .completedHaloWidth
                )
            {

                routeNode.addChild(
                    halo
                )
            }


            // =========================================
            // Main Route
            // =========================================

            if let shape =
                routeShapeNode(
                    for:
                        segment,
                    graph:
                        graph,
                    color:
                        RouteVisualTheme
                            .completedColor,
                    lineWidth:
                        RouteVisualTheme
                            .completedWidth
                )
            {

                routeNode.addChild(
                    shape
                )
            }
        }


        completedLayer.addChild(
            routeNode
        )
    }
}

// =====================================================
// MARK: - Route Geometry
// =====================================================

private extension RouteLayerRenderer {

    func routeShapeNode(
        for segment:
            RoadRouteSegment,
        graph:
            RoadGraph,
        color:
            SKColor,
        lineWidth:
            CGFloat
    ) -> SKShapeNode? {

        guard let path =
            routePath(
                for:
                    segment,
                graph:
                    graph
            )
        else {

            return nil
        }


        let shape =
            SKShapeNode(
                path:
                    path
            )


        shape.strokeColor =
            color


        shape.lineWidth =
            lineWidth


        shape.lineCap =
            .round


        shape.lineJoin =
            .round


        shape.isAntialiased =
            true


        shape.fillColor =
            .clear


        shape.name =
            "route.segment.\(segment.edgeID.rawValue)"


        return shape
    }
}

private extension RouteLayerRenderer {

    func routePath(
        for segment:
            RoadRouteSegment,
        graph:
            RoadGraph
    ) -> CGPath? {

        let points =
            RoadEdgeGeometry
                .sampledPoints(
                    along:
                        segment,
                    graph:
                        graph,
                    cubicSegments:
                        geometrySamples
                )


        guard let first =
            points.first,

            points.count >=
                2
        else {

            return nil
        }


        let path =
            CGMutablePath()


        path.move(
            to:
                first.cgPoint
        )


        for point in
            points.dropFirst() {

            path.addLine(
                to:
                    point.cgPoint
            )
        }


        return path
    }
}

// =====================================================
// MARK: - Current Boundary
// =====================================================

private extension RouteLayerRenderer {

    func renderBoundary(
        _ location:
            GameNodeRouteAnchor.RoadLocation,
        graph:
            RoadGraph
    ) {

        guard let point =
            worldPoint(
                for:
                    location,
                graph:
                    graph
            )
        else {

            return
        }


        let marker =
            SKShapeNode(
                circleOfRadius:
                    RouteVisualTheme
                        .boundaryRadius
            )


        marker.position =
            point.cgPoint


        marker.fillColor =
            RouteVisualTheme
                .boundaryFillColor


        marker.strokeColor =
            RouteVisualTheme
                .boundaryStrokeColor


        marker.lineWidth =
            3


        marker.name =
            "route.currentBoundary"


        boundaryLayer.addChild(
            marker
        )
    }
}

private extension RouteLayerRenderer {

    func worldPoint(
        for location:
            GameNodeRouteAnchor.RoadLocation,
        graph:
            RoadGraph
    ) -> WorldPoint? {

        switch location {

        // =============================================
        // Vertex
        // =============================================

        case let .vertex(
            vertexID
        ):

            return graph
                .vertex(
                    id:
                        vertexID
                )?
                .worldPoint


        // =============================================
        // Edge
        // =============================================

        case let .edge(
            edgeID,
            fraction
        ):

            guard let edge =
                graph.edge(
                    id:
                        edgeID
                )
            else {

                return nil
            }


            return RoadEdgeGeometry
                .point(
                    atFraction:
                        fraction,
                    on:
                        edge,
                    graph:
                        graph,
                    cubicSegments:
                        geometrySamples
                )
        }
    }
}
