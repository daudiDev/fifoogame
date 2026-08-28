//
//  GameNodeRouteAnchorResolver.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/19/26.
//

import Foundation


struct GameNodeRouteAnchorResolver {

    private let relationshipResolver =
        GameNodeRoadRelationshipResolver()


    // =====================================================
    // MARK: - Resolve
    // =====================================================

    func resolve(
        node:
            GameMapNode,
        graph:
            RoadGraph
    ) -> GameNodeRouteAnchor? {

        /*
         Disabled objects remain valid map objects,
         but don't participate in active routing.
         */

        guard
            node.isEnabled
        else {

            return nil
        }


        // =============================================
        // Actual node coordinate
        // =============================================

        guard let nodeCoordinate =
            GameNodePlacementResolver
                .mapCoordinate(
                    for:
                        node,
                    graph:
                        graph
                )
        else {

            return nil
        }


        // =============================================
        // Geometric road relationship
        // =============================================

        let relationship =
            relationshipResolver
                .resolve(
                    node:
                        node,
                    graph:
                        graph
                )


        switch relationship {

        // =============================================
        // Off Road
        // =============================================

        case .offRoad:

            // Tile-map migration:
            //
            // A card is centered inside a deterministic GridCellID, while the
            // retained pathfinding graph still runs along the old cell
            // boundaries. Card-centered nodes therefore look "off road" even
            // though they must remain usable as route stops in the new UI.
            //
            // Only the canonical GridRoadGraph receives this fallback. The
            // node itself is NOT snapped or mutated; we create an internal
            // routing anchor at the nearest traversable hidden edge.
            if graph.id == GridRoadGraph.graphID,
               let fallbackLocation =
                tileRouteFallbackLocation(
                    for: nodeCoordinate,
                    graph: graph
                ) {

                return GameNodeRouteAnchor(
                    nodeID: node.id,
                    nodeCoordinate: nodeCoordinate,
                    roadLocation: fallbackLocation
                )
            }

            return nil


        // =============================================
        // Road Vertex
        // =============================================

        case let .vertex(
            vertexID
        ):

            guard
                vertexCanParticipateInRoute(
                    vertexID:
                        vertexID,
                    graph:
                        graph
                )
            else {

                return nil
            }


            return GameNodeRouteAnchor(
                nodeID:
                    node.id,
                nodeCoordinate:
                    nodeCoordinate,
                roadLocation:
                    .vertex(
                        vertexID
                    )
            )


        // =============================================
        // Road Edge
        // =============================================

        case let .edge(
            edgeID,
            fraction
        ):

            guard
                edgeCanParticipateInRoute(
                    edgeID:
                        edgeID,
                    graph:
                        graph
                )
            else {

                return nil
            }

            return GameNodeRouteAnchor(
                nodeID:
                    node.id,
                nodeCoordinate:
                    nodeCoordinate,
                roadLocation:
                    .edge(
                        edgeID:
                            edgeID,
                        fraction:
                            fraction
                    )
            )
        }
    }
}

// =====================================================
// MARK: - Tile Map Routing Fallback
// =====================================================

private extension GameNodeRouteAnchorResolver {

    func tileRouteFallbackLocation(
        for coordinate: MapCoordinate,
        graph: RoadGraph
    ) -> GameNodeRouteAnchor.RoadLocation? {

        let worldPoint =
            MapCoordinateConverter
                .worldPoint(
                    for: coordinate
                )


        var best:
            (
                edgeID: RoadEdgeID,
                fraction: Double,
                distance: Double,
                timeDelta: Double
            )?


        for edge in graph.edges {

            guard
                edge.attributes.isTraversable,
                edge.travelDirection != .closed,
                let projection =
                    RoadEdgeGeometry
                        .projection(
                            of: worldPoint,
                            onto: edge,
                            graph: graph
                        )
            else {
                continue
            }


            let projectedCoordinate =
                MapCoordinateConverter
                    .mapCoordinate(
                        for: projection.point
                    )

            let candidate =
                (
                    edgeID: edge.id,
                    fraction: projection.fraction,
                    distance: projection.distance,
                    timeDelta:
                        abs(
                            projectedCoordinate
                                .time
                                .secondsFromMidnight
                            - coordinate
                                .time
                                .secondsFromMidnight
                        )
                )


            guard let current = best else {

                best = candidate
                continue
            }


            let distanceDelta =
                abs(
                    candidate.distance
                    - current.distance
                )


            if candidate.distance < current.distance {

                best = candidate

            } else if distanceDelta < 0.000_1 {

                let timeDeltaDifference =
                    abs(
                        candidate.timeDelta
                        - current.timeDelta
                    )

                if candidate.timeDelta < current.timeDelta
                    || (
                        timeDeltaDifference < 0.000_1
                        && candidate.edgeID.rawValue
                            < current.edgeID.rawValue
                    ) {

                    best = candidate
                }
            }
        }


        guard let best else {
            return nil
        }


        return .edge(
            edgeID: best.edgeID,
            fraction: best.fraction
        )
    }
}


// =====================================================
// MARK: - Route Eligibility
// =====================================================

private extension GameNodeRouteAnchorResolver {

    func vertexCanParticipateInRoute(
        vertexID:
            RoadVertexID,
        graph:
            RoadGraph
    ) -> Bool {

        guard let vertex =
            graph.vertex(
                id:
                    vertexID
            )
        else {

            return false
        }


        /*
         Geometry-only control points should not
         become gameplay route destinations.
         */

        guard
            vertex.kind !=
                .control
        else {

            return false
        }


        /*
         At least one traversable road needs to
         touch the vertex.
         */

        return !graph
            .incidentEdges(
                to:
                    vertexID,
                traversableOnly:
                    true
            )
            .isEmpty
    }


    func edgeCanParticipateInRoute(
        edgeID:
            RoadEdgeID,
        graph:
            RoadGraph
    ) -> Bool {

        guard let edge =
            graph.edge(
                id:
                    edgeID
            )
        else {

            return false
        }


        guard
            edge.attributes
                .isTraversable
        else {

            return false
        }


        guard
            edge.travelDirection !=
                .closed
        else {

            return false
        }


        return true
    }
}
