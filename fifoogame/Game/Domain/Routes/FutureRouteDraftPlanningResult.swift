//
//  FutureRouteDraftPlanningResult.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/19/26.
//


import Foundation


enum FutureRouteDraftPlanStart:
    Equatable,
    Sendable {

    case firstSelectedStop

    case currentRoutePosition(
        RoadRouteAnchor
    )
}


struct FutureRouteDraftPlanningResult:
    Equatable,
    Sendable {

    let validation:
        FutureRouteDraftValidationResult

    let plannedRoute:
        GameRoute?

    let planningIssues:
        [GameRoutePathPlanningIssue]

    let start:
        FutureRouteDraftPlanStart?

    let failure:
        FutureRouteDraftPlanningFailure?


    var succeeded:
        Bool {

        failure == nil
        &&
        validation.isValid
        &&
        plannedRoute?.isFullyPlanned == true
        &&
        planningIssues.isEmpty
    }
}
