//
//  FutureRouteBuilderView.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/19/26.
//



import SwiftUI


struct FutureRouteBuilderView: View {

    // =====================================================
    // MARK: - Dependencies
    // =====================================================

    @ObservedObject
    var store:
        GameStore


    // =====================================================
    // MARK: - Environment
    // =====================================================

    @Environment(\.dismiss)
    private var dismiss


    // =====================================================
    // MARK: - State
    // =====================================================

    @State
    private var searchText =
        ""

    @State
    private var planningFailed =
        false
    
    @State
    private var isShowingPreview =
        false

    // =====================================================
    // MARK: - Body
    // =====================================================

    var body: some View {

        NavigationStack {

            List {

                routeSummarySection

                selectedStopsSection

                availableStopsSection

                validationSection
            }
            .navigationTitle(
                builderTitle
            )
            .navigationBarTitleDisplayMode(
                .inline
            )
            .alert(
                "Route Could Not Be Planned",
                isPresented:
                    $planningFailed
            ) {

                Button(
                    "OK",
                    role:
                        .cancel
                ) { }

            } message: {

                Text(
                    planningFailureMessage
                )
            }
            .searchable(
                text:
                    $searchText,
                placement:
                    .navigationBarDrawer(
                        displayMode:
                            .always
                    ),
                prompt:
                    "Search route stops"
            )
            .toolbar {

                routeBuilderToolbar
            }
            .navigationDestination(
                isPresented:
                    $isShowingPreview
            ) {

                FutureRoutePreviewView(
                    store:
                        store,
                    onCommit: {

                        dismiss()
                    },
                    onCancel: {

                        store.clearFutureRoutePreview()

                        isShowingPreview =
                            false
                    }
                )
            }
        }
    }
}


// =====================================================
// MARK: - Summary
// =====================================================

private extension FutureRouteBuilderView {

    var routeSummarySection:
        some View {

        Section {

            HStack {

                VStack(
                    alignment:
                        .leading,
                    spacing:
                        4
                ) {

                    Text(
                        "Future Route"
                    )
                    .font(
                        .headline
                    )


                    Text(
                        routeSummaryText
                    )
                    .font(
                        .subheadline
                    )
                    .foregroundStyle(
                        .secondary
                    )
                }


                Spacer()


                Text(
                    "\(store.futureRouteDraft.stopCount)"
                )
                .font(
                    .title2
                )
                .fontWeight(
                    .semibold
                )
            }

        } header: {

            Text(
                "Route Draft"
            )
            
            if let plan =
                store.futureRouteDraftPlan,
               plan.succeeded
            {

                Divider()


                HStack {

                    Label(
                        routeStartDescription(
                            plan.start
                        ),
                        systemImage:
                            "location.fill"
                    )


                    Spacer()


                    Image(
                        systemName:
                            "checkmark.circle.fill"
                    )
                    .foregroundStyle(
                        .green
                    )
                }
            }
            
            if
                store
                    .futureRouteDraft
                    .isEditingExistingRoute
            {

                Divider()


                Label(
                    "Your current route remains active until you confirm a replacement.",
                    systemImage:
                        "pencil.and.list.clipboard"
                )
                .font(
                    .caption
                )
                .foregroundStyle(
                    .secondary
                )
            }
            
        }
            
            
    }
    


    var routeSummaryText:
        String {

        let count =
            store.futureRouteDraft
                .stopCount


        switch count {

        case 0:

            return "Choose at least two future stops."


        case 1:

            return "Choose one more stop to create a route."


        default:

            return "\(count) stops selected."
        }
    }
    
    
}

// =====================================================
// MARK: - Selected Stops
// =====================================================

private extension FutureRouteBuilderView {

    @ViewBuilder
    var selectedStopsSection:
        some View {

        Section {

            if
                store
                    .futureRouteDraft
                    .stopNodeIDs
                    .isEmpty
            {

                ContentUnavailableView(
                    "No Stops Selected",
                    systemImage:
                        "point.topleft.down.to.point.bottomright.curvepath",
                    description:
                        Text(
                            "Add future map nodes below to build your route."
                        )
                )

            } else {

                selectedStopsList
                
                if store.futureRouteDraft.stopCount == 0 {

                    Text(
                        "Choose two or more future road-connected nodes."
                    )
                    .font(
                        .caption
                    )
                    .foregroundStyle(
                        .secondary
                    )

                } else if store.futureRouteDraft.stopCount == 1 {

                    Text(
                        "Choose one more stop to plan the route."
                    )
                    .font(
                        .caption
                    )
                    .foregroundStyle(
                        .secondary
                    )
                }
                
            }

        } header: {

            selectedStopsHeader

        } footer: {

            selectedStopsFooter
        }
    }
}

private extension FutureRouteBuilderView {

    var selectedStopsList:
        some View {

        ForEach(
            store
                .futureRouteDraft
                .stopNodeIDs,
            id:
                \.self
        ) { nodeID in

            let index =
                store
                    .futureRouteDraft
                    .stopNodeIDs
                    .firstIndex(
                        of:
                            nodeID
                    )
                ??
                0


            selectedStopRow(
                nodeID:
                    nodeID,
                index:
                    index
            )
        }

        // =============================================
        // Native drag-to-reorder
        // =============================================

        .onMove(
            perform:
                moveSelectedStops
        )


        // =============================================
        // Native swipe-to-delete
        // =============================================

        .onDelete(
            perform:
                deleteSelectedStops
        )
    }
}

private extension FutureRouteBuilderView {

    func moveSelectedStops(
        fromOffsets offsets:
            IndexSet,
        toOffset destination:
            Int
    ) {

        let sourceIndices =
            offsets.map {
                $0
            }


        let succeeded =
            store
                .moveFutureRouteDraftStops(
                    fromIndices:
                        sourceIndices,
                    toOffset:
                        destination
                )


        if !succeeded {

            print(
                "❌ Unable to reorder route draft stops."
            )
        }
    }
}

private extension FutureRouteBuilderView {

    func deleteSelectedStops(
        at offsets:
            IndexSet
    ) {

        /*
         Delete backwards so removing one index
         doesn't shift the remaining indices.
        */

        let indices =
            offsets
                .sorted(
                    by:
                        >
                )


        for index in
            indices {

            let nodeIDs =
                store
                    .futureRouteDraft
                    .stopNodeIDs


            guard
                nodeIDs.indices
                    .contains(
                        index
                    )
            else {

                continue
            }


            let nodeID =
                nodeIDs[index]


            store
                .removeStopFromFutureRouteDraft(
                    nodeID:
                        nodeID
                )
        }
    }
}

private extension FutureRouteBuilderView {

    var selectedStopsHeader:
        some View {

        HStack {

            Text(
                "Selected Stops"
            )


            Spacer()


            if
                !store
                    .futureRouteDraft
                    .isEmpty
            {

                Text(
                    "\(store.futureRouteDraft.stopCount)"
                )
                .foregroundStyle(
                    .secondary
                )
            }
        }
    }
}

private extension FutureRouteBuilderView {

    @ViewBuilder
    var selectedStopsFooter:
        some View {

        if
            store
                .futureRouteDraft
                .stopCount > 1
        {

            if draftHasTimeOrderIssue {

                Label(
                    "Stops must move forward through the day. Reorder the highlighted stops.",
                    systemImage:
                        "exclamationmark.triangle.fill"
                )
                .foregroundStyle(
                    .orange
                )

            } else {

                Text(
                    "Drag stops to change their route order."
                )
            }
        }
    }
}

private extension FutureRouteBuilderView {

    @ViewBuilder
    func selectedStopRow(
        nodeID:
            GameNodeID,
        index:
            Int
    ) -> some View {

        if let node =
            store.gameNode(
                id:
                    nodeID
            )
        {

            selectedExistingStopRow(
                node:
                    node,
                index:
                    index
            )

        } else {

            missingSelectedStopRow(
                nodeID:
                    nodeID,
                index:
                    index
            )
        }
    }
}

private extension FutureRouteBuilderView {

    func selectedExistingStopRow(
        node:
            GameMapNode,
        index:
            Int
    ) -> some View {

        HStack(
            spacing:
                12
        ) {

            // =============================================
            // Sequence Number
            // =============================================

            routeStopNumber(
                index:
                    index,
                hasWarning:
                    stopHasTimeOrderIssue(
                        at:
                            index
                    )
            )


            // =============================================
            // Content
            // =============================================

            VStack(
                alignment:
                    .leading,
                spacing:
                    4
            ) {

                routeNodeInformation(
                    node:
                        node
                )


                if let warning =
                    timeOrderWarning(
                        at:
                            index
                    )
                {

                    Label(
                        warning,
                        systemImage:
                            "exclamationmark.triangle.fill"
                    )
                    .font(
                        .caption
                    )
                    .foregroundStyle(
                        .orange
                    )
                }
            }


            Spacer()


            // =============================================
            // More Actions
            // =============================================

            stopActionsMenu(
                node:
                    node,
                index:
                    index
            )
        }
        .padding(
            .vertical,
            4
        )
    }
}

private extension FutureRouteBuilderView {

    func routeStopNumber(
        index:
            Int,
        hasWarning:
            Bool
    ) -> some View {

        ZStack {

            Circle()
                .fill(
                    hasWarning
                    ? Color.orange
                        .opacity(
                            0.16
                        )
                    : Color.secondary
                        .opacity(
                            0.14
                        )
                )
                .frame(
                    width:
                        34,
                    height:
                        34
                )


            Text(
                "\(index + 1)"
            )
            .font(
                .subheadline
            )
            .fontWeight(
                .semibold
            )
            .foregroundStyle(
                hasWarning
                ? .orange
                : .primary
            )
        }
    }
}

private extension FutureRouteBuilderView {

    func stopActionsMenu(
        node:
            GameMapNode,
        index:
            Int
    ) -> some View {

        Menu {

            // =============================================
            // Move Up
            // =============================================

            Button {

                moveStopUp(
                    at:
                        index
                )

            } label: {

                Label(
                    "Move Up",
                    systemImage:
                        "arrow.up"
                )
            }
            .disabled(
                index ==
                    0
            )


            // =============================================
            // Move Down
            // =============================================

            Button {

                moveStopDown(
                    at:
                        index
                )

            } label: {

                Label(
                    "Move Down",
                    systemImage:
                        "arrow.down"
                )
            }
            .disabled(
                index >=
                    store
                        .futureRouteDraft
                        .stopNodeIDs
                        .count
                    -
                    1
            )


            Divider()


            // =============================================
            // Remove
            // =============================================

            Button(
                role:
                    .destructive
            ) {

                removeStop(
                    node.id
                )

            } label: {

                Label(
                    "Remove Stop",
                    systemImage:
                        "trash"
                )
            }


        } label: {

            Image(
                systemName:
                    "ellipsis.circle"
            )
            .font(
                .title3
            )
        }
        .buttonStyle(
            .plain
        )
    }
}

private extension FutureRouteBuilderView {

    func moveStopUp(
        at index:
            Int
    ) {

        guard index > 0 else {
            return
        }


        store
            .moveFutureRouteDraftStop(
                from:
                    index,
                to:
                    index - 1
            )
    }


    func moveStopDown(
        at index:
            Int
    ) {

        let count =
            store
                .futureRouteDraft
                .stopNodeIDs
                .count


        guard
            index >= 0,
            index < count - 1
        else {

            return
        }


        store
            .moveFutureRouteDraftStop(
                from:
                    index,
                to:
                    index + 1
            )
    }
}

private extension FutureRouteBuilderView {

    func missingSelectedStopRow(
        nodeID:
            GameNodeID,
        index:
            Int
    ) -> some View {

        HStack(
            spacing:
                12
        ) {

            routeStopNumber(
                index:
                    index,
                hasWarning:
                    true
            )


            VStack(
                alignment:
                    .leading,
                spacing:
                    3
            ) {

                Text(
                    "Missing Stop"
                )
                .fontWeight(
                    .medium
                )


                Text(
                    "This map node no longer exists."
                )
                .font(
                    .caption
                )
                .foregroundStyle(
                    .secondary
                )
            }


            Spacer()


            Button(
                role:
                    .destructive
            ) {

                removeStop(
                    nodeID
                )

            } label: {

                Image(
                    systemName:
                        "trash"
                )
            }
            .buttonStyle(
                .plain
            )
        }
    }
}

private extension FutureRouteBuilderView {

    var draftHasTimeOrderIssue:
        Bool {

        let nodeIDs =
            store
                .futureRouteDraft
                .stopNodeIDs


        guard nodeIDs.count >= 2 else {
            return false
        }


        for index in
            nodeIDs.indices {

            if
                stopHasTimeOrderIssue(
                    at:
                        index
                )
            {

                return true
            }
        }


        return false
    }
}

private extension FutureRouteBuilderView {

    func stopHasTimeOrderIssue(
        at index:
            Int
    ) -> Bool {

        timeOrderWarning(
            at:
                index
        )
        != nil
    }
}

private extension FutureRouteBuilderView {

    func timeOrderWarning(
        at index:
            Int
    ) -> String? {

        let nodeIDs =
            store
                .futureRouteDraft
                .stopNodeIDs


        guard
            nodeIDs.indices
                .contains(
                    index
                )
        else {

            return nil
        }


        let nodeID =
            nodeIDs[index]


        guard let currentTime =
            store
                .mapCoordinate(
                    for:
                        nodeID
                )?
                .time
        else {

            return "Stop time could not be resolved."
        }


        // =================================================
        // Compare to previous stop.
        // =================================================

        if index > 0 {

            let previousID =
                nodeIDs[
                    index - 1
                ]


            if let previousTime =
                store
                    .mapCoordinate(
                        for:
                            previousID
                    )?
                    .time,
               currentTime <
                previousTime
            {

                return "Occurs earlier than the previous stop."
            }
        }


        // =================================================
        // Compare to next stop.
        // =================================================

        if index <
            nodeIDs.count - 1
        {

            let nextID =
                nodeIDs[
                    index + 1
                ]


            if let nextTime =
                store
                    .mapCoordinate(
                        for:
                            nextID
                    )?
                    .time,
               nextTime <
                currentTime
            {

                return "Occurs later than the next stop."
            }
        }


        return nil
    }
}

private extension FutureRouteBuilderView {

    func selectedStopRow(
        node:
            GameMapNode,
        index:
            Int
    ) -> some View {

        HStack(
            spacing:
                12
        ) {

            // =================================================
            // Stop Number
            // =================================================

            ZStack {

                Circle()
                    .fill(
                        .secondary
                            .opacity(
                                0.14
                            )
                    )
                    .frame(
                        width:
                            34,
                        height:
                            34
                    )


                Text(
                    "\(index + 1)"
                )
                .font(
                    .subheadline
                )
                .fontWeight(
                    .semibold
                )
            }


            // =================================================
            // Node
            // =================================================

            routeNodeInformation(
                node:
                    node
            )


            Spacer()


            // =================================================
            // Remove
            // =================================================

            Button {

                removeStop(
                    node.id
                )

            } label: {

                Image(
                    systemName:
                        "minus.circle.fill"
                )
                .font(
                    .title3
                )
                .foregroundStyle(
                    .red
                )
            }
            .buttonStyle(
                .plain
            )
            .accessibilityLabel(
                "Remove \(node.content.title)"
            )
        }
        .padding(
            .vertical,
            4
        )
    }
}

// =====================================================
// MARK: - Available Stops
// =====================================================

private extension FutureRouteBuilderView {

    @ViewBuilder
    var availableStopsSection:
        some View {

        Section {

            if filteredAvailableNodes.isEmpty {

                ContentUnavailableView(
                    searchText.isEmpty
                    ? "No Available Route Stops"
                    : "No Matching Stops",
                    systemImage:
                        "magnifyingglass",
                    description:
                        Text(
                            searchText.isEmpty
                            ? "Add future nodes on valid roads to make them available here."
                            : "Try another search."
                        )
                )

            } else {

                ForEach(
                    filteredAvailableNodes
                ) { node in

                    availableStopRow(
                        node:
                            node
                    )
                }
            }

        } header: {

            Text(
                "Available Stops"
            )

        } footer: {

            Text(
                "Only enabled future nodes that are actually connected to the road network can be added to a road route."
            )
        }
    }
}

//validationSection
// =====================================================
// MARK: - Validation
// =====================================================

private extension FutureRouteBuilderView {

    @ViewBuilder
    var validationSection:
        some View {

        Section(
            "Route Status"
        ) {

            let validation =
                store
                    .futureRouteDraftValidation


            if validation.isValid {

                Label(
                    "Ready to Plan",
                    systemImage:
                        "checkmark.circle.fill"
                )
                .foregroundStyle(
                    .green
                )

            } else {

                ForEach(
                    Array(
                        store
                            .futureRouteDraftValidationMessages
                            .enumerated()
                    ),
                    id:
                        \.offset
                ) { _, message in

                    Label(
                        message,
                        systemImage:
                            "exclamationmark.triangle.fill"
                    )
                    .foregroundStyle(
                        .orange
                    )
                }
            }
        }
    }
}

private extension FutureRouteBuilderView {

    var filteredAvailableNodes:
        [GameMapNode] {

        let nodes =
            store
                .availableFutureRouteStopNodes


        guard
            !searchText
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )
                .isEmpty
        else {

            return nodes
        }


        let query =
            searchText
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )


        return nodes.filter { node in

            node.content
                .title
                .localizedCaseInsensitiveContains(
                    query
                )
        }
    }
}

private extension FutureRouteBuilderView {

    func availableStopRow(
        node:
            GameMapNode
    ) -> some View {

        let alreadySelected =
            store
                .futureRouteDraft
                .contains(
                    node.id
                )


        return HStack(
            spacing:
                12
        ) {

            routeNodeIcon(
                node:
                    node
            )


            routeNodeInformation(
                node:
                    node
            )


            Spacer()


            if alreadySelected {

                Image(
                    systemName:
                        "checkmark.circle.fill"
                )
                .font(
                    .title3
                )
                .foregroundStyle(
                    .green
                )

            } else {

                Button {

                    addStop(
                        node.id
                    )

                } label: {

                    Image(
                        systemName:
                            "plus.circle.fill"
                    )
                    .font(
                        .title3
                    )
                }
                .buttonStyle(
                    .plain
                )
                .accessibilityLabel(
                    "Add \(node.content.title) to route"
                )
            }
        }
        .contentShape(
            Rectangle()
        )
        .onTapGesture {

            guard
                !alreadySelected
            else {

                return
            }


            addStop(
                node.id
            )
        }
        .padding(
            .vertical,
            4
        )
        .allowsHitTesting(
            !alreadySelected
        )
    }
}

// =====================================================
// MARK: - Node Information
// =====================================================

private extension FutureRouteBuilderView {

    func routeNodeInformation(
        node:
            GameMapNode
    ) -> some View {

        VStack(
            alignment:
                .leading,
            spacing:
                3
        ) {

            Text(
                node.content.title
            )
            .font(
                .body
            )
            .fontWeight(
                .medium
            )


            HStack(
                spacing:
                    8
            ) {

                if let time =
                    nodeTime(
                        node
                    )
                {

                    Label(
                        time.displayClockString,
                        systemImage:
                            "clock"
                    )
                }


                Text(
                    nodeKindName(
                        node.content.kind
                    )
                )
            }
            .font(
                .caption
            )
            .foregroundStyle(
                .secondary
            )
        }
    }
}

private extension FutureRouteBuilderView {

    func routeNodeIcon(
        node:
            GameMapNode
    ) -> some View {

        Image(
            systemName:
                nodeKindSymbol(
                    node.content.kind
                )
        )
        .font(
            .headline
        )
        .frame(
            width:
                34,
            height:
                34
        )
        .background {

            Circle()
                .fill(
                    .secondary
                        .opacity(
                            0.12
                        )
                )
        }
    }


    func nodeKindSymbol(
        _ kind:
            GameNodeKind
    ) -> String {

        switch kind {

        case .label:
            return "tag.fill"

        case .user:
            return "person.fill"

        case .activity:
            return "figure.run"

        case .post:
            return "text.bubble.fill"

        case .media:
            return "photo.fill"

        case .hyperlink:
            return "link"
        }
    }


    func nodeKindName(
        _ kind:
            GameNodeKind
    ) -> String {

        switch kind {

        case .label:
            return "Label"

        case .user:
            return "User"

        case .activity:
            return "Activity"

        case .post:
            return "Post"

        case .media:
            return "Media"

        case .hyperlink:
            return "Link"
        }
    }
}

private extension FutureRouteBuilderView {

    func nodeTime(
        _ node:
            GameMapNode
    ) -> DayTime? {

        store
            .mapCoordinate(
                for:
                    node.id
            )?
            .time
    }
}

// =====================================================
// MARK: - Actions
// =====================================================

private extension FutureRouteBuilderView {

    func addStop(
        _ nodeID:
            GameNodeID
    ) {

        let succeeded =
            store
                .addStopToFutureRouteDraft(
                    nodeID
                )


        if !succeeded {

            print(
                "Unable to add node to future route draft:",
                nodeID
            )
        }
    }


    func removeStop(
        _ nodeID:
            GameNodeID
    ) {

        store
            .removeStopFromFutureRouteDraft(
                nodeID:
                    nodeID
            )
    }
}

// =====================================================
// MARK: - Validation
// =====================================================

private extension FutureRouteBuilderView {

    // =====================================================
    // MARK: - Validation
    // =====================================================
     
    


    var validationSummary:
        String {

        let issues =
            store
                .futureRouteDraftValidation
                .issues


        if issues.contains(
            .tooFewStops
        ) {

            return "Select at least two stops."
        }


        for issue in
            issues {

            switch issue {

            case .stopIsInPast:

                return "A selected stop occurs in the past."


            case .stopsOutOfTimeOrder:

                return "Stops must move forward through the day."


            case .nodeNotRouteEligible:

                return "A selected stop is no longer connected to a valid road."


            case .nodeDisabled:

                return "A selected stop is disabled."


            case .nodeNotFound:

                return "A selected stop no longer exists."


            case .duplicateStop:

                return "The same stop cannot appear twice."


            case .tooFewStops:

                return "Select at least two stops."
            }
        }


        return "Route draft needs attention."
    }
}

// =====================================================
// MARK: - Toolbar
// =====================================================

private extension FutureRouteBuilderView {

    @ToolbarContentBuilder
    var routeBuilderToolbar:
        some ToolbarContent {

        ToolbarItem(
            placement:
                .cancellationAction
        ) {

            Button(
                "Cancel"
            ) {

                cancelRouteBuilder()
            }
        }


        ToolbarItem(
            placement:
                .topBarTrailing
        ) {

            EditButton()
                .disabled(
                    store
                        .futureRouteDraft
                        .stopCount < 2
                )
        }


        ToolbarItem(
            placement:
                .confirmationAction
        ) {

            Button(
                "Plan"
            ) {

                planRoute()
            }
            .disabled(
                !canPlanRoute
            )
        }
    }


    func cancelRouteBuilder() {

        store.clearFutureRouteDraft()

        dismiss()
    }
}

private extension FutureRouteBuilderView {

    private func planRoute() {

        let planningResult =
            store
                .planFutureRouteDraft()


        guard
            planningResult.succeeded
        else {

            planningFailed =
                true

            return
        }


        let generated =
            store
                .generateFutureRoutePreview(
                    maxAlternatives:
                        3
                )


        guard generated else {

            planningFailed =
                true

            return
        }


        isShowingPreview =
            true
    }
}

private extension FutureRouteBuilderView {

    func routeStartDescription(
        _ start:
            FutureRouteDraftPlanStart?
    ) -> String {

        switch start {

        case .firstSelectedStop:

            return "Starts at first stop"


        case .currentRoutePosition:

            return "Starts from current position"


        case .none:

            return "Route start unavailable"
        }
    }
}


private extension FutureRouteBuilderView {

    var builderTitle:
        String {

        if
            store
                .futureRouteDraft
                .isEditingExistingRoute
        {

            return "Edit Route"
        }


        return "Build Route"
    }
}

private extension FutureRouteBuilderView {

    var planningFailureMessage:
        String {

        guard let result =
            store.futureRouteDraftPlan
        else {

            return "The route could not be planned."
        }


        if let firstIssue =
            result.planningIssues.first
        {

            return firstIssue.message
        }


        switch result.failure {

        case .invalidDraft:

            return
                "Fix the route-stop issues before planning."


        case .noValidRoadPath:

            return
                "No valid forward-time road path connects these stops."


        case .currentRoutePositionUnavailable:

            return
                "Your current road position could not be resolved."


        case .none:

            return
                "The route could not be planned."
        }
    }
}

private extension FutureRouteBuilderView {

    var canPlanRoute:
        Bool {

        store
            .futureRouteDraftValidation
            .isValid
        &&
        store
            .futureRouteDraft
            .stopCount >= 2
    }
}
