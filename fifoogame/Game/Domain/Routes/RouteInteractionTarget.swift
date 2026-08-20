//
//  RouteInteractionTarget.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/19/26.
//


import Foundation


enum RouteInteractionTarget:
    Equatable,
    Sendable,
    Identifiable {

    case completed

    case chosen(
        routeID:
            RouteID
    )

    case alternative(
        routeID:
            RouteID
    )


    // =====================================================
    // MARK: - ID
    // =====================================================

    var id: String {

        switch self {

        case .completed:

            return "completed"


        case let .chosen(
            routeID
        ):

            return "chosen-\(routeID.rawValue.uuidString)"


        case let .alternative(
            routeID
        ):

            return "alternative-\(routeID.rawValue.uuidString)"
        }
    }


    // =====================================================
    // MARK: - Route ID
    // =====================================================

    var routeID:
        RouteID? {

        switch self {

        case .completed:

            return nil


        case let .chosen(
            routeID
        ),
        let .alternative(
            routeID
        ):

            return routeID
        }
    }
}
