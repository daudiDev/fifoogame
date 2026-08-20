//
//  FutureRouteDraft.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/19/26.
//


import Foundation


struct FutureRouteDraft:
    Equatable,
    Sendable {

    // =====================================================
    // MARK: - Source
    // =====================================================
    
    enum Source:
        Equatable,
        Sendable {

        case newRoute

        case existingChosenRoute(
            routeID: RouteID
        )
    }


    // =====================================================
    // MARK: - Properties
    // =====================================================

    var source:
        Source


    /// Ordered gameplay nodes the user intends
    /// to visit in the future.
    ///
    /// These are NOT arbitrary coordinates.
    /// They remain real GameMapNode IDs.
    var stopNodeIDs:
        [GameNodeID]


    // =====================================================
    // MARK: - Init
    // =====================================================

    init(
        source:
            Source = .newRoute,
        stopNodeIDs:
            [GameNodeID] = []
    ) {

        self.source =
            source

        self.stopNodeIDs =
            stopNodeIDs
    }
}

extension FutureRouteDraft {

    var isEmpty:
        Bool {

        stopNodeIDs.isEmpty
    }


    var stopCount:
        Int {

        stopNodeIDs.count
    }


    var canAttemptPlanning:
        Bool {

        stopNodeIDs.count >= 2
    }


    func contains(
        _ nodeID:
            GameNodeID
    ) -> Bool {

        stopNodeIDs.contains(
            nodeID
        )
    }
}

extension FutureRouteDraft {

    var isEditingExistingRoute:
        Bool {

        if case .existingChosenRoute =
            source
        {

            return true
        }


        return false
    }


    var originalRouteID:
        RouteID? {

        switch source {

        case .newRoute:

            return nil


        case let .existingChosenRoute(
            routeID
        ):

            return routeID
        }
    }
}


