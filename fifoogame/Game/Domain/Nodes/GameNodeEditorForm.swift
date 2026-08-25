//
//  GameNodeEditorForm.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/24/26.
//




import SwiftUI
import Foundation
import UIKit

struct GameNodeEditorForm: View {

    @Binding var node:
        GameMapNode


    let roadGraph:
        RoadGraph


    let validationIssues:
        [GameNodeValidationIssue]

    @State private var isShowingRoadVertexPicker = false


    var body: some View {

        Form {

            if isActivityNode {

                activityTitleSection

                activityScheduleSection

                activityTypeSection

                activityDetailsSection

                activityStatusSection

            } else if isUserNode {

                validationSection

                userProfileSection

                userGoalProgressSection

                userCommunitySection

                userRecognitionSection

                userAccountActivitySection

                userMapTimeSection

            } else if isPostNode {

                postTypeSection

                postSubjectSection

                postImagesSection

                postVideosSection

            } else {

                validationSection

                identitySection

                contentSection

                timeSection

                imageSection

                placementSection

                roadRelationshipSection

                statusSection
            }
        }
    }
}

// =====================================================
// MARK: - Validation
// =====================================================

private extension GameNodeEditorForm {

    @ViewBuilder
    var validationSection: some View {

        if !validationIssues.isEmpty {

            Section(
                "Validation"
            ) {

                ForEach(
                    validationIssues
                ) { issue in

                    HStack(
                        alignment:
                            .top,
                        spacing:
                            10
                    ) {

                        Image(
                            systemName:
                                issue.severity ==
                                    .error
                                ? "exclamationmark.circle.fill"
                                : "exclamationmark.triangle.fill"
                        )
                        .foregroundStyle(
                            issue.severity ==
                                .error
                                ? .red
                                : .orange
                        )


                        Text(
                            issue.message
                        )
                        .font(
                            .callout
                        )
                    }
                }
            }
        }
    }
}

// =====================================================
// MARK: - Identity
// =====================================================

private extension GameNodeEditorForm {

    var identitySection: some View {

        Section(
            "Node"
        ) {

            LabeledContent(
                "Type",
                value:
                    node.content.kind
                        .rawValue
                        .capitalized
            )


            VStack(
                alignment:
                    .leading,
                spacing:
                    4
            ) {

                Text(
                    "Node ID"
                )
                .font(
                    .caption
                )
                .foregroundStyle(
                    .secondary
                )


                Text(
                    node.id
                        .rawValue
                        .uuidString
                )
                .font(
                    .caption2
                        .monospaced()
                )
                .foregroundStyle(
                    .secondary
                )
                .textSelection(
                    .enabled
                )
            }
        }
    }
}

// =====================================================
// MARK: - Content
// =====================================================

private extension GameNodeEditorForm {

    @ViewBuilder
    var contentSection: some View {

        Section(
            "Content"
        ) {

            switch node.content {

            // =========================================
            // Play
            // =========================================

            case .play:

                TextField(
                    "Title",
                    text:
                        playTitleBinding
                )


            // =========================================
            // User
            // =========================================

            case .user:

                TextField(
                    "Display Name",
                    text:
                        userDisplayNameBinding
                )


                TextField(
                    "User ID",
                    text:
                        userIDBinding
                )
                .textInputAutocapitalization(
                    .never
                )
                .autocorrectionDisabled()


            // =========================================
            // Activity
            // =========================================

            case .activity:

                TextField(
                    "Title",
                    text:
                        activityTitleBinding
                )


                TextField(
                    "Activity ID",
                    text:
                        activityIDBinding
                )
                .textInputAutocapitalization(
                    .never
                )
                .autocorrectionDisabled()


                TextField(
                    "Description",
                    text:
                        activityDescriptionBinding,
                    axis:
                        .vertical
                )
                .lineLimit(
                    3...8
                )


            // =========================================
            // Post
            // =========================================

            case .post:

                // Post nodes use their own intentionally minimal creation
                // form in `body`: Post Type, Subject, Images, and Videos.
                EmptyView()


            // =========================================
            // Media
            // =========================================

            case .media:

                TextField(
                    "Title",
                    text:
                        mediaTitleBinding
                )


                TextField(
                    "Media ID",
                    text:
                        mediaIDBinding
                )
                .textInputAutocapitalization(
                    .never
                )
                .autocorrectionDisabled()


                Picker(
                    "Media Type",
                    selection:
                        mediaTypeBinding
                ) {

                    ForEach(
                        MediaNodeContent
                            .MediaType
                            .allEditorCases,
                        id:
                            \.self
                    ) { type in

                        Text(
                            type.rawValue
                                .capitalized
                        )
                        .tag(
                            type
                        )
                    }
                }


                TextField(
                    "Media URL",
                    text:
                        mediaURLBinding
                )
                .textInputAutocapitalization(
                    .never
                )
                .keyboardType(
                    .URL
                )
                .autocorrectionDisabled()


            // =========================================
            // Hyperlink
            // =========================================

            case .hyperlink:

                TextField(
                    "Title",
                    text:
                        hyperlinkTitleBinding
                )


                TextField(
                    "URL",
                    text:
                        hyperlinkURLBinding
                )
                .textInputAutocapitalization(
                    .never
                )
                .keyboardType(
                    .URL
                )
                .autocorrectionDisabled()
            }
        }
    }
}

// =====================================================
// MARK: - Post Creation Form
// =====================================================

private extension GameNodeEditorForm {

    var isPostNode: Bool {

        if case .post = node.content {
            return true
        }

        return false
    }


    var postTypeSection: some View {

        Section(
            "Post Type"
        ) {

            LabeledContent(
                "Type",
                value:
                    currentPostSnapshot?
                        .postTypeDisplayName
                    ?? "Post"
            )
        }
    }


    var postSubjectSection: some View {

        Section(
            "Subject"
        ) {

            TextField(
                "Subject",
                text:
                    postSubjectBinding,
                axis:
                    .vertical
            )
            .lineLimit(
                2...8
            )
        }
    }


    var postImagesSection: some View {

        Section(
            "Images"
        ) {

            TextField(
                "Image URLs",
                text:
                    postImageURLsBinding,
                axis:
                    .vertical
            )
            .lineLimit(
                2...8
            )
            .textInputAutocapitalization(
                .never
            )
            .keyboardType(
                .URL
            )
            .autocorrectionDisabled()
        }
    }


    var postVideosSection: some View {

        Section(
            "Videos"
        ) {

            TextField(
                "Video URLs",
                text:
                    postVideoURLsBinding,
                axis:
                    .vertical
            )
            .lineLimit(
                2...8
            )
            .textInputAutocapitalization(
                .never
            )
            .keyboardType(
                .URL
            )
            .autocorrectionDisabled()
        }
    }


    var currentPostSnapshot:
        PostNodeSnapshot? {

        guard case let .post(
            content
        ) = node.content
        else {
            return nil
        }

        return content.snapshot
    }
}


// =====================================================
// MARK: - User Editor
// =====================================================

private extension GameNodeEditorForm {

    var isUserNode: Bool {

        if case .user = node.content {
            return true
        }

        return false
    }


    var userProfileSection: some View {

        Section(
            "Profile"
        ) {

            nodeImagePreview


            if let profile =
                currentUserProfile {

                LabeledContent(
                    "Name",
                    value:
                        profile.preferredDisplayName
                )


                if !profile.username
                    .trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )
                    .isEmpty {

                    LabeledContent(
                        "Username",
                        value:
                            profile.username.hasPrefix("@")
                            ? profile.username
                            : "@\(profile.username)"
                    )
                }


                if !profile.phone
                    .trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )
                    .isEmpty {

                    LabeledContent(
                        "Phone",
                        value:
                            profile.phone
                    )
                }


                LabeledContent(
                    "User ID"
                ) {

                    Text(
                        profile.userID
                    )
                    .font(
                        .caption.monospaced()
                    )
                    .foregroundStyle(
                        .secondary
                    )
                    .textSelection(
                        .enabled
                    )
                }

            } else {

                LabeledContent(
                    "Name",
                    value:
                        currentUserContent?.displayName
                        ?? "User"
                )

                LabeledContent(
                    "User ID"
                ) {

                    Text(
                        currentUserContent?.userID
                        ?? ""
                    )
                    .font(
                        .caption.monospaced()
                    )
                    .foregroundStyle(
                        .secondary
                    )
                }

                Text(
                    "No profile snapshot is stored on this user node yet."
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


    var userGoalProgressSection: some View {

        Section(
            "Goal & Progress"
        ) {

            if let profile =
                currentUserProfile {

                if !profile.goal
                    .trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )
                    .isEmpty {

                    VStack(
                        alignment: .leading,
                        spacing: 6
                    ) {

                        Text(
                            "Goal"
                        )
                        .font(
                            .caption
                        )
                        .foregroundStyle(
                            .secondary
                        )

                        Text(
                            profile.goal
                        )
                    }
                }


                VStack(
                    alignment: .leading,
                    spacing: 8
                ) {

                    HStack {

                        Text(
                            "Progress"
                        )

                        Spacer()

                        Text(
                            "\(profile.progressPercent)%"
                        )
                        .fontWeight(
                            .semibold
                        )
                        .monospacedDigit()
                    }

                    ProgressView(
                        value:
                            profile.progressFraction
                    )
                }

            } else {

                Text(
                    "Progress is unavailable until a profile snapshot is attached."
                )
                .foregroundStyle(
                    .secondary
                )
            }
        }
    }


    var userCommunitySection: some View {

        Section(
            "Community"
        ) {

            if let profile =
                currentUserProfile {

                LabeledContent(
                    "Followers",
                    value:
                        "\(profile.inFollowersCount)"
                )

                LabeledContent(
                    "Following",
                    value:
                        "\(profile.outFollowersCount)"
                )

                LabeledContent(
                    "Tips",
                    value:
                        "\(profile.tipsCount)"
                )

                LabeledContent(
                    "Responses",
                    value:
                        "\(profile.responseCount)"
                )

                LabeledContent(
                    "Requests",
                    value:
                        "\(profile.requestCount)"
                )

            } else {

                Text(
                    "Community statistics are unavailable."
                )
                .foregroundStyle(
                    .secondary
                )
            }
        }
    }


    @ViewBuilder
    var userRecognitionSection: some View {

        if let profile =
            currentUserProfile {

            let badges =
                userRecognitionBadges(
                    profile
                )

            Section(
                "Recognition"
            ) {

                if badges.isEmpty {

                    Text(
                        "No recognition badges yet."
                    )
                    .foregroundStyle(
                        .secondary
                    )

                } else {

                    ForEach(
                        badges,
                        id: \.self
                    ) { badge in

                        Text(
                            badge
                        )
                        .fontWeight(
                            .semibold
                        )
                    }
                }
            }
        }
    }


    var userAccountActivitySection: some View {

        Section(
            "Account Activity"
        ) {

            if let profile =
                currentUserProfile {

                if !profile.joined
                    .trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )
                    .isEmpty {

                    LabeledContent(
                        "Joined",
                        value:
                            profile.joined
                    )
                }


                if !profile.lastActive
                    .trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )
                    .isEmpty {

                    LabeledContent(
                        "Last Active",
                        value:
                            profile.lastActive
                    )
                }

            } else {

                Text(
                    "Account activity is unavailable."
                )
                .foregroundStyle(
                    .secondary
                )
            }
        }
    }


    var userMapTimeSection: some View {

        Section(
            "Map Time"
        ) {

            DatePicker(
                "Time",
                selection:
                    nodeTimeBinding,
                displayedComponents:
                    .hourAndMinute
            )
            .disabled(
                isRoadVertexPlacement
            )


            if isRoadVertexPlacement {

                Text(
                    "This user node is attached to a road intersection, so its map time follows that intersection."
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


    var currentUserContent:
        UserNodeContent? {

        guard case let .user(
            content
        ) = node.content
        else {
            return nil
        }

        return content
    }


    var currentUserProfile:
        UserProfileNodeSnapshot? {

        currentUserContent?.profile
    }


    func userRecognitionBadges(
        _ profile:
            UserProfileNodeSnapshot
    ) -> [String] {

        var badges: [String] = []

        if profile.topTipster {
            badges.append("Top Tipster")
        }

        if profile.topRequester {
            badges.append("Top Requester")
        }

        if profile.topResponder {
            badges.append("Top Responder")
        }

        if profile.topContributor {
            badges.append("Top Contributor")
        }

        return badges
    }
}


// =====================================================
// MARK: - Activity Editor
// =====================================================

private extension GameNodeEditorForm {

    var isActivityNode: Bool {

        if case .activity = node.content {
            return true
        }

        return false
    }


    /// Activity's first section is intentionally limited to the content a
    /// user needs to identify the activity at a glance: its title and, when
    /// supplied by the Activity model, its image.
    var activityTitleSection: some View {

        Section(
            "Title"
        ) {

            TextField(
                "Title",
                text:
                    activityTitleBinding
            )


            if currentImage != nil {

                nodeImagePreview
            }
        }
    }


    var activityScheduleSection: some View {

        Section(
            "Schedule"
        ) {

            TextField(
                "Date",
                text:
                    activityDateBinding
            )
            .textInputAutocapitalization(
                .never
            )
            .autocorrectionDisabled()


            DatePicker(
                "Start Time",
                selection:
                    activityStartTimeBinding,
                displayedComponents:
                    .hourAndMinute
            )


            DatePicker(
                "End Time",
                selection:
                    activityEndTimeBinding,
                displayedComponents:
                    .hourAndMinute
            )


            Text(
                "Changing Start Time also moves this node to that time on the day map. If the node was attached to a road intersection, it becomes a free-position node at the same progress instead of being silently snapped to another road."
            )
            .font(
                .caption
            )
            .foregroundStyle(
                .secondary
            )
        }
    }


    /// Activity type is intentionally read-only on the Activity screen. It
    /// summarizes the underlying SuggestedMeal / Workout / UserTask and links
    /// to a dedicated editor for that object.
    var activityTypeSection: some View {

        Section(
            "Activity Type"
        ) {

            LabeledContent(
                "Type"
            ) {

                Text(
                    activityTypeEditorDisplayName
                )
                .fontWeight(
                    .semibold
                )
            }


            activityTypeSummary


            NavigationLink {

                ActivityTypeEditorView(
                    node:
                        $node
                )

            } label: {

                Text(
                    "Edit \(activityTypeEditorDisplayName)"
                )
                .fontWeight(
                    .semibold
                )
            }
        }
    }


    @ViewBuilder
    var activityTypeSummary: some View {

        if case let .activity(
            content
        ) = node.content {

            switch content.resolvedActivityType {

        case .meal:

            if let meal =
                content.meal {

                LabeledContent(
                    "Meal",
                    value:
                        meal.title
                )

                LabeledContent(
                    "Estimated Time",
                    value:
                        "\(meal.estimatedTimeMinutes) min"
                )

                if !meal.priceRange
                    .trimmingCharacters(
                        in:
                            .whitespacesAndNewlines
                    )
                    .isEmpty {

                    LabeledContent(
                        "Price Range",
                        value:
                            meal.priceRange
                    )
                }

                if let user =
                    meal.user,
                   !user.name.isEmpty {

                    LabeledContent(
                        "Created By",
                        value:
                            user.name
                    )
                }

                if let meals =
                    meal.meals {

                    LabeledContent(
                        "Meals",
                        value:
                            "\(meals.count)"
                    )
                }

                if meal.imageURL != nil {

                    LabeledContent(
                        "Image",
                        value:
                            "Available"
                    )
                }

                if let copyStatus =
                    meal.copyStatus,
                   !copyStatus.status.isEmpty {

                    LabeledContent(
                        "Copy Status",
                        value:
                            copyStatus.status
                    )
                }

            } else {

                Text(
                    "No Suggested Meal details are stored on this node yet."
                )
                .foregroundStyle(
                    .secondary
                )
            }


        case .workout:

            if let workout =
                content.workout {

                LabeledContent(
                    "Workout",
                    value:
                        workout.title
                )

                if !workout.durationText.isEmpty {

                    LabeledContent(
                        "Duration",
                        value:
                            workout.durationText
                    )
                }

                if !workout.location.isEmpty {

                    LabeledContent(
                        "Location",
                        value:
                            workout.location
                    )
                }

                if !workout.distance.isEmpty {

                    LabeledContent(
                        "Distance",
                        value:
                            workout.distance
                    )
                }

                if let trainer =
                    workout.trainer,
                   !trainer.name.isEmpty {

                    LabeledContent(
                        "Trainer",
                        value:
                            trainer.name
                    )
                }

                if !workout.categories.isEmpty {

                    LabeledContent(
                        "Categories",
                        value:
                            workout.categories
                                .joined(
                                    separator:
                                        ", "
                                )
                    )
                }

                if let imageURLs =
                    workout.imageURLs {

                    LabeledContent(
                        "Images",
                        value:
                            "\(imageURLs.count)"
                    )
                }

                if let status =
                    workout.workoutStatus,
                   !status.isEmpty {

                    LabeledContent(
                        "Workout Status",
                        value:
                            status
                    )
                }

                if let participants =
                    workout.participants {

                    LabeledContent(
                        "Participants",
                        value:
                            "\(participants.count)"
                    )
                }

                if !workout.rating.isEmpty {

                    LabeledContent(
                        "Rating",
                        value:
                            workout.rating
                    )
                }

                if let copyStatus =
                    workout.copyStatus,
                   !copyStatus.status.isEmpty {

                    LabeledContent(
                        "Copy Status",
                        value:
                            copyStatus.status
                    )
                }

            } else {

                Text(
                    "No Workout details are stored on this node yet."
                )
                .foregroundStyle(
                    .secondary
                )
            }


        case .task:

            if let task =
                content.task {

                LabeledContent(
                    "Task",
                    value:
                        task.title
                )

                if !task.description.isEmpty {

                    VStack(
                        alignment:
                            .leading,
                        spacing:
                            4
                    ) {

                        Text(
                            "Task Description"
                        )
                        .font(
                            .caption
                        )
                        .foregroundStyle(
                            .secondary
                        )

                        Text(
                            task.description
                        )
                    }
                }

                LabeledContent(
                    "Images",
                    value:
                        "\(task.imageURLs?.count ?? 0)"
                )

                LabeledContent(
                    "Videos",
                    value:
                        "\(task.videoURLs?.count ?? 0)"
                )

                if let copyStatus =
                    task.copyStatus,
                   !copyStatus.status.isEmpty {

                    LabeledContent(
                        "Copy Status",
                        value:
                            copyStatus.status
                    )
                }

            } else {

                Text(
                    "No Task details are stored on this node yet."
                )
                .foregroundStyle(
                    .secondary
                )
            }
        }
        }
    }


    var activityDetailsSection: some View {

        Section(
            "Details"
        ) {

            TextField(
                "Location",
                text:
                    activityLocationBinding
            )


            TextField(
                "Description",
                text:
                    activityDescriptionBinding,
                axis:
                    .vertical
            )
            .lineLimit(
                3...8
            )
        }
    }


    var activityStatusSection: some View {

        Section(
            "Status"
        ) {

            LabeledContent(
                "Activity Status"
            ) {

                Text(
                    activityStatusDisplayName
                )
                .fontWeight(
                    .semibold
                )
            }
        }
    }


    var activityTypeEditorDisplayName: String {

        switch activityResolvedType {

        case .meal:

            return "Suggested Meal"

        case .workout:

            return "Workout"

        case .task:

            return "Task"
        }
    }


    var activityResolvedType:
        ActivityNodeContent.ActivityType {

        guard case let .activity(
            content
        ) = node.content
        else {

            return .task
        }

        return content.resolvedActivityType
    }


    var activityStatusDisplayName: String {

        guard case let .activity(
            content
        ) = node.content
        else {

            return "Not Started"
        }

        let cleaned =
            content.status
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )

        return cleaned.isEmpty
            ? "Not Started"
            : cleaned
    }
}


// =====================================================
// MARK: - Activity Bindings
// =====================================================

private extension GameNodeEditorForm {

    var activityDateBinding:
        Binding<String> {

        Binding {

            guard case let .activity(
                content
            ) = node.content
            else {

                return ""
            }

            return content.date

        } set: { newValue in

            guard case var .activity(
                content
            ) = node.content
            else {

                return
            }

            content.date =
                newValue

            node.content =
                .activity(
                    content
                )
        }
    }


    var activityLocationBinding:
        Binding<String> {

        Binding {

            guard case let .activity(
                content
            ) = node.content
            else {

                return ""
            }

            return content.location

        } set: { newValue in

            guard case var .activity(
                content
            ) = node.content
            else {

                return
            }

            content.location =
                newValue

            node.content =
                .activity(
                    content
                )
        }
    }


    var activityStartTimeBinding:
        Binding<Date> {

        Binding {

            if case let .activity(
                content
            ) = node.content,
               let parsed =
                    activityDayTime(
                        from:
                            content.startTime
                    ) {

                return referenceDate(
                    for:
                        parsed
                )
            }

            return referenceDate(
                for:
                    node.time
            )

        } set: { newDate in

            let newTime =
                activityDayTime(
                    from:
                        newDate
                )

            guard case var .activity(
                content
            ) = node.content
            else {

                return
            }

            content.startTime =
                newTime
                    .displayClockString

            node.content =
                .activity(
                    content
                )

            // Start time is always editable. A road-vertex placement has a
            // fixed semantic time, so changing the Activity's start time
            // intentionally detaches it from that intersection while
            // preserving the vertex's progress/X position. This avoids
            // silently snapping the activity to some other road.
            switch node.placement {

            case let .roadVertex(
                vertexID
            ):

                if let vertex =
                    roadGraph.vertex(
                        id:
                            vertexID
                    ) {

                    node.setPlacement(
                        .coordinate(
                            MapCoordinate(
                                time:
                                    newTime,
                                progress:
                                    vertex.coordinate.progress
                            )
                        )
                    )

                } else {

                    node.setTime(
                        newTime
                    )
                }

            case .coordinate:

                node.setTime(
                    newTime
                )
            }
        }
    }


    var activityEndTimeBinding:
        Binding<Date> {

        Binding {

            if case let .activity(
                content
            ) = node.content,
               let parsed =
                    activityDayTime(
                        from:
                            content.endTime
                    ) {

                return referenceDate(
                    for:
                        parsed
                )
            }

            let fallback =
                DayTime(
                    secondsFromMidnight:
                        node.time.secondsFromMidnight
                        + DayTime.secondsPerHour
                )

            return referenceDate(
                for:
                    fallback
            )

        } set: { newDate in

            let newTime =
                activityDayTime(
                    from:
                        newDate
                )

            guard case var .activity(
                content
            ) = node.content
            else {

                return
            }

            content.endTime =
                newTime
                    .displayClockString

            node.content =
                .activity(
                    content
                )
        }
    }


    func activityDayTime(
        from date: Date
    ) -> DayTime {

        let components =
            Calendar.current
                .dateComponents(
                    [
                        .hour,
                        .minute,
                        .second
                    ],
                    from:
                        date
                )

        let seconds =
            TimeInterval(
                (components.hour ?? 0) * 3600
                +
                (components.minute ?? 0) * 60
                +
                (components.second ?? 0)
            )

        return DayTime(
            secondsFromMidnight:
                seconds
        )
    }


    func activityDayTime(
        from value: String
    ) -> DayTime? {

        let cleaned =
            value
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )

        guard !cleaned.isEmpty
        else {

            return nil
        }

        let formatter =
            DateFormatter()

        formatter.locale =
            Locale(
                identifier:
                    "en_US_POSIX"
            )

        formatter.timeZone =
            TimeZone(
                secondsFromGMT:
                    0
            )

        let formats = [
            "h:mm a",
            "hh:mm a",
            "h:mm:ss a",
            "hh:mm:ss a",
            "H:mm",
            "HH:mm",
            "H:mm:ss",
            "HH:mm:ss"
        ]

        for format in formats {

            formatter.dateFormat =
                format

            if let date =
                formatter.date(
                    from:
                        cleaned
                ) {

                var calendar =
                    Calendar(
                        identifier:
                            .gregorian
                    )

                calendar.timeZone =
                    formatter.timeZone

                let components =
                    calendar.dateComponents(
                        [
                            .hour,
                            .minute,
                            .second
                        ],
                        from:
                            date
                    )

                return DayTime(
                    secondsFromMidnight:
                        TimeInterval(
                            (components.hour ?? 0) * 3600
                            +
                            (components.minute ?? 0) * 60
                            +
                            (components.second ?? 0)
                        )
                )
            }
        }

        return nil
    }
}



// =====================================================
// MARK: - Node Time
// =====================================================

private extension GameNodeEditorForm {

    var timeSection: some View {

        Section(
            "Time"
        ) {

            DatePicker(
                "Node Time",
                selection:
                    nodeTimeBinding,
                displayedComponents:
                    .hourAndMinute
            )
            .disabled(
                isRoadVertexPlacement
            )


            if isRoadVertexPlacement {

                Text(
                    "This node is attached to a road intersection, so its time follows that intersection."
                )
                .font(
                    .caption
                )
                .foregroundStyle(
                    .secondary
                )

            } else {

                Text(
                    "Time is stored directly on the GameMapNode and also controls the node's vertical map position."
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


    var isRoadVertexPlacement: Bool {

        if case .roadVertex = node.placement {
            return true
        }

        return false
    }
}



// =====================================================
// MARK: - Image Editor
// =====================================================

private extension GameNodeEditorForm {

    enum ImageSource:
        String,
        CaseIterable,
        Identifiable {

        case none

        case asset

        case remote


        var id: String {

            rawValue
        }


        var title: String {

            switch self {

            case .none:

                return "None"


            case .asset:

                return "Asset"


            case .remote:

                return "Remote URL"
            }
        }
    }


    var imageSection: some View {

        Section(
            "Node Image"
        ) {

            Picker(
                "Source",
                selection:
                    imageSourceBinding
            ) {

                ForEach(
                    ImageSource.allCases
                ) { source in

                    Text(
                        source.title
                    )
                    .tag(
                        source
                    )
                }
            }


            switch imageSourceBinding.wrappedValue {

            case .none:

                Text(
                    "No custom image selected. This node will use its type-specific placeholder image."
                )
                .font(
                    .caption
                )
                .foregroundStyle(
                    .secondary
                )


            case .asset:

                TextField(
                    "Asset Name",
                    text:
                        imageValueBinding
                )
                .autocorrectionDisabled()


            case .remote:

                TextField(
                    "Image URL",
                    text:
                        imageValueBinding
                )
                .textInputAutocapitalization(
                    .never
                )
                .keyboardType(
                    .URL
                )
                .autocorrectionDisabled()
            }


            nodeImagePreview
        }
    }
}

// =====================================================
// MARK: - Image Preview
// =====================================================

private extension GameNodeEditorForm {

    @ViewBuilder
    var nodeImagePreview: some View {

        HStack {

            Spacer()


            Group {

                switch currentImage {

                case let .asset(
                    name
                ):

                    if let image =
                        UIImage(
                            named:
                                name
                        )
                    {

                        Image(
                            uiImage:
                                image
                        )
                        .resizable()
                        .scaledToFill()

                    } else {

                        placeholderNodeImage
                    }


                case .systemSymbol:

                    placeholderNodeImage


                case let .remote(
                    urlString
                ):

                    if let url =
                        URL(
                            string:
                                urlString
                        )
                    {

                        AsyncImage(
                            url:
                                url
                        ) { phase in

                            switch phase {

                            case .empty:

                                ZStack {

                                    placeholderNodeImage

                                    ProgressView()
                                        .tint(
                                            .white
                                        )
                                }


                            case let .success(
                                image
                            ):

                                image
                                    .resizable()
                                    .scaledToFill()


                            case .failure:

                                placeholderNodeImage


                            @unknown default:

                                placeholderNodeImage
                            }
                        }

                    } else {

                        placeholderNodeImage
                    }


                case nil:

                    placeholderNodeImage
                }
            }
            .frame(
                width:
                    70,
                height:
                    70
            )
            .clipShape(
                Circle()
            )
            .overlay {

                Circle()
                    .stroke(
                        .secondary,
                        lineWidth:
                            1
                    )
            }


            Spacer()
        }
        .padding(
            .vertical,
            6
        )
    }
}

private extension GameNodeEditorForm {

    var placeholderNodeImage: some View {

        Image(
            uiImage:
                GameNodePlaceholderImage.image(
                    for:
                        node.content.kind
                )
        )
        .resizable()
        .scaledToFill()
    }
}


// =====================================================
// MARK: - Placement
// =====================================================

private extension GameNodeEditorForm {

        enum PlacementType:
            String,
            CaseIterable,
            Identifiable {

            case coordinate

            case roadVertex


            var id:
                String {

                rawValue
            }


            var title:
                String {

                switch self {

                case .coordinate:

                    return "Free Coordinate"


                case .roadVertex:

                    return "Road Intersection"
                }
            }
        }


        var placementSection:
            some View {

            Section(
                "Placement"
            ) {

                Picker(
                    "Type",
                    selection:
                        placementTypeBinding
                ) {

                    ForEach(
                        PlacementType.allCases
                    ) { type in

                        Text(
                            type.title
                        )
                        .tag(
                            type
                        )
                    }
                }


                switch node.placement {

                // =========================================
                // Free Coordinate
                // =========================================

                case .coordinate:

                    freeCoordinateEditor


                // =========================================
                // Road Vertex
                // =========================================

                case let .roadVertex(
                    vertexID
                ):

                    roadVertexEditor(
                        vertexID:
                            vertexID
                    )
                }
            }
            .sheet(
                isPresented:
                    $isShowingRoadVertexPicker
            ) {

                RoadVertexPickerView(
                    graph:
                        roadGraph,
                    selectedVertexID:
                        selectedRoadVertexID
                ) { vertexID in

                    if let vertex =
                        roadGraph.vertex(
                            id:
                                vertexID
                        )
                    {

                        node.setPlacement(
                            .roadVertex(
                                vertexID
                            ),
                            resolvedRoadTime:
                                vertex.coordinate.time
                        )

                    } else {

                        node.setPlacement(
                            .roadVertex(
                                vertexID
                            )
                        )
                    }
                }
            }
    }
    
}

// =====================================================
// MARK: - Status
// =====================================================

private extension GameNodeEditorForm {

    var statusSection: some View {

        Section(
            "Status"
        ) {

            Toggle(
                "Enabled",
                isOn:
                    $node.isEnabled
            )


            Text(
                node.isEnabled
                    ? "The node is visible and interactive on the map."
                    : "The node will not be rendered or interactive on the map."
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

// =====================================================
// MARK: - Play Bindings
// =====================================================

private extension GameNodeEditorForm {

    var playTitleBinding:
        Binding<String> {

        Binding {

            guard case let .play(
                content
            ) = node.content
            else {

                return ""
            }


            return content.title

        } set: { newValue in

            guard case var .play(
                content
            ) = node.content
            else {

                return
            }


            content.title =
                newValue


            node.content =
                .play(
                    content
                )
        }
    }
}

// =====================================================
// MARK: - User Bindings
// =====================================================

private extension GameNodeEditorForm {

    var userDisplayNameBinding:
        Binding<String> {

        Binding {

            guard case let .user(
                content
            ) = node.content
            else {

                return ""
            }


            return content.displayName

        } set: { newValue in

            guard case var .user(
                content
            ) = node.content
            else {

                return
            }


            content.displayName =
                newValue


            node.content =
                .user(
                    content
                )
        }
    }


    var userIDBinding:
        Binding<String> {

        Binding {

            guard case let .user(
                content
            ) = node.content
            else {

                return ""
            }


            return content.userID

        } set: { newValue in

            guard case var .user(
                content
            ) = node.content
            else {

                return
            }


            content.userID =
                newValue


            node.content =
                .user(
                    content
                )
        }
    }
}

// =====================================================
// MARK: - Activity Bindings
// =====================================================

private extension GameNodeEditorForm {

    var activityTitleBinding:
        Binding<String> {

        Binding {

            guard case let .activity(
                content
            ) = node.content
            else {

                return ""
            }


            return content.title

        } set: { newValue in

            guard case var .activity(
                content
            ) = node.content
            else {

                return
            }


            content.title =
                newValue


            node.content =
                .activity(
                    content
                )
        }
    }


    var activityIDBinding:
        Binding<String> {

        Binding {

            guard case let .activity(
                content
            ) = node.content
            else {

                return ""
            }


            return content.activityID

        } set: { newValue in

            guard case var .activity(
                content
            ) = node.content
            else {

                return
            }


            content.activityID =
                newValue


            node.content =
                .activity(
                    content
                )
        }
    }


    var activityDescriptionBinding:
        Binding<String> {

        Binding {

            guard case let .activity(
                content
            ) = node.content
            else {

                return ""
            }


            return content.description
                ?? ""

        } set: { newValue in

            guard case var .activity(
                content
            ) = node.content
            else {

                return
            }


            content.description =
                newValue
                    .isEmpty
                    ? nil
                    : newValue


            node.content =
                .activity(
                    content
                )
        }
    }
}

// =====================================================
// MARK: - Post Bindings
// =====================================================

private extension GameNodeEditorForm {

    var postSubjectBinding:
        Binding<String> {

        Binding {

            guard case let .post(
                content
            ) = node.content
            else {
                return ""
            }

            return content.snapshot?.subject
                ?? content.title

        } set: { newValue in

            guard case var .post(
                content
            ) = node.content
            else {
                return
            }

            content.title =
                newValue

            if var snapshot =
                content.snapshot {

                snapshot.subject =
                    newValue

                content.snapshot =
                    snapshot
            }

            node.content =
                .post(
                    content
                )
        }
    }


    var postImageURLsBinding:
        Binding<String> {

        Binding {

            guard
                case let .post(content) = node.content,
                let snapshot = content.snapshot
            else {
                return ""
            }

            return snapshot
                .postImageURLs
                .joined(
                    separator: "\n"
                )

        } set: { newValue in

            updatePostSnapshot { snapshot in

                snapshot.postImageURLs =
                    postMediaURLs(
                        from:
                            newValue
                    )

                synchronizePostMediaMetadata(
                    &snapshot
                )
            }
        }
    }


    var postVideoURLsBinding:
        Binding<String> {

        Binding {

            guard
                case let .post(content) = node.content,
                let snapshot = content.snapshot
            else {
                return ""
            }

            return snapshot
                .postVideoURLs
                .joined(
                    separator: "\n"
                )

        } set: { newValue in

            updatePostSnapshot { snapshot in

                snapshot.postVideoURLs =
                    postMediaURLs(
                        from:
                            newValue
                    )

                synchronizePostMediaMetadata(
                    &snapshot
                )
            }
        }
    }


    func postMediaURLs(
        from value: String
    ) -> [String] {

        value
            .components(
                separatedBy:
                    .newlines
            )
            .map {
                $0.trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )
            }
            .filter {
                !$0.isEmpty
                && $0.lowercased() != "none"
            }
    }


    func updatePostSnapshot(
        _ update: (inout PostNodeSnapshot) -> Void
    ) {

        guard case var .post(
            content
        ) = node.content,
              var snapshot = content.snapshot
        else {
            return
        }

        update(
            &snapshot
        )

        content.snapshot =
            snapshot

        content.title =
            snapshot.preferredTitle

        if let markerImageURL =
            snapshot.preferredMarkerImageURL {

            content.image =
                .remote(
                    urlString:
                        markerImageURL
                )

        } else {

            content.image =
                nil
        }

        node.content =
            .post(
                content
            )
    }


    func synchronizePostMediaMetadata(
        _ snapshot: inout PostNodeSnapshot
    ) {

        let gifCount =
            snapshot.postGIFMedia.isEmpty
            ? 0
            : 1

        snapshot.postMediaCount =
            snapshot.postImageURLs.count
            + snapshot.postVideoURLs.count
            + gifCount

        if let firstImage =
            snapshot.postImageURLs.first {

            snapshot.postMainMediaURL =
                firstImage

            snapshot.postMainMediaType =
                "image"

            return
        }

        if let firstVideo =
            snapshot.postVideoURLs.first {

            snapshot.postMainMediaURL =
                firstVideo

            snapshot.postMainMediaType =
                "video"

            return
        }

        if snapshot.postGIFMedia.isEmpty {

            snapshot.postMainMediaURL =
                ""

            snapshot.postMainMediaType =
                ""
        }
    }
}


// =====================================================
// MARK: - Media Bindings
// =====================================================

private extension GameNodeEditorForm {

    var mediaTitleBinding:
        Binding<String> {

        Binding {

            guard case let .media(
                content
            ) = node.content
            else {

                return ""
            }


            return content.title

        } set: { newValue in

            guard case var .media(
                content
            ) = node.content
            else {

                return
            }


            content.title =
                newValue


            node.content =
                .media(
                    content
                )
        }
    }


    var mediaIDBinding:
        Binding<String> {

        Binding {

            guard case let .media(
                content
            ) = node.content
            else {

                return ""
            }


            return content.mediaID

        } set: { newValue in

            guard case var .media(
                content
            ) = node.content
            else {

                return
            }


            content.mediaID =
                newValue


            node.content =
                .media(
                    content
                )
        }
    }


    var mediaTypeBinding:
        Binding<MediaNodeContent.MediaType> {

        Binding {

            guard case let .media(
                content
            ) = node.content
            else {

                return .image
            }


            return content.mediaType

        } set: { newValue in

            guard case var .media(
                content
            ) = node.content
            else {

                return
            }


            content.mediaType =
                newValue


            node.content =
                .media(
                    content
                )
        }
    }


    var mediaURLBinding:
        Binding<String> {

        Binding {

            guard case let .media(
                content
            ) = node.content
            else {

                return ""
            }


            return content.urlString
                ?? ""

        } set: { newValue in

            guard case var .media(
                content
            ) = node.content
            else {

                return
            }


            content.urlString =
                newValue
                    .isEmpty
                    ? nil
                    : newValue


            node.content =
                .media(
                    content
                )
        }
    }
}

// =====================================================
// MARK: - Hyperlink Bindings
// =====================================================

private extension GameNodeEditorForm {

    var hyperlinkTitleBinding:
        Binding<String> {

        Binding {

            guard case let .hyperlink(
                content
            ) = node.content
            else {

                return ""
            }


            return content.title

        } set: { newValue in

            guard case var .hyperlink(
                content
            ) = node.content
            else {

                return
            }


            content.title =
                newValue


            node.content =
                .hyperlink(
                    content
                )
        }
    }


    var hyperlinkURLBinding:
        Binding<String> {

        Binding {

            guard case let .hyperlink(
                content
            ) = node.content
            else {

                return ""
            }


            return content.urlString

        } set: { newValue in

            guard case var .hyperlink(
                content
            ) = node.content
            else {

                return
            }


            content.urlString =
                newValue


            node.content =
                .hyperlink(
                    content
                )
        }
    }
}

// =====================================================
// MARK: - Image Bindings
// =====================================================

private extension GameNodeEditorForm {

    var currentImage:
        GameNodeImage? {

        node.content.image
    }


    var imageSourceBinding:
        Binding<ImageSource> {

        Binding {

            switch currentImage {

            case nil:

                return .none


            case .asset:

                return .asset


            case .systemSymbol:

                return .none


            case .remote:

                return .remote
            }

        } set: { newSource in

            let existingValue =
                imageValue


            switch newSource {

            case .none:

                setNodeImage(
                    nil
                )


            case .asset:

                setNodeImage(
                    .asset(
                        name:
                            existingValue
                    )
                )


            case .remote:

                setNodeImage(
                    .remote(
                        urlString:
                            existingValue
                    )
                )
            }
        }
    }


    var imageValueBinding:
        Binding<String> {

        Binding {

            imageValue

        } set: { newValue in

            switch currentImage {

            case .asset:

                setNodeImage(
                    .asset(
                        name:
                            newValue
                    )
                )


            case .systemSymbol:

                // Legacy value. Choosing Asset or Remote replaces it.
                break


            case .remote:

                setNodeImage(
                    .remote(
                        urlString:
                            newValue
                    )
                )


            case nil:

                break
            }
        }
    }


    var imageValue:
        String {

        switch currentImage {

        case let .asset(
            name
        ):

            return name


        case .systemSymbol:

            return ""


        case let .remote(
            urlString
        ):

            return urlString


        case nil:

            return ""
        }
    }


    func setNodeImage(
        _ image:
            GameNodeImage?
    ) {

        switch node.content {

        case var .play(
            content
        ):

            content.image =
                image

            node.content =
                .play(
                    content
                )


        case var .user(
            content
        ):

            content.image =
                image

            node.content =
                .user(
                    content
                )


        case var .activity(
            content
        ):

            content.image =
                image

            node.content =
                .activity(
                    content
                )


        case var .post(
            content
        ):

            content.image =
                image

            node.content =
                .post(
                    content
                )


        case var .media(
            content
        ):

            content.image =
                image

            node.content =
                .media(
                    content
                )


        case var .hyperlink(
            content
        ):

            content.image =
                image

            node.content =
                .hyperlink(
                    content
                )
        }
    }
}

// =====================================================
// MARK: - Placement Bindings
// =====================================================

private extension GameNodeEditorForm {

    var coordinateProgressBinding:
        Binding<Double> {

        Binding {

            guard case let .coordinate(
                coordinate
            ) = node.placement
            else {

                return 50
            }


            return coordinate
                .progress
                .percent

        } set: { newProgress in

            guard case let .coordinate(
                coordinate
            ) = node.placement
            else {

                return
            }


            node.placement =
                .coordinate(
                    MapCoordinate(
                        time:
                            node.time,
                        progress:
                            MapProgress(
                                newProgress
                            )
                    )
                )
        }
    }


    var roadVertexIDBinding:
        Binding<String> {

        Binding {

            guard case let .roadVertex(
                vertexID
            ) = node.placement
            else {

                return ""
            }


            return vertexID.rawValue

        } set: { newValue in

            let vertexID =
                RoadVertexID(
                    newValue
                )


            node.setPlacement(
                .roadVertex(
                    vertexID
                ),
                resolvedRoadTime:
                    roadGraph
                        .vertex(
                            id:
                                vertexID
                        )?
                        .coordinate
                        .time
            )
        }
    }
}

// =====================================================
// MARK: - Time Binding
// =====================================================

private extension GameNodeEditorForm {

    var nodeTimeBinding:
        Binding<Date> {

        Binding {

            referenceDate(
                for:
                    node.time
            )

        } set: { newDate in


            let calendar =
                Calendar.current


            let components =
                calendar.dateComponents(
                    [
                        .hour,
                        .minute,
                        .second
                    ],
                    from:
                        newDate
                )


            let hour =
                components.hour
                ?? 0


            let minute =
                components.minute
                ?? 0


            let second =
                components.second
                ?? 0


            let seconds =
                TimeInterval(
                    hour * 3600
                    +
                    minute * 60
                    +
                    second
                )


            let newTime =
                DayTime(
                    secondsFromMidnight:
                        seconds
                )


            node.setTime(
                newTime
            )
        }
    }


    func referenceDate(
        for time:
            DayTime
    ) -> Date {

        let totalSeconds =
            Int(
                time.secondsFromMidnight
            )


        let hour =
            min(
                totalSeconds / 3600,
                23
            )


        let minute =
            (
                totalSeconds % 3600
            )
            /
            60


        let second =
            totalSeconds
            %
            60


        var components =
            DateComponents()


        components.year =
            2001

        components.month =
            1

        components.day =
            1

        components.hour =
            hour

        components.minute =
            minute

        components.second =
            second


        return Calendar.current.date(
            from:
                components
        )
        ??
        Date()
    }
}

private extension MediaNodeContent.MediaType {

    static var allEditorCases:
        [Self] {

        [
            .image,
            .video,
            .gif
        ]
    }
}

// =====================================================
// MARK: - Free Coordinate Editor
// =====================================================

private extension GameNodeEditorForm {

    var freeCoordinateEditor:
        some View {

        Group {

            HStack {

                Text(
                    "Progress"
                )


                Spacer()


                TextField(
                    "50",
                    value:
                        coordinateProgressBinding,
                    format:
                        .number
                        .precision(
                            .fractionLength(
                                1
                            )
                        )
                )
                .keyboardType(
                    .decimalPad
                )
                .multilineTextAlignment(
                    .trailing
                )
                .frame(
                    width:
                        85
                )


                Text(
                    "%"
                )
                .foregroundStyle(
                    .secondary
                )
            }


            if let coordinate =
                currentMapCoordinate {

                placementSummary(
                    coordinate:
                        coordinate
                )
            }
        }
    }
}

// =====================================================
// MARK: - Road Vertex Editor
// =====================================================

private extension GameNodeEditorForm {

    @ViewBuilder
    func roadVertexEditor(
        vertexID:
            RoadVertexID
    ) -> some View {

        if let vertex =
            roadGraph.vertex(
                id:
                    vertexID
            )
        {

            LabeledContent(
                "Kind",
                value:
                    vertex.kind
                        .displayName
            )


            LabeledContent(
                "Time",
                value:
                    vertex.coordinate
                        .time
                        .displayClockString
            )


            LabeledContent(
                "Progress"
            ) {

                Text(
                    vertex.coordinate
                        .progress
                        .percent,
                    format:
                        .number
                        .precision(
                            .fractionLength(
                                1
                            )
                        )
                )

                +
                Text("%")
            }


            LabeledContent(
                "Connected Roads",
                value:
                    "\(roadGraph.degree(of: vertex.id))"
            )


            Button {

                isShowingRoadVertexPicker =
                    true

            } label: {

                Label(
                    "Choose Intersection",
                    systemImage:
                        "point.3.connected.trianglepath.dotted"
                )
            }


        } else {

            Label(
                "The selected intersection no longer exists.",
                systemImage:
                    "exclamationmark.triangle.fill"
            )
            .foregroundStyle(
                .orange
            )


            Button(
                "Choose Another Intersection"
            ) {

                isShowingRoadVertexPicker =
                    true
            }
        }
    }
}

private extension RoadVertexKind {

    var displayName:
        String {

        switch self {

        case .intersection:

            return "Intersection"


        case .junction:

            return "Junction"


        case .circleEntry:

            return "Roundabout Entry"


        case .circleExit:

            return "Roundabout Exit"


        case .culDeSacEnd:

            return "Cul-de-sac"


        case .control:

            return "Road Control Point"
        }
    }
}

// =====================================================
// MARK: - Placement Type
// =====================================================

private extension GameNodeEditorForm {

    var placementTypeBinding:
        Binding<PlacementType> {

        Binding {

            switch node.placement {

            case .coordinate:

                return .coordinate


            case .roadVertex:

                return .roadVertex
            }

        } set: { newType in

            switch (
                node.placement,
                newType
            ) {

            // =========================================
            // Already Free
            // =========================================

            case (
                .coordinate,
                .coordinate
            ):

                break


            // =========================================
            // Already Attached
            // =========================================

            case (
                .roadVertex,
                .roadVertex
            ):

                break


            // =========================================
            // Road Vertex -> Free Coordinate
            // =========================================

            case let (
                .roadVertex(
                    vertexID
                ),
                .coordinate
            ):

                convertRoadVertexToCoordinate(
                    vertexID:
                        vertexID
                )


            // =========================================
            // Free Coordinate -> Nearest Vertex
            // =========================================

            case let (
                .coordinate(
                    coordinate
                ),
                .roadVertex
            ):

                attachToNearestRoadVertex(
                    from:
                        coordinate
                )
            }
        }
    }
}

private extension GameNodeEditorForm {

    func convertRoadVertexToCoordinate(
        vertexID:
            RoadVertexID
    ) {

        guard let vertex =
            roadGraph.vertex(
                id:
                    vertexID
            )
        else {

            return
        }


        node.setPlacement(
            .coordinate(
                vertex.coordinate
            )
        )
    }
}

private extension GameNodeEditorForm {

    func attachToNearestRoadVertex(
        from coordinate:
            MapCoordinate
    ) {

        guard let vertex =
            nearestAttachableVertex(
                to:
                    coordinate
            )
        else {

            return
        }


        node.setPlacement(
            .roadVertex(
                vertex.id
            ),
            resolvedRoadTime:
                vertex.coordinate.time
        )
    }


    func nearestAttachableVertex(
        to coordinate:
            MapCoordinate
    ) -> RoadVertex? {

        let target =
            MapCoordinateConverter
                .worldPoint(
                    for:
                        coordinate
                )
                .cgPoint


        return roadGraph
            .vertices
            .filter {

                isAttachableVertex(
                    $0
                )
            }
            .min { lhs, rhs in

                distance(
                    from:
                        lhs.worldPoint.cgPoint,
                    to:
                        target
                )
                <
                distance(
                    from:
                        rhs.worldPoint.cgPoint,
                    to:
                        target
                )
            }
    }


    func distance(
        from lhs:
            CGPoint,
        to rhs:
            CGPoint
    ) -> CGFloat {

        hypot(
            lhs.x - rhs.x,
            lhs.y - rhs.y
        )
    }
}

private extension GameNodeEditorForm {

    func isAttachableVertex(
        _ vertex:
            RoadVertex
    ) -> Bool {

        switch vertex.kind {

        case .intersection,
             .junction,
             .circleEntry,
             .circleExit,
             .culDeSacEnd:

            return true


        case .control:

            /*
             Internal geometry control points shouldn't
             normally be exposed as places where the user
             can attach application content.
             */

            return false
        }
    }
}

private extension GameNodeEditorForm {

    var currentMapCoordinate:
        MapCoordinate? {

        GameNodePlacementResolver
            .mapCoordinate(
                for:
                    node,
                graph:
                    roadGraph
            )
    }


    var selectedRoadVertexID:
        RoadVertexID? {

        guard case let .roadVertex(
            vertexID
        ) = node.placement
        else {

            return nil
        }


        return vertexID
    }
}

private extension GameNodeEditorForm {

    func placementSummary(
        coordinate:
            MapCoordinate
    ) -> some View {

        HStack(
            spacing:
                8
        ) {

            Image(
                systemName:
                    "map.fill"
            )


            Text(
                coordinate
                    .time
                    .displayClockString
            )


            Text(
                "•"
            )


            Text(
                coordinate
                    .progress
                    .percent,
                format:
                    .number
                    .precision(
                        .fractionLength(
                            1
                        )
                    )
            )


            Text(
                "%"
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


// =====================================================
// MARK: - Road Relationship
// =====================================================

private extension GameNodeEditorForm {

    @ViewBuilder
    var roadRelationshipSection:
        some View {

        Section(
            "Road Relationship"
        ) {

            switch roadRelationship {

            // =========================================
            // Off Road
            // =========================================

            case .offRoad:

                Label(
                    "Not On a Road",
                    systemImage:
                        "circle.dashed"
                )


                Text(
                    "This node is a normal object on the time/progress plane and is not currently positioned on road geometry."
                )
                .font(
                    .caption
                )
                .foregroundStyle(
                    .secondary
                )


            // =========================================
            // Vertex
            // =========================================

            case let .vertex(
                vertexID
            ):

                Label(
                    "At Road Intersection",
                    systemImage:
                        "point.3.connected.trianglepath.dotted"
                )
                .foregroundStyle(
                    .green
                )


                if let vertex =
                    roadGraph.vertex(
                        id:
                            vertexID
                    )
                {

                    LabeledContent(
                        "Intersection",
                        value:
                            roadVertexTitle(
                                vertex
                            )
                    )


                    LabeledContent(
                        "Time",
                        value:
                            vertex.coordinate
                                .time
                                .displayClockString
                    )


                    LabeledContent(
                        "Progress"
                    ) {

                        Text(
                            vertex.coordinate
                                .progress
                                .percent,
                            format:
                                .number
                                .precision(
                                    .fractionLength(
                                        1
                                    )
                                )
                        )

                        Text("%")
                    }
                }


            // =========================================
            // Road Edge
            // =========================================

                // =========================================
                // Road Edge
                // =========================================

                case let .edge(
                    edgeID,
                    fraction
                ):

                    Label(
                        "On Road",
                        systemImage:
                            "road.lanes"
                    )
                    .foregroundStyle(
                        .green
                    )


                    if let edge =
                        roadGraph.edge(
                            id:
                                edgeID
                        )
                    {

                        LabeledContent(
                            "Road",
                            value:
                                edge.attributes
                                    .displayName
                                ??
                                "Unnamed Road"
                        )


                        LabeledContent(
                            "Class",
                            value:
                                edge.roadClass
                                    .rawValue
                                    .capitalized
                        )


                        LabeledContent(
                            "Traversable",
                            value:
                                edge.attributes
                                    .isTraversable
                                ? "Yes"
                                : "No"
                        )


                        LabeledContent(
                            "Road Position"
                        ) {

                            Text(
                                fraction * 100,
                                format:
                                    .number
                                    .precision(
                                        .fractionLength(
                                            1
                                        )
                                    )
                            )

                            Text("%")
                        }
                    }
            }


            Divider()


            routeEligibilityView
        }
    }
}

private extension GameNodeEditorForm {

    var roadRelationship:
        GameNodeRoadRelationship {

        GameNodeRoadRelationshipResolver()
            .resolve(
                node:
                    node,
                graph:
                    roadGraph
            )
    }


    var routeAnchor:
        GameNodeRouteAnchor? {

        GameNodeRouteAnchorResolver()
            .resolve(
                node:
                    node,
                graph:
                    roadGraph
            )
    }


    @ViewBuilder
    var routeEligibilityView:
        some View {

        if routeAnchor != nil {

            Label(
                "Available to Road Routing",
                systemImage:
                    "checkmark.circle.fill"
            )
            .foregroundStyle(
                .green
            )


        } else if case .offRoad =
            roadRelationship
        {

            Label(
                "No Road Route Connection",
                systemImage:
                    "circle"
            )
            .foregroundStyle(
                .secondary
            )


            Text(
                "This is expected for nodes that do not lie on a road."
            )
            .font(
                .caption
            )
            .foregroundStyle(
                .secondary
            )


        } else {

            Label(
                "Road Is Not Routable",
                systemImage:
                    "exclamationmark.triangle.fill"
            )
            .foregroundStyle(
                .orange
            )
        }
    }
}

private extension GameNodeEditorForm {

    func roadVertexTitle(
        _ vertex:
            RoadVertex
    ) -> String {

        let names =
            roadGraph
                .incidentEdges(
                    to:
                        vertex.id,
                    traversableOnly:
                        false
                )
                .compactMap {

                    $0.attributes
                        .displayName
                }
                .filter {

                    !$0.isEmpty
                }


        let uniqueNames =
            Array(
                Set(
                    names
                )
            )
            .sorted()


        if !uniqueNames.isEmpty {

            return uniqueNames
                .joined(
                    separator:
                        " / "
                )
        }


        switch vertex.kind {

        case .intersection:

            return "Intersection"


        case .junction:

            return "Junction"


        case .circleEntry:

            return "Roundabout Entry"


        case .circleExit:

            return "Roundabout Exit"


        case .culDeSacEnd:

            return "Cul-de-sac"


        case .control:

            return "Road Point"
        }
    }
}
