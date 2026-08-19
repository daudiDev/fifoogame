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

            /*
             This is perfectly valid.

             It simply means this node cannot act as
             a road-route anchor.
             */

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
            edgeID
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
                        edgeID
                    )
            )
        }
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
