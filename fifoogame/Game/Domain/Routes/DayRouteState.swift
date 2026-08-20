//
//  DayRouteState.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/19/26.
//

import Foundation


struct DayRouteState:
    Equatable,
    Sendable {

    // =====================================================
    // MARK: - Past
    // =====================================================

    /// Frozen route history.
    var completedRoute:
        CompletedRoute


    // =====================================================
    // MARK: - Future
    // =====================================================

    var chosenFutureRoute:
        GameRoute


    var alternativeRoutes:
        [GameRoute]


    /// Time at which this chosen route became active.
    ///
    /// This prevents a route selected at 3 PM from
    /// retroactively becoming "completed" between
    /// 8 AM and 3 PM.
    var chosenFutureRouteActivatedAt:
        DayTime?


    // =====================================================
    // MARK: - Init
    // =====================================================

    init(
        completedRoute:
            CompletedRoute = CompletedRoute(),
        chosenFutureRoute:
            GameRoute = GameRoute(),
        alternativeRoutes:
            [GameRoute] = [],
        chosenFutureRouteActivatedAt:
            DayTime? = nil
    ) {

        self.completedRoute =
            completedRoute

        self.chosenFutureRoute =
            chosenFutureRoute

        self.alternativeRoutes =
            alternativeRoutes

        self.chosenFutureRouteActivatedAt =
            chosenFutureRouteActivatedAt
    }
}

extension DayRouteState {

    var hasCompletedRoute:
        Bool {

        !completedRoute
            .isEmpty
    }


    var hasChosenFutureRoute:
        Bool {

        !chosenFutureRoute
            .isEmpty
    }


    var hasAlternatives:
        Bool {

        !alternativeRoutes
            .isEmpty
    }


    var allFutureRoutes:
        [GameRoute] {

        guard
            !chosenFutureRoute
                .isEmpty
        else {

            return alternativeRoutes
        }


        return [
            chosenFutureRoute
        ]
        +
        alternativeRoutes
    }
}
