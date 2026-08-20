//
//  AlternativeRouteGenerator.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/19/26.
//


import Foundation


struct AlternativeRouteGenerator {

    let policy:
        AlternativeRouteGenerationPolicy


    init(
        policy:
            AlternativeRouteGenerationPolicy = .standard
    ) {

        self.policy =
            policy
    }


    // =====================================================
    // MARK: - Generate
    // =====================================================

    func generate(
        from chosenRoute:
            GameRoute,
        gameNodes:
            [GameMapNode],
        roadGraph:
            RoadGraph,
        timePolicy:
            RouteTimePolicy? = .dayMap
    ) -> [GameRoute] {

        guard
            policy.maxAlternatives >
                0,

            chosenRoute.isFullyPlanned,

            let chosenSignature =
                chosenRoute
                    .plannedPathSignature,

            let chosenCost =
                chosenRoute
                    .plannedTotalCost
        else {

            return []
        }


        let chosenEdges =
            chosenRoute
                .orderedUniqueRoadEdgeIDs


        guard
            !chosenEdges.isEmpty
        else {

            return []
        }


        // =============================================
        // Already known path signatures
        // =============================================

        var seenPathSignatures:
            Set<String> = [

                chosenSignature
            ]


        // =============================================
        // Penalty combinations waiting to be tried
        // =============================================

        var pendingPenaltySets:
            [Set<RoadEdgeID>] =
                chosenEdges.map {

                    Set(
                        [
                            $0
                        ]
                    )
                }


        var attemptedPenaltyKeys =
            Set<String>()


        var alternatives:
            [GameRoute] = []


        var attempts =
            0


        // =============================================
        // Search
        // =============================================

        while
            !pendingPenaltySets.isEmpty,

            attempts <
                policy
                    .maxPlanningAttempts,

            alternatives.count <
                policy
                    .maxAlternatives
        {

            let penaltySet =
                pendingPenaltySets
                    .removeFirst()


            let penaltyKey =
                penaltySetKey(
                    penaltySet
                )


            guard
                attemptedPenaltyKeys
                    .insert(
                        penaltyKey
                    )
                    .inserted
            else {

                continue
            }


            attempts +=
                1


            // =========================================
            // Build routing options
            // =========================================

            let options =
                RoadRoutingOptions
                    .standard
                    .applyingPenalty(
                        to:
                            penaltySet,
                        multiplier:
                            policy
                                .penaltyMultiplier
                    )


            // =========================================
            // Fresh unplanned route
            // =========================================

            let unplanned =
                chosenRoute
                    .unplannedPreservingStart()


            // =========================================
            // Plan candidate
            // =========================================

            let planningResult =
                GameRoutePathPlanner(
                    timePolicy:
                        timePolicy,
                    routingOptions:
                        options
                )
                .plan(
                    route:
                        unplanned,
                    gameNodes:
                        gameNodes,
                    roadGraph:
                        roadGraph
                )


            guard
                planningResult
                    .succeeded
            else {

                continue
            }


            var candidate =
                planningResult
                    .route


            guard
                let candidateSignature =
                    candidate
                        .plannedPathSignature,

                seenPathSignatures
                    .insert(
                        candidateSignature
                    )
                    .inserted
            else {

                /*
                 Dijkstra still found the same route.
                 Not an alternative.
                 */

                continue
            }


            // =========================================
            // Cost sanity check
            // =========================================

            if
                chosenCost >
                    0.000_001,

                let candidateCost =
                    candidate
                        .plannedTotalCost,

                candidateCost >
                    chosenCost
                    *
                    policy
                        .maximumCostRatio
            {

                continue
            }


            // =========================================
            // Give accepted route a unique identity
            // =========================================

            candidate =
                candidate
                    .withNewRouteID()


            alternatives.append(
                candidate
            )


            // =========================================
            // Explore further variations
            // =========================================

            for edgeID in
                candidate
                    .orderedUniqueRoadEdgeIDs {

                guard
                    !penaltySet
                        .contains(
                            edgeID
                        )
                else {

                    continue
                }


                var expanded =
                    penaltySet


                expanded.insert(
                    edgeID
                )


                pendingPenaltySets.append(
                    expanded
                )
            }
        }


        // =============================================
        // Cheapest alternatives first
        // =============================================

        return alternatives.sorted {

            (
                $0.plannedTotalCost
                ??
                .greatestFiniteMagnitude
            )

            <

            (
                $1.plannedTotalCost
                ??
                .greatestFiniteMagnitude
            )
        }
    }
}


private extension AlternativeRouteGenerator {

    func penaltySetKey(
        _ edgeIDs:
            Set<RoadEdgeID>
    ) -> String {

        edgeIDs
            .map(
                \.rawValue
            )
            .sorted()
            .joined(
                separator:
                    "|"
            )
    }
}
