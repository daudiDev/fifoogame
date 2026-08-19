//
//  RoadGraph.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/18/26.
//

import Foundation


// MARK: - Road Graph

struct RoadGraph:
    Identifiable,
    Codable,
    Hashable,
    Sendable {

    let id: RoadGraphID

    var version: Int

    var vertices: [RoadVertex]

    var edges: [RoadEdge]


    init(
        id: RoadGraphID,
        version: Int,
        vertices: [RoadVertex],
        edges: [RoadEdge]
    ) {

        self.id =
            id

        self.version =
            version

        self.vertices =
            vertices

        self.edges =
            edges
    }
}


// MARK: - Lookup

extension RoadGraph {

    func vertex(
        id: RoadVertexID
    ) -> RoadVertex? {

        vertices.first {
            $0.id == id
        }
    }


    func edge(
        id: RoadEdgeID
    ) -> RoadEdge? {

        edges.first {
            $0.id == id
        }
    }
}


// MARK: - Incident Edges

extension RoadGraph {

    func incidentEdges(
        to vertexID:
            RoadVertexID,
        traversableOnly:
            Bool = false
    ) -> [RoadEdge] {

        edges.filter { edge in

            let touchesVertex =
                edge.fromID == vertexID
                ||
                edge.toID == vertexID


            guard touchesVertex else {

                return false
            }


            guard traversableOnly else {

                return true
            }


            return edge
                .attributes
                .isTraversable
            &&
            edge.travelDirection
                != .closed
        }
    }


    func degree(
        of vertexID:
            RoadVertexID,
        traversableOnly:
            Bool = true
    ) -> Int {

        incidentEdges(
            to:
                vertexID,
            traversableOnly:
                traversableOnly
        )
        .count
    }
}

// MARK: - Road Connection

struct RoadConnection:
    Hashable,
    Sendable {

    let edgeID:
        RoadEdgeID

    let fromVertexID:
        RoadVertexID

    let toVertexID:
        RoadVertexID

    let roadClass:
        RoadClass

    let routingCostMultiplier:
        Double
}


// MARK: - Traversal

extension RoadGraph {

    func outgoingConnections(
        from vertexID:
            RoadVertexID
    ) -> [RoadConnection] {

        edges.compactMap { edge in

            guard
                edge.attributes
                    .isTraversable,
                edge.travelDirection
                    != .closed
            else {

                return nil
            }


            // ----------------------------------
            // Vertex is edge's FROM endpoint
            // ----------------------------------

            if edge.fromID ==
                vertexID {

                switch edge.travelDirection {

                case .bidirectional,
                     .fromTo:

                    return RoadConnection(
                        edgeID:
                            edge.id,
                        fromVertexID:
                            vertexID,
                        toVertexID:
                            edge.toID,
                        roadClass:
                            edge.roadClass,
                        routingCostMultiplier:
                            edge
                                .attributes
                                .routingCostMultiplier
                    )


                case .toFrom,
                     .closed:

                    return nil
                }
            }


            // ----------------------------------
            // Vertex is edge's TO endpoint
            // ----------------------------------

            if edge.toID ==
                vertexID {

                switch edge.travelDirection {

                case .bidirectional,
                     .toFrom:

                    return RoadConnection(
                        edgeID:
                            edge.id,
                        fromVertexID:
                            vertexID,
                        toVertexID:
                            edge.fromID,
                        roadClass:
                            edge.roadClass,
                        routingCostMultiplier:
                            edge
                                .attributes
                                .routingCostMultiplier
                    )


                case .fromTo,
                     .closed:

                    return nil
                }
            }


            return nil
        }
    }
}
