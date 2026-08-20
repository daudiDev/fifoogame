//
//  FutureRoutePlanner.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/19/26.
//



import Foundation


struct FutureRouteGenerationResult:
    Equatable,
    Sendable {

    let chosenRoute:
        GameRoute?


    let alternativeRoutes:
        [GameRoute]


    let validationResult:
        GameRouteValidationResult


    let planningIssues:
        [GameRoutePathPlanningIssue]


    var succeeded:
        Bool {

        chosenRoute !=
            nil
    }
}

struct FutureRoutePlanner {

    let timePolicy:
        RouteTimePolicy?


    let alternativePolicy:
        AlternativeRouteGenerationPolicy


    init(
        timePolicy:
            RouteTimePolicy? = .dayMap,
        alternativePolicy:
            AlternativeRouteGenerationPolicy = .standard
    ) {

        self.timePolicy =
            timePolicy

        self.alternativePolicy =
            alternativePolicy
    }


    // =====================================================
    // MARK: - Generate
    // =====================================================

    func generate(
        stopNodeIDs:
            [GameNodeID],
        gameNodes:
            [GameMapNode],
        roadGraph:
            RoadGraph
    ) -> FutureRouteGenerationResult {

        // =============================================
        // Build semantic route
        // =============================================

        let unplannedRoute =
            GameRoute
                .unplanned(
                    stopNodeIDs:
                        stopNodeIDs
                )


        // =============================================
        // Validate gameplay stops
        // =============================================

        let validation =
            GameRouteValidator
                .validate(
                    unplannedRoute,
                    gameNodes:
                        gameNodes,
                    roadGraph:
                        roadGraph
                )


        guard
            validation.isValid
        else {

            return FutureRouteGenerationResult(
                chosenRoute:
                    nil,
                alternativeRoutes:
                    [],
                validationResult:
                    validation,
                planningIssues:
                    []
            )
        }


        // =============================================
        // Find best route
        // =============================================

        let primaryPlanning =
            GameRoutePathPlanner(
                timePolicy:
                    timePolicy,
                routingOptions:
                    .standard
            )
            .plan(
                route:
                    unplannedRoute,
                gameNodes:
                    gameNodes,
                roadGraph:
                    roadGraph
            )


        guard
            primaryPlanning
                .succeeded
        else {

            return FutureRouteGenerationResult(
                chosenRoute:
                    nil,
                alternativeRoutes:
                    [],
                validationResult:
                    validation,
                planningIssues:
                    primaryPlanning
                        .issues
            )
        }


        let chosen =
            primaryPlanning
                .route


        // =============================================
        // Generate different valid road routes
        // =============================================

        let alternatives =
            AlternativeRouteGenerator(
                policy:
                    alternativePolicy
            )
            .generate(
                from:
                    chosen,
                gameNodes:
                    gameNodes,
                roadGraph:
                    roadGraph,
                timePolicy:
                    timePolicy
            )


        return FutureRouteGenerationResult(
            chosenRoute:
                chosen,
            alternativeRoutes:
                alternatives,
            validationResult:
                validation,
            planningIssues:
                []
        )
    }
}
