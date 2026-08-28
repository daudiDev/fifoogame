//
//  DebugRouteRenderDemo.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/26/26.
//


#if DEBUG

import Foundation


enum DebugRouteRenderPreset:
    String,
    CaseIterable,
    Identifiable {

    case fullDayAllStates
    case futureOnly
    case earlyMixed
    case balancedMixed
    case lateMixed
    case completedOnly


    var id: String {
        rawValue
    }


    var title: String {

        switch self {

        case .fullDayAllStates:
            return "Full Day — All States"

        case .futureOnly:
            return "Future Only — 8:00 AM"

        case .earlyMixed:
            return "Early Mix — 10:00 AM"

        case .balancedMixed:
            return "All States — 12:45 PM"

        case .lateMixed:
            return "Late Mix — 3:15 PM"

        case .completedOnly:
            return "Completed Only — 5:00 PM"
        }
    }


    var time: DayTime {

        switch self {

        case .fullDayAllStates:
            // Noon puts the Completed / Chosen split exactly halfway
            // through the 24-hour map while the route itself spans
            // 12:00 AM through 11:59 PM.
            return DayTime(
                secondsFromMidnight:
                    12 * 3_600
            )

        case .futureOnly:
            return DayTime(
                secondsFromMidnight:
                    8 * 3_600
            )

        case .earlyMixed:
            return DayTime(
                secondsFromMidnight:
                    10 * 3_600
            )

        case .balancedMixed:
            return DayTime(
                secondsFromMidnight:
                    (12 * 3_600)
                    +
                    (45 * 60)
            )

        case .lateMixed:
            return DayTime(
                secondsFromMidnight:
                    (15 * 3_600)
                    +
                    (15 * 60)
            )

        case .completedOnly:
            return DayTime(
                secondsFromMidnight:
                    17 * 3_600
            )
        }
    }
}


@MainActor
extension GameStore {

    /// Builds the normal deterministic chosen route, then installs two
    /// deliberately divergent RENDER-ONLY alternatives for DEBUG testing.
    ///
    /// Why the explicit render fixtures?
    /// `AlternativeRouteGenerator` is production logic and is allowed to
    /// return zero alternatives when it cannot find sufficiently distinct,
    /// valid routes. That makes it a poor dependency for a renderer test.
    ///
    /// These render-only paths are used by `routeRenderState` in DEBUG builds;
    /// they do not replace or mutate the authoritative live route models.
    @discardableResult
    func installRouteRenderDemo(
        _ preset: DebugRouteRenderPreset = .fullDayAllStates
    ) -> Bool {

        // The full-day fixture is intentionally render-first: it does not
        // depend on the production planner or production alternative finder.
        // That guarantees a vertically dominant 12:00 AM → 11:59 PM route
        // with all three visual states present at once.
        if preset == .fullDayAllStates {
            return installFullDayRouteRenderDemo()
        }

        let routeStartTime =
            DayTime(
                secondsFromMidnight:
                    8 * 3_600
            )


        // =====================================================
        // 1. Remove any previous render-only override.
        // =====================================================

        debugAlternativeRenderPaths =
            nil

        debugRouteRenderStateOverride =
            nil


        // =====================================================
        // 2. Ensure deterministic fixture nodes exist.
        // =====================================================

        if debugRouteScenario == nil {

            guard
                installDebugRouteScenario()
                != nil
            else {

                print(
                    "❌ Could not install path-render demo stops."
                )

                return false
            }

        } else {

            resetSimulationDay(
                to:
                    routeStartTime
            )
        }


        // =====================================================
        // 3. Build + commit the normal chosen route.
        // =====================================================

        buildDebugChosenRoute()


        guard
            !routeState
                .chosenFutureRoute
                .isEmpty
        else {

            print(
                "❌ Path-render demo failed to create a chosen path."
            )

            return false
        }


        // Freeze the clock so the visual test stays put.
        pauseSimulation()


        // =====================================================
        // 4. Advance Completed / Chosen to test time.
        // =====================================================

        let progression =
            updateCurrentDayTime(
                preset.time
            )


        guard progression.succeeded else {

            print(
                "❌ Path-render demo could not advance to \(preset.title)."
            )

            return false
        }


        // =====================================================
        // 5. Install guaranteed-visible alternative paths.
        // =====================================================

        debugAlternativeRenderPaths =
            makeDebugAlternativeRenderPaths(
                for:
                    preset
            )


        // =====================================================
        // 6. Diagnostics.
        // =====================================================

        let renderState =
            routeRenderState


        print("")
        print("==========================================")
        print("        PATH RENDER DEMO READY")
        print("==========================================")
        print("Preset: \(preset.title)")
        print("Clock: \(currentDayTime.displayClockString)")
        print("Completed segments: \(renderState.completedSegments.count)")
        print(
            "Chosen future segments:",
            renderState.chosenFuture?.segments.count ?? 0
        )
        print(
            "Production alternatives generated:",
            routeState.alternativeRoutes.count
        )
        print(
            "Render-test alternatives visible:",
            renderState.alternatives.count
        )

        for (index, route) in
            renderState
                .alternatives
                .enumerated() {

            print(
                "Alternative \(index + 1) segments: \(route.segments.count)"
            )
        }

        print("==========================================")
        print("")


        return true
    }


    /// Restores route rendering to the actual authoritative route state.
    func clearRouteRenderDemoAlternatives() {

        debugAlternativeRenderPaths =
            nil

        debugRouteRenderStateOverride =
            nil
    }
}


// =====================================================
// MARK: - Full-Day All-State Renderer Fixture
// =====================================================

@MainActor
private extension GameStore {

    /// Installs one deterministic route that spans the entire day vertically:
    ///
    ///     12:00 AM ------------------------------ 11:59 PM
    ///
    /// At noon, the first half is rendered as Completed and the second half
    /// as Chosen. Multiple alternative futures branch/rejoin throughout the day and continue to
    /// 11:59 PM. Horizontal movement is intentionally narrow so the visual
    /// reads as a DAY route first, not a wide cross-map route.
    @discardableResult
    func installFullDayRouteRenderDemo() -> Bool {

        // This fixture is deliberately production-shaped rather than a
        // renderer-only mock. It installs real route-state data plus real map
        // nodes so node taps, route inspectors, route switching, overlap,
        // end-of-day layout, and the current-user boundary marker can all be
        // tested together.

        resetSimulationDay(
            to:
                DayTime(
                    secondsFromMidnight:
                        12 * 3_600
                )
        )

        pauseSimulation()

        debugAlternativeRenderPaths =
            nil

        debugRouteRenderStateOverride =
            nil

        let baseGameNodes =
            gameNodes.filter { node in
                guard case let .activity(content) = node.content else {
                    return true
                }

                return !content.activityID.hasPrefix(
                    "debug-full-day-"
                )
            }


        // =====================================================
        // 1. Shared route geometry
        // =====================================================

        let boundary =
            GridIntersectionID(
                column: 5,
                row: 8
            )


        // COMPLETED: 12:00 AM → 12:00 PM
        let completedPoints: [GridIntersectionID] = [
            .init(column: 4, row: 0),
            .init(column: 4, row: 2),
            .init(column: 3, row: 2),
            .init(column: 3, row: 4),
            .init(column: 4, row: 4),
            .init(column: 4, row: 6),
            .init(column: 4, row: 8),
            boundary
        ]

        let completedSegments =
            debugSegments(
                through:
                    completedPoints
            )


        // =====================================================
        // 2. Completed-route nodes
        // =====================================================

        let completedSpecs: [(GridIntersectionID, String)] = [
            (.init(column: 4, row: 1), "Early Start"),       // 1:30 AM
            (.init(column: 3, row: 3), "Morning Reset"),     // 4:30 AM
            (.init(column: 4, row: 5), "Breakfast Walk"),    // 7:30 AM
            (.init(column: 4, row: 7), "Midday Prep")        // 10:30 AM
        ]

        let completedNodes =
            completedSpecs.map {
                makeFullDayFixtureNode(
                    intersection:
                        $0.0,
                    title:
                        $0.1,
                    routeRole:
                        "completed",
                    status:
                        "Completed"
                )
            }

        // Nodes are published together after the entire fixture is built.
        // Keeping fixture construction side-effect free avoids repeatedly
        // selecting newly-added nodes while the routes are being assembled.


        // =====================================================
        // 3. Chosen-route nodes
        // =====================================================

        let chosenOneIntersection =
            GridIntersectionID(column: 5, row: 9)     // 1:30 PM

        let chosenTwoIntersection =
            GridIntersectionID(column: 4, row: 11)    // 4:30 PM

        let chosenThreeIntersection =
            GridIntersectionID(column: 5, row: 13)    // 7:30 PM

        let chosenFourIntersection =
            GridIntersectionID(column: 4, row: 15)    // 10:30 PM

        let endOfDayCoordinate =
            debugEndOfDayCoordinate(
                column: 4
            )


        let chosenNodes = [
            makeFullDayFixtureNode(
                intersection:
                    chosenOneIntersection,
                title:
                    "Lunch Follow-up",
                routeRole:
                    "chosen"
            ),

            makeFullDayFixtureNode(
                intersection:
                    chosenTwoIntersection,
                title:
                    "Afternoon Focus",
                routeRole:
                    "chosen"
            ),

            makeFullDayFixtureNode(
                intersection:
                    chosenThreeIntersection,
                title:
                    "Evening Workout",
                routeRole:
                    "chosen"
            ),

            makeFullDayFixtureNode(
                intersection:
                    chosenFourIntersection,
                title:
                    "Wind Down",
                routeRole:
                    "chosen"
            ),

            makeFullDayFixtureNode(
                coordinate:
                    endOfDayCoordinate,
                title:
                    "End of Day",
                routeRole:
                    "chosen"
            )
        ]

        // =====================================================
        // 4. Five alternative routes + their own nodes
        // =====================================================
        //
        // The alternatives intentionally branch and rejoin at different
        // points of the chosen route. This gives a much better interaction
        // fixture than five routes that all diverge only at noon.

        let altOneIntersection =
            GridIntersectionID(column: 6, row: 9)     // 1:30 PM

        let altTwoIntersection =
            GridIntersectionID(column: 3, row: 11)    // 4:30 PM

        let altThreeIntersection =
            GridIntersectionID(column: 6, row: 13)    // 7:30 PM

        let altFourIntersection =
            GridIntersectionID(column: 3, row: 15)    // 10:30 PM

        let altFiveOneIntersection =
            GridIntersectionID(column: 7, row: 9)     // 1:30 PM

        let altFiveTwoIntersection =
            GridIntersectionID(column: 7, row: 13)    // 7:30 PM


        let alternativeNodes = [
            makeFullDayFixtureNode(
                intersection:
                    altOneIntersection,
                title:
                    "Coffee Detour",
                routeRole:
                    "alternative-1"
            ),

            makeFullDayFixtureNode(
                intersection:
                    altTwoIntersection,
                title:
                    "Errand Stop",
                routeRole:
                    "alternative-2"
            ),

            makeFullDayFixtureNode(
                intersection:
                    altThreeIntersection,
                title:
                    "Dinner Option",
                routeRole:
                    "alternative-3"
            ),

            makeFullDayFixtureNode(
                intersection:
                    altFourIntersection,
                title:
                    "Late Stop",
                routeRole:
                    "alternative-4"
            ),

            makeFullDayFixtureNode(
                intersection:
                    altFiveOneIntersection,
                title:
                    "Long Detour",
                routeRole:
                    "alternative-5"
            ),

            makeFullDayFixtureNode(
                intersection:
                    altFiveTwoIntersection,
                title:
                    "Evening Rejoin",
                routeRole:
                    "alternative-5"
            )
        ]

        // =====================================================
        // 5. Build a fully planned CHOSEN route
        // =====================================================

        let chosenRouteID =
            RouteID()

        let chosenRoute =
            GameRoute(
                id:
                    chosenRouteID,
                stopNodeIDs: [
                    chosenNodes[0].id,
                    chosenNodes[1].id,
                    chosenNodes[2].id,
                    chosenNodes[3].id,
                    chosenNodes[4].id
                ],
                entryLeg:
                    debugEntryLeg(
                        startIntersection:
                            boundary,
                        toNodeID:
                            chosenNodes[0].id,
                        through: [
                            boundary,
                            chosenOneIntersection
                        ]
                    ),
                legs: [
                    debugLeg(
                        from:
                            chosenNodes[0].id,
                        to:
                            chosenNodes[1].id,
                        through: [
                            chosenOneIntersection,
                            .init(column: 5, row: 10),
                            .init(column: 4, row: 10),
                            chosenTwoIntersection
                        ]
                    ),

                    debugLeg(
                        from:
                            chosenNodes[1].id,
                        to:
                            chosenNodes[2].id,
                        through: [
                            chosenTwoIntersection,
                            .init(column: 4, row: 12),
                            .init(column: 5, row: 12),
                            chosenThreeIntersection
                        ]
                    ),

                    debugLeg(
                        from:
                            chosenNodes[2].id,
                        to:
                            chosenNodes[3].id,
                        through: [
                            chosenThreeIntersection,
                            .init(column: 5, row: 14),
                            .init(column: 4, row: 14),
                            chosenFourIntersection
                        ]
                    ),

                    debugLegEndingAtElevenFiftyNine(
                        from:
                            chosenNodes[3].id,
                        to:
                            chosenNodes[4].id,
                        through: [
                            chosenFourIntersection
                        ]
                    )
                ]
            )


        // =====================================================
        // 6. Build five fully planned ALTERNATIVE routes
        // =====================================================

        let altOne =
            GameRoute(
                id:
                    RouteID(),
                stopNodeIDs: [
                    alternativeNodes[0].id,
                    chosenNodes[4].id
                ],
                entryLeg:
                    debugEntryLeg(
                        startIntersection:
                            boundary,
                        toNodeID:
                            alternativeNodes[0].id,
                        through: [
                            boundary,
                            .init(column: 6, row: 8),
                            altOneIntersection
                        ]
                    ),
                legs: [
                    debugLegEndingAtElevenFiftyNine(
                        from:
                            alternativeNodes[0].id,
                        to:
                            chosenNodes[4].id,
                        through: [
                            altOneIntersection,
                            .init(column: 6, row: 10),
                            .init(column: 5, row: 10),
                            .init(column: 4, row: 10),
                            .init(column: 4, row: 12),
                            .init(column: 5, row: 12),
                            .init(column: 5, row: 14),
                            .init(column: 4, row: 14),
                            chosenFourIntersection
                        ]
                    )
                ]
            )


        let altTwo =
            GameRoute(
                id:
                    RouteID(),
                stopNodeIDs: [
                    alternativeNodes[1].id,
                    chosenNodes[4].id
                ],
                entryLeg:
                    debugEntryLeg(
                        startIntersection:
                            boundary,
                        toNodeID:
                            alternativeNodes[1].id,
                        through: [
                            boundary,
                            .init(column: 5, row: 10),
                            .init(column: 3, row: 10),
                            altTwoIntersection
                        ]
                    ),
                legs: [
                    debugLegEndingAtElevenFiftyNine(
                        from:
                            alternativeNodes[1].id,
                        to:
                            chosenNodes[4].id,
                        through: [
                            altTwoIntersection,
                            .init(column: 3, row: 12),
                            .init(column: 4, row: 12),
                            .init(column: 5, row: 12),
                            .init(column: 5, row: 14),
                            .init(column: 4, row: 14),
                            chosenFourIntersection
                        ]
                    )
                ]
            )


        let altThree =
            GameRoute(
                id:
                    RouteID(),
                stopNodeIDs: [
                    alternativeNodes[2].id,
                    chosenNodes[4].id
                ],
                entryLeg:
                    debugEntryLeg(
                        startIntersection:
                            boundary,
                        toNodeID:
                            alternativeNodes[2].id,
                        through: [
                            boundary,
                            .init(column: 5, row: 10),
                            .init(column: 4, row: 10),
                            .init(column: 4, row: 12),
                            .init(column: 5, row: 12),
                            .init(column: 6, row: 12),
                            altThreeIntersection
                        ]
                    ),
                legs: [
                    debugLegEndingAtElevenFiftyNine(
                        from:
                            alternativeNodes[2].id,
                        to:
                            chosenNodes[4].id,
                        through: [
                            altThreeIntersection,
                            .init(column: 6, row: 14),
                            .init(column: 5, row: 14),
                            .init(column: 4, row: 14),
                            chosenFourIntersection
                        ]
                    )
                ]
            )


        let altFour =
            GameRoute(
                id:
                    RouteID(),
                stopNodeIDs: [
                    alternativeNodes[3].id,
                    chosenNodes[4].id
                ],
                entryLeg:
                    debugEntryLeg(
                        startIntersection:
                            boundary,
                        toNodeID:
                            alternativeNodes[3].id,
                        through: [
                            boundary,
                            .init(column: 5, row: 10),
                            .init(column: 4, row: 10),
                            .init(column: 4, row: 12),
                            .init(column: 5, row: 12),
                            .init(column: 5, row: 14),
                            .init(column: 3, row: 14),
                            altFourIntersection
                        ]
                    ),
                legs: [
                    debugLegEndingAtElevenFiftyNine(
                        from:
                            alternativeNodes[3].id,
                        to:
                            chosenNodes[4].id,
                        through: [
                            altFourIntersection,
                            chosenFourIntersection
                        ]
                    )
                ]
            )


        let altFive =
            GameRoute(
                id:
                    RouteID(),
                stopNodeIDs: [
                    alternativeNodes[4].id,
                    alternativeNodes[5].id,
                    chosenNodes[4].id
                ],
                entryLeg:
                    debugEntryLeg(
                        startIntersection:
                            boundary,
                        toNodeID:
                            alternativeNodes[4].id,
                        through: [
                            boundary,
                            .init(column: 7, row: 8),
                            altFiveOneIntersection
                        ]
                    ),
                legs: [
                    debugLeg(
                        from:
                            alternativeNodes[4].id,
                        to:
                            alternativeNodes[5].id,
                        through: [
                            altFiveOneIntersection,
                            .init(column: 7, row: 10),
                            .init(column: 5, row: 10),
                            .init(column: 5, row: 12),
                            .init(column: 7, row: 12),
                            altFiveTwoIntersection
                        ]
                    ),

                    debugLegEndingAtElevenFiftyNine(
                        from:
                            alternativeNodes[5].id,
                        to:
                            chosenNodes[4].id,
                        through: [
                            altFiveTwoIntersection,
                            .init(column: 7, row: 14),
                            .init(column: 4, row: 14),
                            chosenFourIntersection
                        ]
                    )
                ]
            )


        // =====================================================
        // 7. Publish the authoritative DEBUG route state
        // =====================================================

        let fixtureNodes =
            completedNodes
            + chosenNodes
            + alternativeNodes

        replaceGameNodesFromServer(
            baseGameNodes
            + fixtureNodes
        )

        let fullDayRouteState =
            DayRouteState(
                completedRoute:
                    CompletedRoute(
                        segments:
                            completedSegments,
                        reachedNodeIDs:
                            completedNodes.map(\.id),
                        throughTime:
                            DayTime(
                                secondsFromMidnight:
                                    12 * 3_600
                            ),
                        boundary:
                            .vertex(
                                GridRoadTopology.vertexID(
                                    for:
                                        boundary
                                )
                            )
                    ),
                chosenFutureRoute:
                    chosenRoute,
                alternativeRoutes: [
                    altOne,
                    altTwo,
                    altThree,
                    altFour,
                    altFive
                ],
                chosenFutureRouteActivatedAt:
                    DayTime(
                        secondsFromMidnight:
                            12 * 3_600
                    )
            )

        replaceRouteStateFromServer(
            fullDayRouteState
        )


        print("")
        print("==========================================")
        print("     FULL-DAY PATH + STOP TEST READY")
        print("==========================================")
        print("Path span: 12:00 AM → 11:59 PM")
        print("State split: 12:00 PM")
        print("Completed stops: \(completedNodes.count)")
        print("Chosen stops: \(chosenNodes.count)")
        print("Alternative paths: \(fullDayRouteState.alternativeRoutes.count)")
        print("Alternative-only stops: \(alternativeNodes.count)")
        print("Total fixture stops: \(completedNodes.count + chosenNodes.count + alternativeNodes.count)")
        print("Latest stop time: 11:59 PM")
        print("==========================================")
        print("")

        return true
    }


    // MARK: - Full-Day Fixture Nodes

    func makeFullDayFixtureNode(
        intersection: GridIntersectionID,
        title: String,
        routeRole: String,
        status: String = "Not Started"
    ) -> GameMapNode {

        let coordinate =
            GridRoadTopology.coordinate(
                for:
                    intersection
            )

        return GameMapNode(
            id:
                GameNodeID(),
            placement:
                .roadVertex(
                    GridRoadTopology.vertexID(
                        for:
                            intersection
                    )
                ),
            time:
                coordinate.time,
            content:
                .activity(
                    ActivityNodeContent(
                        activityID:
                            "debug-full-day-\(routeRole)-\(UUID().uuidString)",
                        title:
                            title,
                        startTime:
                            coordinate.time.displayClockString,
                        description:
                            "Full-day path testing fixture (\(routeRole)).",
                        activityType:
                            ActivityNodeContent.ActivityType.task.rawValue,
                        status:
                            status,
                        image:
                            nil
                    )
                ),
            isEnabled:
                true
        )
    }


    func makeFullDayFixtureNode(
        coordinate: MapCoordinate,
        title: String,
        routeRole: String,
        status: String = "Not Started"
    ) -> GameMapNode {

        GameMapNode(
            id:
                GameNodeID(),
            placement:
                .coordinate(
                    coordinate
                ),
            time:
                coordinate.time,
            content:
                .activity(
                    ActivityNodeContent(
                        activityID:
                            "debug-full-day-\(routeRole)-\(UUID().uuidString)",
                        title:
                            title,
                        startTime:
                            coordinate.time.displayClockString,
                        description:
                            "Full-day path testing fixture (\(routeRole)).",
                        activityType:
                            ActivityNodeContent.ActivityType.task.rawValue,
                        status:
                            status,
                        image:
                            nil
                    )
                ),
            isEnabled:
                true
        )
    }





    // MARK: - Full-Day Fixture Route Builders

    func debugEntryLeg(
        startIntersection: GridIntersectionID,
        toNodeID: GameNodeID,
        through points: [GridIntersectionID]
    ) -> GameRouteEntryLeg {

        let startLocation:
            GameNodeRouteAnchor.RoadLocation =
                .vertex(
                    GridRoadTopology.vertexID(
                        for:
                            startIntersection
                    )
                )

        let startAnchor =
            RoadRouteAnchor(
                coordinate:
                    GridRoadTopology.coordinate(
                        for:
                            startIntersection
                    ),
                roadLocation:
                    startLocation
            )

        return GameRouteEntryLeg(
            startAnchor:
                startAnchor,
            toNodeID:
                toNodeID,
            path:
                debugRoadRoutePath(
                    through:
                        points
                )
        )
    }


    func debugLeg(
        from fromNodeID: GameNodeID,
        to toNodeID: GameNodeID,
        through points: [GridIntersectionID]
    ) -> GameRouteLeg {

        GameRouteLeg(
            fromNodeID:
                fromNodeID,
            toNodeID:
                toNodeID,
            path:
                debugRoadRoutePath(
                    through:
                        points
                )
        )
    }


    func debugLegEndingAtElevenFiftyNine(
        from fromNodeID: GameNodeID,
        to toNodeID: GameNodeID,
        through points: [GridIntersectionID]
    ) -> GameRouteLeg {

        GameRouteLeg(
            fromNodeID:
                fromNodeID,
            toNodeID:
                toNodeID,
            path:
                debugRoadRoutePathEndingAtElevenFiftyNine(
                    through:
                        points
                )
        )
    }


    func debugRoadRoutePath(
        through points: [GridIntersectionID]
    ) -> RoadRoutePath? {

        guard
            let first = points.first,
            let last = points.last
        else {
            return nil
        }

        let segments =
            debugSegments(
                through:
                    points
            )

        return RoadRoutePath(
            startLocation:
                .vertex(
                    GridRoadTopology.vertexID(
                        for:
                            first
                    )
                ),
            endLocation:
                .vertex(
                    GridRoadTopology.vertexID(
                        for:
                            last
                    )
                ),
            vertexIDs:
                points.map {
                    GridRoadTopology.vertexID(
                        for:
                            $0
                    )
                },
            segments:
                segments,
            totalCost:
                debugRouteCost(
                    segments
                )
        )
    }


    func debugRoadRoutePathEndingAtElevenFiftyNine(
        through points: [GridIntersectionID]
    ) -> RoadRoutePath? {

        guard
            let first = points.first,
            let last = points.last,
            last.row == GridRoadTopology.maximumIntersectionRow - 1
        else {
            return nil
        }

        let segments =
            debugSegmentsEndingAtElevenFiftyNine(
                through:
                    points
            )

        return RoadRoutePath(
            startLocation:
                .vertex(
                    GridRoadTopology.vertexID(
                        for:
                            first
                    )
                ),
            endLocation:
                .edge(
                    edgeID:
                        GridRoadTopology.verticalEdgeID(
                            column:
                                last.column,
                            topRow:
                                last.row
                        ),
                    fraction:
                        debugEndOfDayEdgeFraction()
                ),
            vertexIDs:
                points.map {
                    GridRoadTopology.vertexID(
                        for:
                            $0
                    )
                },
            segments:
                segments,
            totalCost:
                debugRouteCost(
                    segments
                )
        )
    }


    func debugEndOfDayCoordinate(
        column: Int
    ) -> MapCoordinate {

        let progress =
            GridRoadTopology.coordinate(
                for:
                    GridIntersectionID(
                        column:
                            column,
                        row:
                            GridRoadTopology.maximumIntersectionRow - 1
                    )
            )
            .progress

        return MapCoordinate(
            time:
                DayTime(
                    secondsFromMidnight:
                        (23 * 3_600)
                        +
                        (59 * 60)
                ),
            progress:
                progress
        )
    }


    func debugEndOfDayEdgeFraction() -> Double {

        let finalTopRow =
            GridRoadTopology.maximumIntersectionRow - 1

        let targetSeconds =
            Double(
                (23 * 3_600)
                +
                (59 * 60)
            )

        let edgeStartSeconds =
            Double(finalTopRow)
            *
            GridRoadTopology.hoursPerPitch
            *
            3_600.0

        let edgeDurationSeconds =
            GridRoadTopology.hoursPerPitch
            *
            3_600.0

        return min(
            max(
                (targetSeconds - edgeStartSeconds)
                /
                edgeDurationSeconds,
                0
            ),
            1
        )
    }


    func debugRouteCost(
        _ segments: [RoadRouteSegment]
    ) -> Double {

        segments.reduce(0) {
            $0
            +
            $1.traversedFraction
        }
    }


    /// Adds the final partial vertical segment so the render ends at exactly
    /// 11:59 PM rather than at the mathematical 24:00 boundary.
    ///
    /// With the current four-islands-per-six-hours grid, row 15 is 10:30 PM
    /// and row 16 is 12:00 AM of the next day. 11:59 PM is therefore 89/90
    /// of the way down the final 90-minute road edge.
    func debugSegmentsEndingAtElevenFiftyNine(
        through points: [GridIntersectionID]
    ) -> [RoadRouteSegment] {

        guard let last = points.last else {
            return []
        }

        let finalTopRow =
            GridRoadTopology.maximumIntersectionRow - 1

        guard
            last.row == finalTopRow
        else {

            assertionFailure(
                "Full-day debug path must reach the final 10:30 PM row before its 11:59 PM partial edge."
            )

            return debugSegments(
                through:
                    points
            )
        }

        var result =
            debugSegments(
                through:
                    points
            )


        let targetSeconds =
            Double(
                (23 * 3_600)
                +
                (59 * 60)
            )

        let edgeStartSeconds =
            Double(finalTopRow)
            *
            GridRoadTopology.hoursPerPitch
            *
            3_600.0

        let edgeDurationSeconds =
            GridRoadTopology.hoursPerPitch
            *
            3_600.0

        let finalFraction =
            min(
                max(
                    (targetSeconds - edgeStartSeconds)
                    /
                    edgeDurationSeconds,
                    0
                ),
                1
            )


        result.append(
            RoadRouteSegment(
                edgeID:
                    GridRoadTopology.verticalEdgeID(
                        column:
                            last.column,
                        topRow:
                            last.row
                    ),
                fromFraction:
                    0,
                toFraction:
                    finalFraction
            )
        )

        return result
    }
}


// =====================================================
// MARK: - Deterministic Alternative Render Fixtures
// =====================================================

@MainActor
private extension GameStore {

    func makeDebugAlternativeRenderPaths(
        for preset: DebugRouteRenderPreset
    ) -> [RouteRenderPath] {

        switch preset {

        case .fullDayAllStates:
            // This preset uses a complete RouteRenderState override and never
            // reaches this render-only-alternatives helper.
            return []

        case .completedOnly:
            return []


        case .lateMixed:

            // At 3:15 PM, keep both alternatives entirely in the future
            // between the 3:00 PM and 4:30 PM street rows.
            return [

                debugRenderPath(
                    points: [
                        .init(column: 3, row: 10),
                        .init(column: 3, row: 11),
                        .init(column: 7, row: 11)
                    ]
                ),

                debugRenderPath(
                    points: [
                        .init(column: 3, row: 10),
                        .init(column: 5, row: 10),
                        .init(column: 5, row: 11),
                        .init(column: 7, row: 11)
                    ]
                )
            ]


        case .futureOnly,
             .earlyMixed,
             .balancedMixed:

            // Two intentionally different legal LEFT/RIGHT/DOWN paths.
            // Both begin at the 1:30 PM Work Session intersection and end
            // at the 4:30 PM Dinner intersection, passing the 3:00 PM stop.
            // They are far enough apart to make renderer differences obvious.
            return [

                debugRenderPath(
                    points: [
                        .init(column: 8, row: 9),
                        .init(column: 8, row: 10),
                        .init(column: 3, row: 10),
                        .init(column: 3, row: 11),
                        .init(column: 7, row: 11)
                    ]
                ),

                debugRenderPath(
                    points: [
                        .init(column: 8, row: 9),
                        .init(column: 5, row: 9),
                        .init(column: 5, row: 10),
                        .init(column: 3, row: 10),
                        .init(column: 3, row: 11),
                        .init(column: 7, row: 11)
                    ]
                )
            ]
        }
    }


    func debugRenderPath(
        points: [GridIntersectionID]
    ) -> RouteRenderPath {

        RouteRenderPath(
            routeID:
                RouteID(),
            segments:
                debugSegments(
                    through:
                        points
                )
        )
    }


    func debugSegments(
        through points: [GridIntersectionID]
    ) -> [RoadRouteSegment] {

        guard points.count >= 2 else {
            return []
        }


        var result:
            [RoadRouteSegment] = []


        for (start, end) in
            zip(
                points,
                points.dropFirst()
            ) {

            result.append(
                contentsOf:
                    debugSegments(
                        from:
                            start,
                        to:
                            end
                    )
            )
        }


        return result
    }


    func debugSegments(
        from start: GridIntersectionID,
        to end: GridIntersectionID
    ) -> [RoadRouteSegment] {

        // =================================================
        // Horizontal run
        // =================================================

        if start.row == end.row {

            if start.column < end.column {

                return (start.column..<end.column)
                    .map { leftColumn in

                        RoadRouteSegment(
                            edgeID:
                                GridRoadTopology
                                    .horizontalEdgeID(
                                        row:
                                            start.row,
                                        leftColumn:
                                            leftColumn
                                    ),
                            fromFraction:
                                0,
                            toFraction:
                                1
                        )
                    }
            }


            if start.column > end.column {

                return stride(
                    from:
                        start.column,
                    to:
                        end.column,
                    by:
                        -1
                )
                .map { rightColumn in

                    RoadRouteSegment(
                        edgeID:
                            GridRoadTopology
                                .horizontalEdgeID(
                                    row:
                                        start.row,
                                    leftColumn:
                                        rightColumn - 1
                                ),
                        fromFraction:
                            1,
                        toFraction:
                            0
                    )
                }
            }


            return []
        }


        // =================================================
        // Downward vertical run
        // =================================================

        if
            start.column == end.column,
            start.row < end.row
        {

            return (start.row..<end.row)
                .map { topRow in

                    RoadRouteSegment(
                        edgeID:
                            GridRoadTopology
                                .verticalEdgeID(
                                    column:
                                        start.column,
                                    topRow:
                                        topRow
                                ),
                        fromFraction:
                            0,
                        toFraction:
                            1
                    )
                }
        }


        assertionFailure(
            "Debug path fixture requires horizontal or downward segments only."
        )

        return []
    }
}

#endif
