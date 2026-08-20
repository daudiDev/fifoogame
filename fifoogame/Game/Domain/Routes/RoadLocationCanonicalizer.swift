//
//  RoadLocationCanonicalizer.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/19/26.
//


import Foundation


enum RoadLocationCanonicalizer {

    static let fractionTolerance =
        0.000_001


    // =====================================================
    // MARK: - Canonical Location
    // =====================================================

    static func canonical(
        _ location:
            GameNodeRouteAnchor.RoadLocation,
        graph:
            RoadGraph
    ) -> GameNodeRouteAnchor.RoadLocation {

        switch location {

        case .vertex:

            return location


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

                return location
            }


            if fraction <=
                fractionTolerance {

                return .vertex(
                    edge.fromID
                )
            }


            if fraction >=
                1
                -
                fractionTolerance {

                return .vertex(
                    edge.toID
                )
            }


            return .edge(
                edgeID:
                    edgeID,
                fraction:
                    fraction
            )
        }
    }
}


extension RoadLocationCanonicalizer {

    static func equivalent(
        _ lhs:
            GameNodeRouteAnchor.RoadLocation,
        _ rhs:
            GameNodeRouteAnchor.RoadLocation,
        graph:
            RoadGraph
    ) -> Bool {

        let left =
            canonical(
                lhs,
                graph:
                    graph
            )


        let right =
            canonical(
                rhs,
                graph:
                    graph
            )


        switch (
            left,
            right
        ) {

        case let (
            .vertex(lhsID),
            .vertex(rhsID)
        ):

            return lhsID ==
                rhsID


        case let (
            .edge(lhsID, lhsFraction),
            .edge(rhsID, rhsFraction)
        ):

            return
                lhsID ==
                    rhsID
                &&
                abs(
                    lhsFraction
                    -
                    rhsFraction
                )
                <=
                fractionTolerance


        default:

            return false
        }
    }
}
