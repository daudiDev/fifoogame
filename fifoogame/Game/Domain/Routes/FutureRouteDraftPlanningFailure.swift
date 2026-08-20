//
//  FutureRouteDraftPlanningFailure.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/20/26.
//


import Foundation


enum FutureRouteDraftPlanningFailure:
    Equatable,
    Sendable {

    case invalidDraft

    case noValidRoadPath

    case currentRoutePositionUnavailable
}