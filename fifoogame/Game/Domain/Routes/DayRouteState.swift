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

    /// The route already traveled by the user.
    ///
    /// It starts empty at the beginning of the day
    /// and grows as route progress is completed.
    var completedRoute:
        GameRoute


    /// The currently chosen future route.
    ///
    /// It starts empty until a route is selected.
    var chosenFutureRoute:
        GameRoute


    /// Other viable future routes.
    var alternativeRoutes:
        [GameRoute]


    init(
        completedRoute:
            GameRoute = GameRoute(),
        chosenFutureRoute:
            GameRoute = GameRoute(),
        alternativeRoutes:
            [GameRoute] = []
    ) {

        self.completedRoute =
            completedRoute

        self.chosenFutureRoute =
            chosenFutureRoute

        self.alternativeRoutes =
            alternativeRoutes
    }
}

extension DayRouteState {

    var hasChosenFutureRoute:
        Bool {

        !chosenFutureRoute
            .isEmpty
    }


    var hasCompletedRoute:
        Bool {

        !completedRoute
            .isEmpty
    }


    var allFutureRoutes:
        [GameRoute] {

        if chosenFutureRoute.isEmpty {

            return alternativeRoutes
        }


        return [
            chosenFutureRoute
        ]
        +
        alternativeRoutes
    }
}
