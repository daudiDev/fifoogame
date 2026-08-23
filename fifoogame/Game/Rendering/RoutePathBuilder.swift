//
//  RoutePathBuilder.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/22/26.
//


import Foundation
import CoreGraphics


/// Builds the VISUAL centerline for a route without changing its logical
/// road traversal.
///
/// Step 5 deliberately keeps route topology orthogonal: LEFT / RIGHT / DOWN.
/// This builder leaves that topology untouched and only rounds the visible
/// 90-degree turns at road intersections.
enum RoutePathBuilder {

    struct Configuration: Sendable {

        let cornerRadius: CGFloat
        let maximumCornerTrimFraction: CGFloat
        let pointMergeTolerance: CGFloat


        static var dayMap: Configuration {

            Configuration(
                cornerRadius:
                    RouteVisualTheme.cornerRadius,
                maximumCornerTrimFraction:
                    RouteVisualTheme.maximumCornerTrimFraction,
                pointMergeTolerance:
                    0.5
            )
        }
    }


    /// A pair of paths used when the Completed route changes into the Chosen
    /// route exactly at a turning intersection. The quadratic turn is split
    /// at its midpoint so the two colors share one smooth centerline instead
    /// of drawing a sharp L at the state boundary.
    struct BoundaryTransitionPaths {

        let completedPath: CGPath
        let chosenPath: CGPath
    }


    // =====================================================
    // MARK: - Normal Route Path
    // =====================================================

    static func makePath(
        for segments: [RoadRouteSegment],
        graph: RoadGraph,
        configuration: Configuration = .dayMap
    ) -> CGPath? {

        let components =
            polylineComponents(
                for: segments,
                graph: graph,
                configuration: configuration
            )

        guard !components.isEmpty else {
            return nil
        }

        let path = CGMutablePath()

        for component in components {

            appendSmoothedPolyline(
                component,
                to: path,
                configuration: configuration,
                moveToStart: true
            )
        }

        return path
    }


    // =====================================================
    // MARK: - Completed -> Chosen Boundary Turn
    // =====================================================

    static func makeBoundaryTransitionPaths(
        completedSegments: [RoadRouteSegment],
        chosenSegments: [RoadRouteSegment],
        graph: RoadGraph,
        configuration: Configuration = .dayMap
    ) -> BoundaryTransitionPaths? {

        let completedComponents =
            polylineComponents(
                for: completedSegments,
                graph: graph,
                configuration: configuration
            )

        let chosenComponents =
            polylineComponents(
                for: chosenSegments,
                graph: graph,
                configuration: configuration
            )

        // A state boundary is meaningful only when both sides are one
        // continuous route component.
        guard
            completedComponents.count == 1,
            chosenComponents.count == 1
        else {
            return nil
        }

        let completedPoints = completedComponents[0]
        let chosenPoints = chosenComponents[0]

        guard
            completedPoints.count >= 2,
            chosenPoints.count >= 2,
            let boundary = completedPoints.last,
            nearlyEqual(
                boundary,
                chosenPoints[0],
                tolerance: configuration.pointMergeTolerance
            )
        else {
            return nil
        }

        let incomingPoint =
            completedPoints[
                completedPoints.count - 2
            ]

        let outgoingPoint =
            chosenPoints[1]

        let incoming =
            vector(
                from: incomingPoint,
                to: boundary
            )

        let outgoing =
            vector(
                from: boundary,
                to: outgoingPoint
            )

        guard
            isTurn(
                incoming: incoming,
                outgoing: outgoing
            )
        else {
            // Straight state transitions already line up perfectly and do
            // not need special geometry.
            return nil
        }

        let incomingLength = length(incoming)
        let outgoingLength = length(outgoing)

        guard
            incomingLength > 0.001,
            outgoingLength > 0.001
        else {
            return nil
        }

        let trim =
            min(
                configuration.cornerRadius,
                incomingLength
                    * configuration.maximumCornerTrimFraction,
                outgoingLength
                    * configuration.maximumCornerTrimFraction
            )

        guard trim > 0.001 else {
            return nil
        }

        let incomingUnit = normalized(incoming)
        let outgoingUnit = normalized(outgoing)

        let entry = CGPoint(
            x: boundary.x - incomingUnit.dx * trim,
            y: boundary.y - incomingUnit.dy * trim
        )

        let exit = CGPoint(
            x: boundary.x + outgoingUnit.dx * trim,
            y: boundary.y + outgoingUnit.dy * trim
        )

        // De Casteljau split at t = 0.5 for the quadratic:
        // entry -> (control: boundary) -> exit
        let firstControl = midpoint(entry, boundary)
        let secondControl = midpoint(boundary, exit)
        let curveMidpoint = midpoint(firstControl, secondControl)


        // =============================================
        // Completed half
        // =============================================

        var completedTrimmed = completedPoints
        completedTrimmed[completedTrimmed.count - 1] = entry

        let completedPath = CGMutablePath()

        appendSmoothedPolyline(
            completedTrimmed,
            to: completedPath,
            configuration: configuration,
            moveToStart: true
        )

        completedPath.addQuadCurve(
            to: curveMidpoint,
            control: firstControl
        )


        // =============================================
        // Chosen half
        // =============================================

        let chosenPath = CGMutablePath()

        chosenPath.move(
            to: curveMidpoint
        )

        chosenPath.addQuadCurve(
            to: exit,
            control: secondControl
        )

        let chosenTrimmed =
            [exit]
            + Array(
                chosenPoints.dropFirst()
            )

        appendSmoothedPolyline(
            chosenTrimmed,
            to: chosenPath,
            configuration: configuration,
            moveToStart: false
        )


        return BoundaryTransitionPaths(
            completedPath: completedPath,
            chosenPath: chosenPath
        )
    }
}


// =====================================================
// MARK: - Ordered Logical Centerline
// =====================================================

private extension RoutePathBuilder {

    static func polylineComponents(
        for segments: [RoadRouteSegment],
        graph: RoadGraph,
        configuration: Configuration
    ) -> [[CGPoint]] {

        guard !segments.isEmpty else {
            return []
        }

        var rawComponents: [[CGPoint]] = []
        var current: [CGPoint] = []

        for segment in segments {

            guard
                let edge = graph.edge(id: segment.edgeID),
                let start = RoadEdgeGeometry.point(
                    atFraction: segment.fromFraction,
                    on: edge,
                    graph: graph
                ),
                let end = RoadEdgeGeometry.point(
                    atFraction: segment.toFraction,
                    on: edge,
                    graph: graph
                )
            else {
                continue
            }

            let startPoint = start.cgPoint
            let endPoint = end.cgPoint

            guard
                distance(startPoint, endPoint)
                    > configuration.pointMergeTolerance
            else {
                continue
            }

            if current.isEmpty {

                current = [
                    startPoint,
                    endPoint
                ]

                continue
            }

            if let last = current.last,
               nearlyEqual(
                    last,
                    startPoint,
                    tolerance: configuration.pointMergeTolerance
               )
            {
                current.append(endPoint)

            } else {

                let simplified =
                    simplify(
                        current,
                        tolerance: configuration.pointMergeTolerance
                    )

                if simplified.count >= 2 {
                    rawComponents.append(simplified)
                }

                current = [
                    startPoint,
                    endPoint
                ]
            }
        }

        let simplified =
            simplify(
                current,
                tolerance: configuration.pointMergeTolerance
            )

        if simplified.count >= 2 {
            rawComponents.append(simplified)
        }

        return rawComponents
    }
}


// =====================================================
// MARK: - Rounded Orthogonal Geometry
// =====================================================

private extension RoutePathBuilder {

    static func appendSmoothedPolyline(
        _ points: [CGPoint],
        to path: CGMutablePath,
        configuration: Configuration,
        moveToStart: Bool
    ) {

        guard let first = points.first else {
            return
        }

        if moveToStart {
            path.move(to: first)
        }

        guard points.count >= 2 else {
            return
        }

        if points.count == 2 {

            path.addLine(
                to: points[1]
            )

            return
        }

        for index in 1 ..< points.count - 1 {

            let previous = points[index - 1]
            let corner = points[index]
            let next = points[index + 1]

            let incoming = vector(
                from: previous,
                to: corner
            )

            let outgoing = vector(
                from: corner,
                to: next
            )

            guard
                isTurn(
                    incoming: incoming,
                    outgoing: outgoing
                )
            else {

                path.addLine(
                    to: corner
                )

                continue
            }

            let incomingLength = length(incoming)
            let outgoingLength = length(outgoing)

            let trim =
                min(
                    configuration.cornerRadius,
                    incomingLength
                        * configuration.maximumCornerTrimFraction,
                    outgoingLength
                        * configuration.maximumCornerTrimFraction
                )

            guard trim > 0.001 else {

                path.addLine(
                    to: corner
                )

                continue
            }

            let incomingUnit = normalized(incoming)
            let outgoingUnit = normalized(outgoing)

            let entry = CGPoint(
                x: corner.x - incomingUnit.dx * trim,
                y: corner.y - incomingUnit.dy * trim
            )

            let exit = CGPoint(
                x: corner.x + outgoingUnit.dx * trim,
                y: corner.y + outgoingUnit.dy * trim
            )

            path.addLine(
                to: entry
            )

            path.addQuadCurve(
                to: exit,
                control: corner
            )
        }

        if let last = points.last {

            path.addLine(
                to: last
            )
        }
    }
}




// =====================================================
// MARK: - Visual Hit Testing
// =====================================================

extension RoutePathBuilder {

    /// Returns the minimum distance from a world-space point to the exact
    /// visual centerline produced by this builder.
    ///
    /// Step 7 uses this for route hit testing so taps follow the rounded
    /// vehicle-like corners instead of the old sharp logical L-shapes.
    static func minimumVisualDistance(
        from point: CGPoint,
        to segments: [RoadRouteSegment],
        graph: RoadGraph,
        configuration: Configuration = .dayMap
    ) -> CGFloat? {

        guard let path =
            makePath(
                for: segments,
                graph: graph,
                configuration: configuration
            )
        else {
            return nil
        }

        return minimumVisualDistance(
            from: point,
            to: path
        )
    }


    /// Same measurement for an already-built path. This is important at the
    /// Completed -> Chosen boundary where Step 6 may split one rounded corner
    /// into two color/state paths.
    static func minimumVisualDistance(
        from point: CGPoint,
        to path: CGPath,
        curveSampleCount: Int = 14
    ) -> CGFloat? {

        let samplesPerCurve =
            max(
                4,
                curveSampleCount
            )

        var currentPoint: CGPoint?
        var subpathStart: CGPoint?
        var bestDistance = CGFloat.greatestFiniteMagnitude

        func considerLine(
            from start: CGPoint,
            to end: CGPoint
        ) {

            bestDistance =
                min(
                    bestDistance,
                    distanceFromPoint(
                        point,
                        toLineSegmentFrom: start,
                        to: end
                    )
                )
        }

        path.applyWithBlock { elementPointer in

            let element = elementPointer.pointee

            switch element.type {

            case .moveToPoint:

                let destination = element.points[0]
                currentPoint = destination
                subpathStart = destination


            case .addLineToPoint:

                let destination = element.points[0]

                if let start = currentPoint {
                    considerLine(
                        from: start,
                        to: destination
                    )
                }

                currentPoint = destination


            case .addQuadCurveToPoint:

                guard let start = currentPoint else {
                    return
                }

                let control = element.points[0]
                let destination = element.points[1]

                var previous = start

                for index in 1 ... samplesPerCurve {

                    let t =
                        CGFloat(index)
                        / CGFloat(samplesPerCurve)

                    let oneMinusT = 1 - t

                    let sample = CGPoint(
                        x:
                            oneMinusT * oneMinusT * start.x
                            + 2 * oneMinusT * t * control.x
                            + t * t * destination.x,
                        y:
                            oneMinusT * oneMinusT * start.y
                            + 2 * oneMinusT * t * control.y
                            + t * t * destination.y
                    )

                    considerLine(
                        from: previous,
                        to: sample
                    )

                    previous = sample
                }

                currentPoint = destination


            case .addCurveToPoint:

                guard let start = currentPoint else {
                    return
                }

                let control1 = element.points[0]
                let control2 = element.points[1]
                let destination = element.points[2]

                var previous = start

                for index in 1 ... samplesPerCurve {

                    let t =
                        CGFloat(index)
                        / CGFloat(samplesPerCurve)

                    let oneMinusT = 1 - t

                    let sample = CGPoint(
                        x:
                            oneMinusT * oneMinusT * oneMinusT * start.x
                            + 3 * oneMinusT * oneMinusT * t * control1.x
                            + 3 * oneMinusT * t * t * control2.x
                            + t * t * t * destination.x,
                        y:
                            oneMinusT * oneMinusT * oneMinusT * start.y
                            + 3 * oneMinusT * oneMinusT * t * control1.y
                            + 3 * oneMinusT * t * t * control2.y
                            + t * t * t * destination.y
                    )

                    considerLine(
                        from: previous,
                        to: sample
                    )

                    previous = sample
                }

                currentPoint = destination


            case .closeSubpath:

                if
                    let start = currentPoint,
                    let end = subpathStart
                {
                    considerLine(
                        from: start,
                        to: end
                    )

                    currentPoint = end
                }


            @unknown default:
                break
            }
        }

        guard
            bestDistance !=
                .greatestFiniteMagnitude
        else {
            return nil
        }

        return bestDistance
    }
}


private extension RoutePathBuilder {

    static func distanceFromPoint(
        _ point: CGPoint,
        toLineSegmentFrom start: CGPoint,
        to end: CGPoint
    ) -> CGFloat {

        let dx = end.x - start.x
        let dy = end.y - start.y

        let lengthSquared =
            dx * dx
            + dy * dy

        guard lengthSquared > 0.000_001 else {
            return hypot(
                point.x - start.x,
                point.y - start.y
            )
        }

        let rawT =
            (
                (point.x - start.x) * dx
                + (point.y - start.y) * dy
            )
            / lengthSquared

        let t =
            min(
                max(
                    rawT,
                    0
                ),
                1
            )

        let projection = CGPoint(
            x: start.x + t * dx,
            y: start.y + t * dy
        )

        return hypot(
            point.x - projection.x,
            point.y - projection.y
        )
    }
}


// =====================================================
// MARK: - Point Simplification
// =====================================================

private extension RoutePathBuilder {

    static func simplify(
        _ points: [CGPoint],
        tolerance: CGFloat
    ) -> [CGPoint] {

        guard !points.isEmpty else {
            return []
        }

        // Remove duplicate adjacent points first.
        var deduplicated: [CGPoint] = []
        deduplicated.reserveCapacity(points.count)

        for point in points {

            if let last = deduplicated.last,
               nearlyEqual(
                    last,
                    point,
                    tolerance: tolerance
               )
            {
                continue
            }

            deduplicated.append(point)
        }

        guard deduplicated.count >= 3 else {
            return deduplicated
        }

        // Collapse only FORWARD collinear runs. A theoretical reversal is
        // intentionally retained so malformed legacy data stays visible
        // rather than silently changing its traversal.
        var result: [CGPoint] = []
        result.reserveCapacity(deduplicated.count)

        for point in deduplicated {

            while result.count >= 2 {

                let a = result[result.count - 2]
                let b = result[result.count - 1]

                if isForwardCollinear(
                    a,
                    b,
                    point
                ) {
                    result.removeLast()
                } else {
                    break
                }
            }

            result.append(point)
        }

        return result
    }


    static func isForwardCollinear(
        _ a: CGPoint,
        _ b: CGPoint,
        _ c: CGPoint
    ) -> Bool {

        let first = vector(from: a, to: b)
        let second = vector(from: b, to: c)

        let firstLength = length(first)
        let secondLength = length(second)

        guard
            firstLength > 0.001,
            secondLength > 0.001
        else {
            return true
        }

        let cross =
            first.dx * second.dy
            - first.dy * second.dx

        let normalizedCross =
            abs(cross)
            / (firstLength * secondLength)

        let dot =
            first.dx * second.dx
            + first.dy * second.dy

        return
            normalizedCross < 0.001
            && dot > 0
    }
}


// =====================================================
// MARK: - Vector Helpers
// =====================================================

private extension RoutePathBuilder {

    static func vector(
        from start: CGPoint,
        to end: CGPoint
    ) -> CGVector {

        CGVector(
            dx: end.x - start.x,
            dy: end.y - start.y
        )
    }


    static func length(
        _ vector: CGVector
    ) -> CGFloat {

        hypot(
            vector.dx,
            vector.dy
        )
    }


    static func normalized(
        _ vector: CGVector
    ) -> CGVector {

        let magnitude = length(vector)

        guard magnitude > 0 else {
            return .zero
        }

        return CGVector(
            dx: vector.dx / magnitude,
            dy: vector.dy / magnitude
        )
    }


    static func isTurn(
        incoming: CGVector,
        outgoing: CGVector
    ) -> Bool {

        let incomingLength = length(incoming)
        let outgoingLength = length(outgoing)

        guard
            incomingLength > 0.001,
            outgoingLength > 0.001
        else {
            return false
        }

        let cross =
            incoming.dx * outgoing.dy
            - incoming.dy * outgoing.dx

        let normalizedCross =
            abs(cross)
            / (incomingLength * outgoingLength)

        return normalizedCross > 0.01
    }


    static func distance(
        _ lhs: CGPoint,
        _ rhs: CGPoint
    ) -> CGFloat {

        hypot(
            lhs.x - rhs.x,
            lhs.y - rhs.y
        )
    }


    static func nearlyEqual(
        _ lhs: CGPoint,
        _ rhs: CGPoint,
        tolerance: CGFloat
    ) -> Bool {

        distance(lhs, rhs) <= tolerance
    }


    static func midpoint(
        _ lhs: CGPoint,
        _ rhs: CGPoint
    ) -> CGPoint {

        CGPoint(
            x: (lhs.x + rhs.x) / 2,
            y: (lhs.y + rhs.y) / 2
        )
    }
}
