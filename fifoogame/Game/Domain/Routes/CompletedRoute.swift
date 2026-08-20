//
//  CompletedRoute.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/19/26.
//


import Foundation


struct CompletedRoute:
    Equatable,
    Sendable {

    /// Actual road geometry that has already
    /// become history.
    ///
    /// This is append-only during the day.
    var segments:
        [RoadRouteSegment]


    /// Gameplay route stops that have actually
    /// been reached.
    var reachedNodeIDs:
        [GameNodeID]


    /// Last day-map time processed by the
    /// completion engine.
    ///
    /// nil means progression has not started yet.
    var throughTime:
        DayTime?


    /// Current end of the completed road trace.
    ///
    /// May be:
    ///
    /// - road vertex
    /// - partial position on an edge
    /// - nil when no road has yet been completed
    var boundary:
        GameNodeRouteAnchor.RoadLocation?


    init(
        segments:
            [RoadRouteSegment] = [],
        reachedNodeIDs:
            [GameNodeID] = [],
        throughTime:
            DayTime? = nil,
        boundary:
            GameNodeRouteAnchor.RoadLocation? = nil
    ) {

        self.segments =
            segments

        self.reachedNodeIDs =
            reachedNodeIDs

        self.throughTime =
            throughTime

        self.boundary =
            boundary
    }
}

extension CompletedRoute {

    var isEmpty:
        Bool {

        segments.isEmpty
        &&
        reachedNodeIDs.isEmpty
    }


    var lastReachedNodeID:
        GameNodeID? {

        reachedNodeIDs.last
    }


    var edgeIDs:
        [RoadEdgeID] {

        segments.map(
            \.edgeID
        )
    }
}

extension CompletedRoute {

    mutating func append(
        segments newSegments:
            [RoadRouteSegment]
    ) {

        for segment in
            newSegments {

            append(
                segment:
                    segment
            )
        }
    }
}

private extension CompletedRoute {

    mutating func append(
        segment newSegment:
            RoadRouteSegment
    ) {

        let epsilon =
            0.000_001


        guard
            newSegment
                .traversedFraction
            >
            epsilon
        else {

            return
        }


        guard let last =
            segments.last
        else {

            segments.append(
                newSegment
            )

            return
        }


        // =============================================
        // Exact duplicate
        // =============================================

        if last ==
            newSegment {

            return
        }


        // =============================================
        // Merge contiguous pieces of same road
        // =============================================

        let lastDirection =
            last.toFraction
            -
            last.fromFraction


        let newDirection =
            newSegment.toFraction
            -
            newSegment.fromFraction


        let sameDirection =
            lastDirection
            *
            newDirection
            >
            0


        let contiguous =
            abs(
                last.toFraction
                -
                newSegment.fromFraction
            )
            <=
            epsilon


        if
            last.edgeID ==
                newSegment.edgeID,

            sameDirection,

            contiguous
        {

            segments[
                segments.count - 1
            ] =
                RoadRouteSegment(
                    edgeID:
                        last.edgeID,
                    fromFraction:
                        last.fromFraction,
                    toFraction:
                        newSegment.toFraction
                )


            return
        }


        segments.append(
            newSegment
        )
    }
}

extension CompletedRoute {

    mutating func appendReachedNodes(
        _ nodeIDs:
            [GameNodeID]
    ) {

        var existing =
            Set(
                reachedNodeIDs
            )


        for nodeID in
            nodeIDs {

            guard
                existing
                    .insert(
                        nodeID
                    )
                    .inserted
            else {

                continue
            }


            reachedNodeIDs.append(
                nodeID
            )
        }
    }
}
