//
//  RouteLayerRenderer.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/25/26.
//



import SpriteKit
import CoreGraphics
import UIKit


@MainActor
final class RouteLayerRenderer {

    // =====================================================
    // MARK: - Layers
    // =====================================================

    private let container = SKNode()
    private let alternativeLayer = SKNode()
    private let chosenLayer = SKNode()
    private let completedLayer = SKNode()
    private let boundaryLayer = SKNode()
    private let previewLayer = SKNode()


    // =====================================================
    // MARK: - Attach
    // =====================================================

    func attach(
        to parent: SKNode
    ) {

        guard container.parent == nil else {
            return
        }

        container.name = "routes.container"

        alternativeLayer.name = "routes.alternatives"
        chosenLayer.name = "routes.chosen"
        completedLayer.name = "routes.completed"
        boundaryLayer.name = "routes.boundary"
        previewLayer.name = "routes.preview"

        // Internal route z-order remains unchanged.
        alternativeLayer.zPosition = 0
        chosenLayer.zPosition = 10
        completedLayer.zPosition = 20
        boundaryLayer.zPosition = 30
        previewLayer.zPosition = 40

        container.addChild(alternativeLayer)
        container.addChild(chosenLayer)
        container.addChild(completedLayer)
        container.addChild(boundaryLayer)
        container.addChild(previewLayer)

        parent.addChild(container)
    }


    // =====================================================
    // MARK: - Clear
    // =====================================================

    func clearLiveRoutes() {

        alternativeLayer.removeAllChildren()
        chosenLayer.removeAllChildren()
        completedLayer.removeAllChildren()
        boundaryLayer.removeAllChildren()
    }


    func clearPreview() {

        previewLayer.removeAllChildren()
    }


    func clearAll() {

        clearLiveRoutes()
        clearPreview()
    }


    // =====================================================
    // MARK: - Live Render
    // =====================================================

    func render(
        _ state: RouteRenderState,
        graph: RoadGraph,
        selectedRouteID: RouteID? = nil,
        currentUserAvatarAssetName: String? = nil
    ) {

        clearLiveRoutes()

        renderAlternatives(
            state.alternatives,
            graph: graph,
            selectedRouteID: selectedRouteID
        )


        // =============================================
        // Primary route
        //
        // When Completed changes into Chosen exactly at
        // a turning intersection, split one quadratic
        // corner between the two state colors. This keeps
        // the state transition on one smooth centerline.
        // =============================================

        if let chosen = state.chosenFuture {

            let transition =
                RoutePathBuilder
                    .makeBoundaryTransitionPaths(
                        completedSegments: state.completedSegments,
                        chosenSegments: chosen.segments,
                        graph: graph
                    )

            renderChosen(
                chosen,
                graph: graph,
                isSelected: chosen.routeID == selectedRouteID,
                pathOverride: transition?.chosenPath
            )

            renderCompleted(
                state.completedSegments,
                graph: graph,
                pathOverride: transition?.completedPath
            )

        } else {

            renderCompleted(
                state.completedSegments,
                graph: graph
            )
        }


        if let boundary = state.currentBoundary {

            renderBoundary(
                boundary,
                graph: graph,
                currentUserAvatarAssetName:
                    currentUserAvatarAssetName
            )
        }
    }


    // =====================================================
    // MARK: - Preview Render
    // =====================================================

    func renderPreview(
        _ state: RoutePreviewRenderState,
        graph: RoadGraph
    ) {

        previewLayer.removeAllChildren()

        guard !state.isEmpty else {
            return
        }

        // Draw unselected previews first.
        for route in state.routes where !route.isSelected {

            renderPreviewRoute(
                route,
                graph: graph
            )
        }

        // Selected preview stays visually on top.
        if let selected = state.routes.first(where: { $0.isSelected }) {

            renderPreviewRoute(
                selected,
                graph: graph
            )
        }
    }
}


// =====================================================
// MARK: - Preview Routes
// =====================================================

private extension RouteLayerRenderer {

    func renderPreviewRoute(
        _ route: RoutePreviewRenderPath,
        graph: RoadGraph
    ) {

        guard let path =
            RoutePathBuilder.makePath(
                for: route.segments,
                graph: graph
            )
        else {
            return
        }

        let routeNode = SKNode()

        routeNode.name =
            "route.preview.\(route.routeID.rawValue.uuidString)"

        if route.isSelected {

            routeNode.addChild(
                routeShapeNode(
                    path: path,
                    color: RouteVisualTheme.previewSelectedHaloColor,
                    lineWidth: RouteVisualTheme.previewSelectedHaloWidth,
                    name: "route.preview.selected.halo"
                )
            )

            routeNode.addChild(
                routeShapeNode(
                    path: path,
                    color: RouteVisualTheme.previewSelectedColor,
                    lineWidth: RouteVisualTheme.previewSelectedWidth,
                    name: "route.preview.selected"
                )
            )

        } else {

            routeNode.addChild(
                routeShapeNode(
                    path: path,
                    color: RouteVisualTheme.previewAlternativeColor,
                    lineWidth: RouteVisualTheme.previewAlternativeWidth,
                    name: "route.preview.alternative"
                )
            )
        }

        previewLayer.addChild(routeNode)
    }
}


// =====================================================
// MARK: - Alternatives
// =====================================================

private extension RouteLayerRenderer {

    func renderAlternatives(
        _ routes: [RouteRenderPath],
        graph: RoadGraph,
        selectedRouteID: RouteID?
    ) {

        for (routeIndex, route) in routes.enumerated() {

            guard let path =
                RoutePathBuilder.makePath(
                    for: route.segments,
                    graph: graph
                )
            else {
                continue
            }

            let isSelected =
                route.routeID == selectedRouteID

            let routeNode = SKNode()

            routeNode.name =
                "route.alternative.\(route.routeID.rawValue.uuidString)"

            routeNode.alpha =
                isSelected
                ? 1
                : max(
                    0.28,
                    1 - CGFloat(routeIndex) * 0.12
                )

            if isSelected {

                routeNode.addChild(
                    routeShapeNode(
                        path: path,
                        color: RouteVisualTheme.chosenHaloColor,
                        lineWidth: RouteVisualTheme.chosenHaloWidth,
                        name: "route.alternative.selected.halo"
                    )
                )
            }

            routeNode.addChild(
                routeShapeNode(
                    path: path,
                    color:
                        isSelected
                        ? RouteVisualTheme.chosenColor
                        : RouteVisualTheme.alternativeColor,
                    lineWidth:
                        isSelected
                        ? RouteVisualTheme.chosenWidth
                        : RouteVisualTheme.alternativeWidth,
                    name: "route.alternative.path"
                )
            )

            alternativeLayer.addChild(routeNode)
        }
    }
}


// =====================================================
// MARK: - Chosen Future
// =====================================================

private extension RouteLayerRenderer {

    func renderChosen(
        _ route: RouteRenderPath,
        graph: RoadGraph,
        isSelected: Bool,
        pathOverride: CGPath? = nil
    ) {

        guard let path =
            pathOverride
            ?? RoutePathBuilder.makePath(
                for: route.segments,
                graph: graph
            )
        else {
            return
        }

        let routeNode = SKNode()

        routeNode.name =
            "route.chosen.\(route.routeID.rawValue.uuidString)"

        routeNode.addChild(
            routeShapeNode(
                path: path,
                color: RouteVisualTheme.chosenHaloColor,
                lineWidth:
                    isSelected
                    ? RouteVisualTheme.chosenHaloWidth + 4
                    : RouteVisualTheme.chosenHaloWidth,
                name: "route.chosen.halo"
            )
        )

        routeNode.addChild(
            routeShapeNode(
                path: path,
                color: RouteVisualTheme.chosenColor,
                lineWidth:
                    isSelected
                    ? RouteVisualTheme.chosenWidth + 2
                    : RouteVisualTheme.chosenWidth,
                name: "route.chosen.path"
            )
        )

        chosenLayer.addChild(routeNode)
    }
}


// =====================================================
// MARK: - Completed
// =====================================================

private extension RouteLayerRenderer {

    func renderCompleted(
        _ segments: [RoadRouteSegment],
        graph: RoadGraph,
        pathOverride: CGPath? = nil
    ) {

        guard !segments.isEmpty else {
            return
        }

        guard let path =
            pathOverride
            ?? RoutePathBuilder.makePath(
                for: segments,
                graph: graph
            )
        else {
            return
        }

        let routeNode = SKNode()
        routeNode.name = "route.completed"

        routeNode.addChild(
            routeShapeNode(
                path: path,
                color: RouteVisualTheme.completedHaloColor,
                lineWidth: RouteVisualTheme.completedHaloWidth,
                name: "route.completed.halo"
            )
        )

        routeNode.addChild(
            routeShapeNode(
                path: path,
                color: RouteVisualTheme.completedColor,
                lineWidth: RouteVisualTheme.completedWidth,
                name: "route.completed.path"
            )
        )

        completedLayer.addChild(routeNode)
    }
}


// =====================================================
// MARK: - Shared Shape Creation
// =====================================================

private extension RouteLayerRenderer {

    func routeShapeNode(
        path: CGPath,
        color: SKColor,
        lineWidth: CGFloat,
        name: String
    ) -> SKShapeNode {

        let shape = SKShapeNode(path: path)

        shape.strokeColor = color
        shape.lineWidth = lineWidth
        shape.lineCap = .round
        shape.lineJoin = .round
        shape.isAntialiased = true
        shape.fillColor = .clear
        shape.name = name

        return shape
    }
}


// =====================================================
// MARK: - Current Boundary
// =====================================================

private extension RouteLayerRenderer {

    func renderBoundary(
        _ location: GameNodeRouteAnchor.RoadLocation,
        graph: RoadGraph,
        currentUserAvatarAssetName: String?
    ) {

        guard let point =
            worldPoint(
                for: location,
                graph: graph
            )
        else {
            return
        }

        let root =
            SKNode()

        root.name =
            "route.currentUser"

        root.position =
            point.cgPoint

        // A small shadow/ring keeps the user's current route position legible
        // over either Completed or Chosen route colors.
        let shadow =
            SKShapeNode(
                circleOfRadius: 18
            )

        shadow.fillColor =
            UIColor.black.withAlphaComponent(0.18)

        shadow.strokeColor =
            .clear

        shadow.position =
            CGPoint(
                x: 0,
                y: -2
            )

        shadow.zPosition =
            0

        root.addChild(
            shadow
        )

        let ring =
            SKShapeNode(
                circleOfRadius: 17
            )

        ring.fillColor =
            .white

        ring.strokeColor =
            UIColor.black.withAlphaComponent(0.12)

        ring.lineWidth =
            1

        ring.zPosition =
            1

        root.addChild(
            ring
        )

        let avatarCrop =
            SKCropNode()

        let avatarMask =
            SKShapeNode(
                circleOfRadius: 14
            )

        avatarMask.fillColor =
            .white

        avatarMask.strokeColor =
            .clear

        avatarCrop.maskNode =
            avatarMask

        avatarCrop.zPosition =
            2

        let requestedName =
            currentUserAvatarAssetName
                ?? "placeholder"

        let avatarImage =
            UIImage(
                named: requestedName
            )
            ?? UIImage(
                named: "placeholder"
            )
            ?? UIImage(
                systemName:
                    "person.crop.circle.fill"
            )

        if let avatarImage {

            let avatarSprite =
                SKSpriteNode(
                    texture:
                        SKTexture(
                            image: avatarImage
                        )
                )

            avatarSprite.size =
                CGSize(
                    width: 50,
                    height: 50
                )

            avatarCrop.addChild(
                avatarSprite
            )
        }

        root.addChild(
            avatarCrop
        )

        boundaryLayer.addChild(
            root
        )
    }


    func worldPoint(
        for location: GameNodeRouteAnchor.RoadLocation,
        graph: RoadGraph
    ) -> WorldPoint? {

        switch location {

        case let .vertex(vertexID):

            return graph
                .vertex(id: vertexID)?
                .worldPoint

        case let .edge(edgeID, fraction):

            guard let edge = graph.edge(id: edgeID) else {
                return nil
            }

            return RoadEdgeGeometry.point(
                atFraction: fraction,
                on: edge,
                graph: graph
            )
        }
    }
}
