//
//  RouteAction.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/19/26.
//


import Foundation


enum RouteAction:
    Equatable,
    Sendable {

    case inspectCompleted


    case inspectChosen(
        routeID:
            RouteID
    )


    case inspectAlternative(
        routeID:
            RouteID
    )
}

enum RouteActionResolver {

    static func action(
        for target:
            RouteInteractionTarget
    ) -> RouteAction {

        switch target {

        case .completed:

            return .inspectCompleted


        case let .chosen(
            routeID
        ):

            return .inspectChosen(
                routeID:
                    routeID
            )


        case let .alternative(
            routeID
        ):

            return .inspectAlternative(
                routeID:
                    routeID
            )
        }
    }
}
