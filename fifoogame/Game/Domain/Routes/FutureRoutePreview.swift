//
//  FutureRoutePreview.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/19/26.
//


import Foundation


struct FutureRoutePreview:
    Equatable,
    Sendable {

    /// Best/default planned route.
    let primaryRoute:
        GameRoute


    /// Other valid road paths through exactly
    /// the same ordered gameplay stops.
    let alternativeRoutes:
        [GameRoute]


    /// Route currently selected by the user in preview.
    var selectedRouteID:
        RouteID


    // =====================================================
    // MARK: - Selected Route
    // =====================================================

    var selectedRoute:
        GameRoute? {

        if
            primaryRoute.id ==
                selectedRouteID
        {

            return primaryRoute
        }


        return alternativeRoutes
            .first {

                $0.id ==
                    selectedRouteID
            }
    }


    var allRoutes:
        [GameRoute] {

        [
            primaryRoute
        ]
        +
        alternativeRoutes
    }


    var hasAlternatives:
        Bool {

        !alternativeRoutes.isEmpty
    }
}
