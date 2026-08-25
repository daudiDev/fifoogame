//
//  DebugRouteRenderDemo.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/23/26.
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
    /// These two paths are only used by `routeRenderState` in DEBUG builds;
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
                    "❌ Could not install route-render demo nodes."
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
                "❌ Route-render demo failed to create a chosen route."
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
                "❌ Route-render demo could not advance to \(preset.title)."
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
        print("        ROUTE RENDER DEMO READY")
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
    /// as Chosen. Two alternative futures also begin at noon and continue to
    /// 11:59 PM. Horizontal movement is intentionally narrow so the visual
    /// reads as a DAY route first, not a wide cross-map route.
    @discardableResult
    func installFullDayRouteRenderDemo() -> Bool {

        // Keep the current-time line exactly at the Completed / Chosen split.
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


        // -------------------------------------------------
        // COMPLETED: 12:00 AM → 12:00 PM
        // -------------------------------------------------
        //
        // Uses only columns 3...5. With the current grid that is a maximum
        // horizontal spread of 25 progress points while covering 12 hours.
        // The last segment approaches the noon boundary from the LEFT so the
        // Completed → Chosen transition exercises a curved state-color turn.

        let completedPoints: [GridIntersectionID] = [
            .init(column: 4, row: 0),   // 12:00 AM
            .init(column: 4, row: 2),   //  3:00 AM
            .init(column: 3, row: 2),
            .init(column: 3, row: 4),   //  6:00 AM
            .init(column: 4, row: 4),
            .init(column: 4, row: 6),   //  9:00 AM
            .init(column: 4, row: 8),   // 12:00 PM
            .init(column: 5, row: 8)    // noon state boundary
        ]

        let completedSegments =
            debugSegments(
                through:
                    completedPoints
            )


        // -------------------------------------------------
        // CHOSEN: 12:00 PM → 11:59 PM
        // -------------------------------------------------

        let chosenPoints: [GridIntersectionID] = [
            .init(column: 5, row: 8),   // 12:00 PM
            .init(column: 5, row: 10),  //  3:00 PM
            .init(column: 4, row: 10),
            .init(column: 4, row: 12),  //  6:00 PM
            .init(column: 5, row: 12),
            .init(column: 5, row: 14),  //  9:00 PM
            .init(column: 4, row: 14),
            .init(column: 4, row: 15)   // 10:30 PM
        ]

        let chosenSegments =
            debugSegmentsEndingAtElevenFiftyNine(
                through:
                    chosenPoints
            )


        // -------------------------------------------------
        // ALTERNATIVE 1: noon → 11:59 PM
        // -------------------------------------------------
        // Slightly to the RIGHT of the chosen route, but still deliberately
        // narrow compared with the 2,000-point vertical day axis.

        let alternativeOnePoints: [GridIntersectionID] = [
            .init(column: 5, row: 8),
            .init(column: 6, row: 8),
            .init(column: 6, row: 10),
            .init(column: 5, row: 10),
            .init(column: 5, row: 12),
            .init(column: 6, row: 12),
            .init(column: 6, row: 14),
            .init(column: 4, row: 14),
            .init(column: 4, row: 15)
        ]

        let alternativeOneSegments =
            debugSegmentsEndingAtElevenFiftyNine(
                through:
                    alternativeOnePoints
            )


        // -------------------------------------------------
        // ALTERNATIVE 2: noon → 11:59 PM
        // -------------------------------------------------
        // Diverges to the LEFT, making both alternatives easy to distinguish
        // from the chosen route without creating a horizontally dominant map.

        let alternativeTwoPoints: [GridIntersectionID] = [
            .init(column: 5, row: 8),
            .init(column: 4, row: 8),
            .init(column: 4, row: 10),
            .init(column: 3, row: 10),
            .init(column: 3, row: 12),
            .init(column: 4, row: 12),
            .init(column: 4, row: 14),
            .init(column: 4, row: 15)
        ]

        let alternativeTwoSegments =
            debugSegmentsEndingAtElevenFiftyNine(
                through:
                    alternativeTwoPoints
            )


        let boundaryIntersection =
            GridIntersectionID(
                column: 5,
                row: 8
            )

        let state =
            RouteRenderState(
                completedSegments:
                    completedSegments,
                chosenFuture:
                    RouteRenderPath(
                        routeID:
                            RouteID(),
                        segments:
                            chosenSegments
                    ),
                alternatives: [
                    RouteRenderPath(
                        routeID:
                            RouteID(),
                        segments:
                            alternativeOneSegments
                    ),
                    RouteRenderPath(
                        routeID:
                            RouteID(),
                        segments:
                            alternativeTwoSegments
                    )
                ],
                currentBoundary:
                    .vertex(
                        GridRoadTopology.vertexID(
                            for:
                                boundaryIntersection
                        )
                    )
            )

        debugRouteRenderStateOverride =
            state


        print("")
        print("==========================================")
        print("       FULL-DAY ROUTE DEMO READY")
        print("==========================================")
        print("Route span: 12:00 AM → 11:59 PM")
        print("State split: 12:00 PM")
        print("Completed segments: \(completedSegments.count)")
        print("Chosen segments: \(chosenSegments.count)")
        print("Alternatives visible: \(state.alternatives.count)")
        print("Grid rows covered: 0 → 15 + 89/90 of final edge")
        print("Primary columns used: 3...5")
        print("Alternative columns used: 3...6")
        print("==========================================")
        print("")

        return true
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
                "Full-day debug route must reach the final 10:30 PM row before its 11:59 PM partial edge."
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
            "Debug route fixture requires horizontal or downward segments only."
        )

        return []
    }
}

#endif
