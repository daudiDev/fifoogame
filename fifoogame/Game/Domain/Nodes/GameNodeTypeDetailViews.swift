//
//  GameNodeTypeDetailViews.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/24/26.
//



import SwiftUI
import UIKit
import Foundation


struct GameNodeTypeDetailViews: View {
    var body: some View {
        Text("Hello, World!")
    }
}


// =====================================================
// MARK: - Shared Node Image
// =====================================================

private struct NodeDetailImage: View {

    let kind: GameNodeKind
    let image: GameNodeImage?
    var size: CGFloat = 76


    var body: some View {

        resolvedImage
            .frame(
                width: size,
                height: size
            )
            .clipShape(
                Circle()
            )
            .overlay {

                Circle()
                    .stroke(
                        .white.opacity(0.25),
                        lineWidth: 1.5
                    )
            }
    }


    @ViewBuilder
    private var resolvedImage: some View {

        switch image {

        case let .asset(name):

            if let uiImage = UIImage(
                named: name
            ) {

                Image(
                    uiImage: uiImage
                )
                .resizable()
                .scaledToFill()

            } else {

                placeholder
            }


        case let .remote(urlString):

            if let url = URL(
                string: urlString
            ) {

                AsyncImage(
                    url: url
                ) { phase in

                    switch phase {

                    case .empty:

                        ZStack {
                            placeholder
                            ProgressView()
                                .tint(.white)
                        }

                    case let .success(image):

                        image
                            .resizable()
                            .scaledToFill()

                    case .failure:

                        placeholder

                    @unknown default:

                        placeholder
                    }
                }

            } else {

                placeholder
            }


        case .systemSymbol,
             nil:

            // Legacy system-symbol data intentionally resolves to the
            // node-type raster placeholder instead of rendering an icon.
            placeholder
        }
    }


    private var placeholder: some View {

        Image(
            uiImage:
                GameNodePlaceholderImage.image(
                    for: kind
                )
        )
        .resizable()
        .scaledToFill()
    }
}



// =====================================================
// MARK: - User
// =====================================================

struct UserNodeDetailView: View {

    let content: UserNodeContent

    var body: some View {

        ScrollView {

            VStack(
                alignment: .leading,
                spacing: 18
            ) {

                HStack(
                    spacing: 14
                ) {

                    NodeDetailImage(
                        kind: .user,
                        image: content.image,
                        size: 80
                    )

                    VStack(
                        alignment: .leading,
                        spacing: 4
                    ) {

                        Text(
                            content.profile?.preferredDisplayName
                            ?? content.displayName
                        )
                        .font(.title2)
                        .fontWeight(.semibold)

                        if let username =
                            content.profile?.username,
                           !username.isEmpty {

                            Text(
                                username.hasPrefix("@")
                                ? username
                                : "@\(username)"
                            )
                            .foregroundStyle(.secondary)
                        }
                    }
                }


                if let profile =
                    content.profile {

                    if !profile.goal.isEmpty {
                        Text(profile.goal)
                    }

                    VStack(
                        alignment: .leading,
                        spacing: 8
                    ) {

                        HStack {
                            Text("Progress")
                            Spacer()
                            Text("\(profile.progressPercent)%")
                                .fontWeight(.semibold)
                                .monospacedDigit()
                        }

                        ProgressView(
                            value: profile.progressFraction
                        )
                    }

                    LabeledContent(
                        "Followers",
                        value: "\(profile.inFollowersCount)"
                    )

                    LabeledContent(
                        "Following",
                        value: "\(profile.outFollowersCount)"
                    )

                    if !profile.lastActive.isEmpty {
                        LabeledContent(
                            "Last Active",
                            value: profile.lastActive
                        )
                    }
                }


                Divider()

                Text("User ID")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(
                    content.userID
                )
                .font(.caption.monospaced())
            }
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
            .padding()
        }
    }
}


private func activityKind(
    for content: ActivityNodeContent
) -> GameNodeKind {
    switch content.resolvedActivityType {
    case .meal: return .activityMeal
    case .workout: return .activityWorkout
    case .task: return .activityTask
    }
}


// =====================================================
// MARK: - Activity
// =====================================================

struct ActivityNodeDetailView: View {

    let content: ActivityNodeContent

    var body: some View {

        ScrollView {

            VStack(
                alignment: .leading,
                spacing: 18
            ) {

                NodeDetailImage(
                    kind: activityKind(for: content),
                    image: content.image,
                    size: 72
                )

                Text(
                    content.title
                )
                .font(.title2)
                .fontWeight(.bold)

                HStack(spacing: 8) {

                    Text(
                        content.activityTypeDisplayName
                    )
                    .font(.caption)
                    .fontWeight(.semibold)

                    if !content.status.isEmpty {

                        Text("•")
                            .foregroundStyle(.secondary)

                        Text(
                            content.status
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }

                if !content.startTime.isEmpty || !content.endTime.isEmpty {

                    LabeledContent("Time") {

                        Text(
                            [
                                content.startTime,
                                content.endTime
                            ]
                            .filter { !$0.isEmpty }
                            .joined(separator: " – ")
                        )
                    }
                }

                if !content.location.isEmpty {

                    LabeledContent(
                        "Location",
                        value: content.location
                    )
                }

                if let description = content.description {
                    Text(description)
                }

                Divider()

                Text("Activity ID")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(
                    content.activityID
                )
                .font(.caption.monospaced())
            }
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
            .padding()
        }
    }
}


// =====================================================
// MARK: - Post
// =====================================================

struct PostNodeDetailView: View {

    let content: PostNodeContent

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 18
        ) {

            NodeDetailImage(
                kind: .post,
                image: content.image,
                size: 68
            )

            Text(
                content.title
            )
            .font(.title2)
            .fontWeight(.bold)

            Divider()

            Text("Post ID")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(
                content.postID
            )
            .font(.caption.monospaced())

            Spacer()
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .padding()
    }
}


// =====================================================
// MARK: - Hyperlink
// =====================================================

struct HyperlinkNodeDetailView: View {

    let content: HyperlinkNodeContent

    var body: some View {

        VStack(
            spacing: 16
        ) {

            NodeDetailImage(
                kind: .hyperlink,
                image: content.image,
                size: 68
            )

            Text(
                content.title
            )
            .font(.title2)

            Text(
                content.urlString
            )
            .font(.caption.monospaced())
            .foregroundStyle(.secondary)
        }
        .padding()
    }
}


// =====================================================
// MARK: - Media Metadata
// =====================================================

struct MediaNodeMetadataView: View {

    let content: MediaNodeContent

    var body: some View {

        VStack(
            spacing: 16
        ) {

            NodeDetailImage(
                kind: .media,
                image: content.image,
                size: 72
            )

            Text(
                content.title
            )
            .font(.title2)

            Text(
                content.mediaType.rawValue.capitalized
            )
            .foregroundStyle(.secondary)
        }
        .padding()
    }
}


// =====================================================
// MARK: - ActivityWorkout Experience (Pass 5.29)
// =====================================================

/// One selectable workout shown by the reusable Browse Workouts sheet.
/// The local catalog is development scaffolding; the view intentionally
/// consumes `ActivityWorkoutNodeSummary` so server-backed results can replace
/// these fixtures without changing the ActivityWorkout presentation flow.
struct ActivityWorkoutBrowseOption:
    Identifiable,
    Equatable {

    let summary: ActivityWorkoutNodeSummary

    var id: String {
        summary.workoutID
    }
}


enum ActivityWorkoutBrowseCatalog {

    static var options: [ActivityWorkoutBrowseOption] {
        [
            ActivityWorkoutBrowseOption(
                summary: ActivityWorkoutNodeSummary(
                    activityWorkoutID: UUID().uuidString,
                    workoutID: "class-strength-conditioning",
                    title: "Strength & Conditioning Class",
                    location: "Harbor Fitness Studio",
                    categories: ["Strength", "Conditioning"],
                    selectedWorkoutTime: "6:00 PM",
                    durationInSeconds: 3_000,
                    durationText: "50 min",
                    distance: "",
                    workoutFormat: "Guided / Class",
                    rating: "4.9",
                    workoutType: .guidedClass,
                    imageURLs: ["https://picsum.photos/seed/fifoo-strength-class/1200/1800"],
                    description: "Coach-led strength and conditioning class with progressive circuits.",
                    phone: "(410) 555-0142",
                    website: "https://harborfitness.example/classes",
                    trainer: ActivityTrainerNodeSummary(
                        userID: "trainer-maya",
                        name: "Maya Chen",
                        location: "Harbor Fitness Studio",
                        userImageURL: "",
                        userDescription: "Strength and conditioning coach",
                        conversationID: "",
                        onlineStatus: "Online",
                        rating: "4.9"
                    ),
                    workoutStatus: "Scheduled"
                )
            ),
            ActivityWorkoutBrowseOption(
                summary: ActivityWorkoutNodeSummary(
                    activityWorkoutID: UUID().uuidString,
                    workoutID: "class-morning-yoga",
                    title: "Morning Yoga Flow",
                    location: "Riverside Yoga Room",
                    categories: ["Yoga", "Mobility"],
                    selectedWorkoutTime: "7:00 AM",
                    durationInSeconds: 2_700,
                    durationText: "45 min",
                    distance: "",
                    workoutFormat: "Guided / Class",
                    rating: "4.8",
                    workoutType: .guidedClass,
                    imageURLs: ["https://picsum.photos/seed/fifoo-yoga-class/1200/1800"],
                    description: "Instructor-led mobility, breathwork and full-body yoga flow.",
                    phone: "(410) 555-0188",
                    website: "https://riversideyoga.example/schedule",
                    trainer: ActivityTrainerNodeSummary(
                        userID: "trainer-elena",
                        name: "Elena Brooks",
                        location: "Riverside Yoga Room",
                        userImageURL: "",
                        userDescription: "Yoga instructor",
                        conversationID: "",
                        onlineStatus: "Offline",
                        rating: "4.8"
                    ),
                    workoutStatus: "Scheduled"
                )
            ),
            ActivityWorkoutBrowseOption(
                summary: ActivityWorkoutNodeSummary(
                    activityWorkoutID: UUID().uuidString,
                    workoutID: "class-hiit",
                    title: "Evening HIIT",
                    location: "Downtown Training Lab",
                    categories: ["HIIT", "Cardio"],
                    selectedWorkoutTime: "5:30 PM",
                    durationInSeconds: 2_400,
                    durationText: "40 min",
                    distance: "",
                    workoutFormat: "Guided / Class",
                    rating: "4.7",
                    workoutType: .guidedClass,
                    imageURLs: ["https://picsum.photos/seed/fifoo-hiit-class/1200/1800"],
                    description: "Fast-paced coach-led intervals with bodyweight and conditioning work.",
                    phone: "(410) 555-0164",
                    website: "https://downtowntraining.example/hiit",
                    trainer: ActivityTrainerNodeSummary(
                        userID: "trainer-marcus",
                        name: "Marcus Reed",
                        location: "Downtown Training Lab",
                        userImageURL: "",
                        userDescription: "HIIT coach",
                        conversationID: "",
                        onlineStatus: "Online",
                        rating: "4.7"
                    ),
                    workoutStatus: "Scheduled"
                )
            ),
            ActivityWorkoutBrowseOption(
                summary: ActivityWorkoutNodeSummary(
                    activityWorkoutID: UUID().uuidString,
                    workoutID: "independent-full-body",
                    title: "Full Body Workout",
                    location: "Wherever you train",
                    categories: ["Strength", "Cardio"],
                    selectedWorkoutTime: "",
                    durationInSeconds: 2_700,
                    durationText: "45 min",
                    distance: "",
                    workoutFormat: "Independent",
                    rating: "4.8",
                    workoutType: .independent,
                    imageURLs: ["https://picsum.photos/seed/fifoo-full-body/1200/1800"],
                    description: "A Fifoo Play full-body strength and cardio workout."
                )
            ),
            ActivityWorkoutBrowseOption(
                summary: ActivityWorkoutNodeSummary(
                    activityWorkoutID: UUID().uuidString,
                    workoutID: "independent-upper-body",
                    title: "Upper Body Strength",
                    location: "Wherever you train",
                    categories: ["Strength", "Upper Body"],
                    selectedWorkoutTime: "",
                    durationInSeconds: 2_400,
                    durationText: "40 min",
                    distance: "",
                    workoutFormat: "Independent",
                    rating: "4.7",
                    workoutType: .independent,
                    imageURLs: ["https://picsum.photos/seed/fifoo-upper-body/1200/1800"],
                    description: "Independent Fifoo Play upper-body strength session."
                )
            ),
            ActivityWorkoutBrowseOption(
                summary: ActivityWorkoutNodeSummary(
                    activityWorkoutID: UUID().uuidString,
                    workoutID: "independent-cardio-core",
                    title: "Cardio + Core",
                    location: "Wherever you train",
                    categories: ["Cardio", "Core"],
                    selectedWorkoutTime: "",
                    durationInSeconds: 2_100,
                    durationText: "35 min",
                    distance: "",
                    workoutFormat: "Independent",
                    rating: "4.6",
                    workoutType: .independent,
                    imageURLs: ["https://picsum.photos/seed/fifoo-cardio-core/1200/1800"],
                    description: "Independent Fifoo Play cardio intervals and core work."
                )
            )
        ]
    }
}


/// Applies a Browse Workouts result to the ActivityWorkout node while keeping
/// the Activity transport envelope intact.
func activityWorkoutApplyingSelection(
    _ option: ActivityWorkoutBrowseOption,
    to originalNode: GameMapNode,
    roadGraph: RoadGraph
) -> GameMapNode {

    var node = originalNode

    guard case var .activity(content) = node.content else {
        return node
    }

    var summary = option.summary
    let workoutType = summary.resolvedWorkoutType

    if workoutType == .independent {
        // Independent workouts keep the user's current scheduled activity time.
        let preservedTime =
            content.startTime.isEmpty
            ? node.time.displayClockString
            : content.startTime

        content.startTime = preservedTime
        summary.selectedWorkoutTime = preservedTime

        if summary.durationInSeconds > 0 {
            content.endTime = activityWorkoutEndClockString(
                start: preservedTime,
                durationInSeconds: summary.durationInSeconds
            ) ?? content.endTime
        }
    } else {
        // A class owns its schedule. Selecting another class is the only way
        // to change the class time.
        content.startTime = summary.selectedWorkoutTime

        if summary.durationInSeconds > 0 {
            content.endTime = activityWorkoutEndClockString(
                start: summary.selectedWorkoutTime,
                durationInSeconds: summary.durationInSeconds
            ) ?? content.endTime
        }
    }

    content.title = summary.title
    content.location = summary.location
    content.description = summary.description
    content.activityType = ActivityNodeContent.ActivityType.workout.rawValue
    content.workout = summary

    if let firstImage = summary.imageURLs?.first,
       !firstImage.isEmpty {
        content.image = .remote(urlString: firstImage)
    }

    node.content = .activity(content)

    if let time = activityWorkoutParseClockString(content.startTime) {
        activityWorkoutMoveNode(
            &node,
            to: time,
            roadGraph: roadGraph
        )
    }

    return node
}


/// Updates only the user-controlled schedule of an independent Fifoo Play
/// ActivityWorkout. Class scheduling never calls this helper.
func activityWorkoutUpdatingIndependentSchedule(
    _ originalNode: GameMapNode,
    to time: DayTime,
    roadGraph: RoadGraph
) -> GameMapNode {

    var node = originalNode

    guard case var .activity(content) = node.content,
          var workout = content.workout,
          workout.resolvedWorkoutType == .independent else {
        return node
    }

    let clock = time.displayClockString

    content.startTime = clock
    workout.selectedWorkoutTime = clock

    if workout.durationInSeconds > 0 {
        content.endTime = activityWorkoutEndClockString(
            start: clock,
            durationInSeconds: workout.durationInSeconds
        ) ?? content.endTime
    }

    content.workout = workout
    node.content = .activity(content)

    activityWorkoutMoveNode(
        &node,
        to: time,
        roadGraph: roadGraph
    )

    return node
}


private func activityWorkoutMoveNode(
    _ node: inout GameMapNode,
    to time: DayTime,
    roadGraph: RoadGraph
) {

    switch node.placement {
    case let .roadVertex(vertexID):
        if let vertex = roadGraph.vertex(id: vertexID) {
            node.setPlacement(
                .coordinate(
                    MapCoordinate(
                        time: time,
                        progress: vertex.coordinate.progress
                    )
                )
            )
        } else {
            node.setTime(time)
        }

    case .coordinate:
        node.setTime(time)
    }
}


private func activityWorkoutEndClockString(
    start: String,
    durationInSeconds: Int
) -> String? {

    guard let startTime = activityWorkoutParseClockString(start) else {
        return nil
    }

    let seconds = min(
        startTime.secondsFromMidnight + TimeInterval(max(0, durationInSeconds)),
        DayTime.secondsPerDay - 60
    )

    return DayTime(
        secondsFromMidnight: seconds
    )
    .displayClockString
}


private func activityWorkoutParseClockString(
    _ value: String
) -> DayTime? {

    let cleaned = value.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !cleaned.isEmpty else { return nil }

    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)

    for format in [
        "h:mm a",
        "hh:mm a",
        "h:mm:ss a",
        "hh:mm:ss a",
        "H:mm",
        "HH:mm",
        "H:mm:ss",
        "HH:mm:ss"
    ] {
        formatter.dateFormat = format

        guard let date = formatter.date(from: cleaned) else {
            continue
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = formatter.timeZone

        let components = calendar.dateComponents(
            [.hour, .minute, .second],
            from: date
        )

        return DayTime(
            secondsFromMidnight: TimeInterval(
                (components.hour ?? 0) * 3_600
                + (components.minute ?? 0) * 60
                + (components.second ?? 0)
            )
        )
    }

    return nil
}


// =====================================================
// MARK: Guided / Class Workout Full-screen Details
// =====================================================

struct ActivityWorkoutClassExperienceView: View {

    let node: GameMapNode
    let roadGraph: RoadGraph
    let onUpdate: (GameMapNode) -> Void
    let onSwitchToIndependent: (GameMapNode) -> Void

    @State private var draft: GameMapNode
    @State private var isShowingBrowseWorkouts = false
    @State private var isShowingFixedTimeAlert = false

    @Environment(\.dismiss) private var dismiss

    init(
        node: GameMapNode,
        roadGraph: RoadGraph,
        onUpdate: @escaping (GameMapNode) -> Void,
        onSwitchToIndependent: @escaping (GameMapNode) -> Void
    ) {
        self.node = node
        self.roadGraph = roadGraph
        self.onUpdate = onUpdate
        self.onSwitchToIndependent = onSwitchToIndependent
        _draft = State(initialValue: node)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ActivityWorkoutBackgroundImage(
                    image: workoutImage
                )

                // Keep the class artwork full-bleed, but place a persistent
                // dark veil between the image and every foreground detail so
                // class metadata remains legible regardless of the photo.
                Color.black
                    .opacity(0.34)
                    .ignoresSafeArea()

                LinearGradient(
                    colors: [
                        Color.black.opacity(0.62),
                        Color.black.opacity(0.26),
                        Color.black.opacity(0.86)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: geometry.size.height < 700 ? 12 : 18) {
                    classHeader
                    classTypeBadge
                    fixedClassTimeRow

                    ScrollView(showsIndicators: false) {
                        classDetails
                            .padding(.vertical, 4)
                    }

                    TimelineView(
                        .periodic(
                            from: .now,
                            by: 30
                        )
                    ) { context in
                        classBottomControls(
                            now: context.date
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, geometry.size.height < 700 ? 54 : 72)
                .padding(.bottom, geometry.size.height < 700 ? 34 : 48)
                .frame(
                    width: geometry.size.width,
                    height: geometry.size.height,
                    alignment: .top
                )
            }
            .frame(
                width: geometry.size.width,
                height: geometry.size.height
            )
            .clipped()
        }
        .ignoresSafeArea()
        .alert(
            "Class time is fixed",
            isPresented: $isShowingFixedTimeAlert
        ) {
            Button("Browse Workouts") {
                isShowingBrowseWorkouts = true
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text(
                "Workout classes use the class schedule. To choose a different time, browse available workouts and select another class."
            )
        }
        .sheet(
            isPresented: $isShowingBrowseWorkouts
        ) {
            ActivityWorkoutBrowseSheet(
                selectedWorkoutID: workout?.workoutID
            ) { option in
                selectWorkout(option)
            }
        }
    }
}


private extension ActivityWorkoutClassExperienceView {

    var activityContent: ActivityNodeContent? {
        guard case let .activity(content) = draft.content,
              content.resolvedActivityType == .workout else {
            return nil
        }

        return content
    }

    var workout: ActivityWorkoutNodeSummary? {
        activityContent?.workout
    }

    var workoutImage: GameNodeImage? {
        if let image = activityContent?.image {
            return image
        }

        if let imageURL = workout?.imageURLs?.first,
           !imageURL.isEmpty {
            return .remote(urlString: imageURL)
        }

        return nil
    }

    var classHeader: some View {
        HStack(spacing: 14) {
            Text(workout?.title ?? activityContent?.title ?? "Workout Class")
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.75)

            Spacer()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.headline.weight(.bold))
                    .frame(width: 42, height: 42)
                    .background(.black.opacity(0.30), in: Circle())
                    .foregroundStyle(.white)
            }
        }
    }

    var classTypeBadge: some View {
        HStack(spacing: 8) {
            Image(systemName: "person.2.fill")
            Text("Guided / Class")
                .fontWeight(.semibold)

            Spacer()

            if let status = workout?.workoutStatus,
               !status.isEmpty {
                Text(status)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.white.opacity(0.12), in: Capsule())
            }
        }
        .font(.subheadline)
        .foregroundStyle(.white.opacity(0.92))
    }

    var fixedClassTimeRow: some View {
        Button {
            isShowingFixedTimeAlert = true
        } label: {
            HStack(spacing: 12) {
                workoutClassTimeCell(
                    title: "Start",
                    value: activityContent?.startTime.isEmpty == false
                        ? (activityContent?.startTime ?? "")
                        : (workout?.selectedWorkoutTime ?? "Time unavailable")
                )

                Image(systemName: "lock.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.72))

                workoutClassTimeCell(
                    title: "End",
                    value: activityContent?.endTime.isEmpty == false
                        ? (activityContent?.endTime ?? "")
                        : durationDisplay
                )
            }
            .padding(12)
            .background(.black.opacity(0.28), in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    func workoutClassTimeCell(
        title: String,
        value: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title.uppercased())
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white.opacity(0.62))

            Text(value.isEmpty ? "—" : value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var classDetails: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let description = workout?.description,
               !description.isEmpty {
                Text(description)
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.90))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            workoutDetailCard(
                title: "Location",
                value: workout?.location.isEmpty == false
                    ? (workout?.location ?? "")
                    : (activityContent?.location ?? "Location not provided"),
                systemImage: "mappin.and.ellipse"
            )

            workoutDetailCard(
                title: "Duration",
                value: durationDisplay,
                systemImage: "clock.fill"
            )

            HStack(alignment: .top, spacing: 10) {
                workoutCompactDetailCard(
                    title: "Class",
                    value: workout?.categories.isEmpty == false
                        ? (workout?.categories.joined(separator: " • ") ?? "Class")
                        : "Class",
                    systemImage: "figure.run"
                )

                workoutCompactDetailCard(
                    title: "Trainer",
                    value: workout?.trainer?.name.isEmpty == false
                        ? (workout?.trainer?.name ?? "Trainer")
                        : "Trainer not listed",
                    systemImage: "person.crop.circle.fill"
                )
            }

            classContactRow

            if let participants = workout?.participants,
               !participants.isEmpty {
                workoutDetailCard(
                    title: "Participants",
                    value: "\(participants.count) attending",
                    systemImage: "person.3.fill"
                )
            }
        }
    }

    func workoutDetailCard(
        title: String,
        value: String,
        systemImage: String
    ) -> some View {
        HStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.headline.weight(.semibold))
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 3) {
                Text(title.uppercased())
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.58))

                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(.black.opacity(0.25), in: RoundedRectangle(cornerRadius: 16))
        .foregroundStyle(.white)
    }

    func workoutCompactDetailCard(
        title: String,
        value: String,
        systemImage: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.subheadline.weight(.semibold))

                Text(title.uppercased())
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.58))
            }

            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 88, alignment: .topLeading)
        .background(.black.opacity(0.25), in: RoundedRectangle(cornerRadius: 16))
    }


    @ViewBuilder
    var classContactRow: some View {
        let phone = workout?.phone?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let website = workout?.website?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        if !phone.isEmpty || !website.isEmpty {
            HStack(spacing: 10) {
                if !phone.isEmpty {
                    if let phoneURL = activityWorkoutPhoneURL(phone) {
                        Link(destination: phoneURL) {
                            workoutContactCard(
                                title: "Phone",
                                value: phone,
                                systemImage: "phone.fill"
                            )
                        }
                        .buttonStyle(.plain)
                    } else {
                        workoutContactCard(
                            title: "Phone",
                            value: phone,
                            systemImage: "phone.fill"
                        )
                    }
                }

                if !website.isEmpty {
                    if let websiteURL = activityWorkoutWebsiteURL(website) {
                        Link(destination: websiteURL) {
                            workoutContactCard(
                                title: "Website",
                                value: website,
                                systemImage: "safari.fill"
                            )
                        }
                        .buttonStyle(.plain)
                    } else {
                        workoutContactCard(
                            title: "Website",
                            value: website,
                            systemImage: "safari.fill"
                        )
                    }
                }
            }
        }
    }


    func workoutContactCard(
        title: String,
        value: String,
        systemImage: String
    ) -> some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.semibold))

            VStack(alignment: .leading, spacing: 2) {
                Text(title.uppercased())
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.58))

                Text(value)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(.black.opacity(0.25), in: RoundedRectangle(cornerRadius: 16))
    }


    func classBottomControls(
        now: Date
    ) -> some View {

        let state = checkInState(now: now)

        return HStack(spacing: 10) {
            Button {
                checkInToClass()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: state.systemImage)
                    Text(state.title)
                }
                .font(.headline.weight(.bold))
                .foregroundStyle(state.isEnabled ? .black : .white.opacity(0.78))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(
                            state.isEnabled
                            ? Color.white
                            : Color.black.opacity(0.42)
                        )
                }
            }
            .buttonStyle(.plain)
            .disabled(!state.isEnabled)

            Button {
                isShowingBrowseWorkouts = true
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "rectangle.stack.fill")
                        .font(.subheadline.weight(.bold))

                    Text("Browse\nWorkouts")
                        .font(.caption2.weight(.bold))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                .foregroundStyle(.white)
                .frame(width: 92)
                .padding(.vertical, 10)
                .background(
                    .black.opacity(0.42),
                    in: RoundedRectangle(cornerRadius: 18)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(.white.opacity(0.18), lineWidth: 1)
                }
            }
            .buttonStyle(.plain)
        }
    }


    func checkInState(
        now: Date
    ) -> (
        title: String,
        systemImage: String,
        isEnabled: Bool
    ) {

        if isPastClassCheckInWindow(now: now) {
            return (
                "Workout Completed",
                "checkmark.seal.fill",
                false
            )
        }

        let status = workout?.workoutStatus?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        if status == "checked in"
            || status == "checked-in"
            || status == "checkedin" {
            return (
                "Checked In",
                "checkmark.circle.fill",
                false
            )
        }

        return (
            "Check In",
            "person.crop.circle.badge.checkmark",
            true
        )
    }


    func isPastClassCheckInWindow(
        now: Date
    ) -> Bool {

        guard let start = activityWorkoutParseClockString(
            activityContent?.startTime.isEmpty == false
            ? (activityContent?.startTime ?? "")
            : (workout?.selectedWorkoutTime ?? "")
        ) else {
            return false
        }

        let calendar = Calendar.current
        let components = calendar.dateComponents(
            [.hour, .minute, .second],
            from: now
        )

        let nowSeconds = TimeInterval(
            (components.hour ?? 0) * 3_600
            + (components.minute ?? 0) * 60
            + (components.second ?? 0)
        )

        // The user may check in before class or during the first ten minutes.
        // Once that ten-minute grace window has elapsed, this control becomes
        // the non-interactive Workout Completed state.
        return nowSeconds > start.secondsFromMidnight + 600
    }


    func checkInToClass() {
        guard case var .activity(content) = draft.content,
              var summary = content.workout else {
            return
        }

        summary.workoutStatus = "Checked In"
        content.workout = summary
        content.status = "Checked In"
        draft.content = .activity(content)
        onUpdate(draft)
    }

    var durationDisplay: String {
        if let text = workout?.durationText,
           !text.isEmpty {
            return text
        }

        let seconds = workout?.durationInSeconds ?? 0
        guard seconds > 0 else { return "Duration unavailable" }

        let minutes = (seconds + 59) / 60
        return "\(minutes) min"
    }

    func selectWorkout(
        _ option: ActivityWorkoutBrowseOption
    ) {
        let updated = activityWorkoutApplyingSelection(
            option,
            to: draft,
            roadGraph: roadGraph
        )

        draft = updated
        onUpdate(updated)
        isShowingBrowseWorkouts = false

        if option.summary.resolvedWorkoutType == .independent {
            onSwitchToIndependent(updated)
            dismiss()
        }
    }
}


// =====================================================
private func activityWorkoutPhoneURL(
    _ phone: String
) -> URL? {
    let allowed = phone.filter {
        $0.isNumber || $0 == "+"
    }

    guard !allowed.isEmpty else {
        return nil
    }

    return URL(string: "tel:\(allowed)")
}


private func activityWorkoutWebsiteURL(
    _ website: String
) -> URL? {
    let trimmed = website.trimmingCharacters(in: .whitespacesAndNewlines)

    guard !trimmed.isEmpty else {
        return nil
    }

    if let url = URL(string: trimmed),
       url.scheme != nil {
        return url
    }

    return URL(string: "https://\(trimmed)")
}


// MARK: Browse Workouts Sheet
// =====================================================

enum ActivityWorkoutBrowseScope:
    Sendable {

    case all
    case classesOnly
}


struct ActivityWorkoutBrowseSheet: View {

    let selectedWorkoutID: String?
    var scope: ActivityWorkoutBrowseScope = .all
    let onSelect: (ActivityWorkoutBrowseOption) -> Void

    @State private var searchText = ""
    @Environment(\.dismiss) private var dismiss

    private var scopedOptions: [ActivityWorkoutBrowseOption] {
        switch scope {
        case .all:
            return ActivityWorkoutBrowseCatalog.options

        case .classesOnly:
            return ActivityWorkoutBrowseCatalog.options.filter {
                $0.summary.resolvedWorkoutType == .guidedClass
            }
        }
    }

    private var filteredOptions: [ActivityWorkoutBrowseOption] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            return scopedOptions
        }

        return scopedOptions.filter { option in
            let summary = option.summary
            let searchable = [
                summary.title,
                summary.location,
                summary.workoutFormat,
                summary.trainer?.name ?? "",
                summary.categories.joined(separator: " ")
            ]
            .joined(separator: " ")

            return searchable.localizedCaseInsensitiveContains(query)
        }
    }

    private var classOptions: [ActivityWorkoutBrowseOption] {
        filteredOptions.filter {
            $0.summary.resolvedWorkoutType == .guidedClass
        }
    }

    private var independentOptions: [ActivityWorkoutBrowseOption] {
        filteredOptions.filter {
            $0.summary.resolvedWorkoutType == .independent
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if !classOptions.isEmpty {
                    Section("Classes") {
                        ForEach(classOptions) { option in
                            workoutRow(option)
                        }
                    }
                }

                if !independentOptions.isEmpty {
                    Section("Independent • Fifoo Play") {
                        ForEach(independentOptions) { option in
                            workoutRow(option)
                        }
                    }
                }
            }
            .navigationTitle(
                scope == .classesOnly
                ? "Browse Workout Classes"
                : "Browse Workouts"
            )
            .navigationBarTitleDisplayMode(.inline)
            .searchable(
                text: $searchText,
                prompt: scope == .classesOnly
                    ? "Search classes, trainers, studios"
                    : "Search workouts, trainers, studios"
            )
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func workoutRow(
        _ option: ActivityWorkoutBrowseOption
    ) -> some View {
        Button {
            onSelect(option)
            dismiss()
        } label: {
            HStack(spacing: 14) {
                ActivityWorkoutBrowseThumbnail(
                    urlString: option.summary.imageURLs?.first
                )

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(option.summary.title)
                            .font(.headline)
                            .foregroundStyle(.primary)

                        if option.summary.workoutID == selectedWorkoutID {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                    }

                    Text(option.summary.resolvedWorkoutType.displayName)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    if option.summary.resolvedWorkoutType == .guidedClass {
                        Text(
                            [
                                option.summary.selectedWorkoutTime,
                                option.summary.location,
                                option.summary.durationText
                            ]
                            .filter { !$0.isEmpty }
                            .joined(separator: " • ")
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                    } else {
                        Text(
                            [
                                option.summary.durationText,
                                option.summary.categories.joined(separator: " • ")
                            ]
                            .filter { !$0.isEmpty }
                            .joined(separator: " • ")
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}


private struct ActivityWorkoutBrowseThumbnail: View {

    let urlString: String?

    var body: some View {
        Group {
            if let urlString,
               let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case let .success(image):
                        image.resizable().scaledToFill()
                    case .empty:
                        ProgressView()
                    case .failure:
                        placeholder
                    @unknown default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .frame(width: 62, height: 62)
        .background(.secondary.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var placeholder: some View {
        Image(systemName: "figure.run")
            .font(.title2)
            .foregroundStyle(.secondary)
    }
}


// =====================================================
// MARK: Independent Workout Time Picker
// =====================================================

struct ActivityWorkoutScheduleTimePickerSheet: View {

    let node: GameMapNode
    let onSave: (DayTime) -> Void

    @State private var selectedDate: Date
    @Environment(\.dismiss) private var dismiss

    init(
        node: GameMapNode,
        onSave: @escaping (DayTime) -> Void
    ) {
        self.node = node
        self.onSave = onSave

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current

        let startOfToday = calendar.startOfDay(for: Date())
        let initialDate = startOfToday.addingTimeInterval(
            min(
                node.time.secondsFromMidnight,
                DayTime.secondsPerDay - 60
            )
        )

        _selectedDate = State(initialValue: initialDate)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Independent workouts can be moved to any time in your day.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                DatePicker(
                    "Workout Time",
                    selection: $selectedDate,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .frame(maxWidth: .infinity)

                Spacer()
            }
            .padding()
            .navigationTitle("Workout Time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let time = DayTime.from(
                            date: selectedDate,
                            timeZone: .current
                        )
                        onSave(time)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
    }
}


// =====================================================
// MARK: Workout Full-screen Background
// =====================================================

private struct ActivityWorkoutBackgroundImage: View {

    let image: GameNodeImage?

    var body: some View {
        Group {
            switch image {
            case let .asset(name):
                if let uiImage = UIImage(named: name) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    placeholder
                }

            case let .remote(urlString):
                if let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case let .success(image):
                            image.resizable().scaledToFill()
                        case .empty:
                            ZStack {
                                placeholder
                                ProgressView().tint(.white)
                            }
                        case .failure:
                            placeholder
                        @unknown default:
                            placeholder
                        }
                    }
                } else {
                    placeholder
                }

            case .systemSymbol, nil:
                placeholder
            }
        }
        .ignoresSafeArea()
    }

    private var placeholder: some View {
        Image(
            uiImage: GameNodePlaceholderImage.image(
                for: .activityWorkout,
                size: 900
            )
        )
        .resizable()
        .scaledToFill()
    }
}


// =====================================================
// MARK: - ActivityTask Full-screen Experience
// =====================================================

private enum ActivityTaskTimePickerTarget:
    Equatable,
    Sendable {

    case start
    case end
}


/// Full-screen execution surface for ActivityTask stops.
///
/// The task experience intentionally mirrors the visual hierarchy of the
/// ActivityMeal welcome page, but tasks do not have a Play/action state. A
/// task can be rescheduled, skipped, or marked completed directly from this
/// screen.
struct ActivityTaskExperienceView: View {

    let node: GameMapNode
    let roadGraph: RoadGraph
    let onUpdate: (GameMapNode) -> Void
    let onSkip: (GameMapNode) -> Void
    let onCompleted: (GameMapNode) -> Void

    @State private var draft: GameMapNode
    @State private var activeTimePicker: ActivityTaskTimePickerTarget?
    @State private var isShowingSkipConfirmation = false
    @State private var isShowingDoneConfirmation = false

    @Environment(\.dismiss) private var dismiss


    init(
        node: GameMapNode,
        roadGraph: RoadGraph,
        onUpdate: @escaping (GameMapNode) -> Void,
        onSkip: @escaping (GameMapNode) -> Void,
        onCompleted: @escaping (GameMapNode) -> Void
    ) {
        self.node = node
        self.roadGraph = roadGraph
        self.onUpdate = onUpdate
        self.onSkip = onSkip
        self.onCompleted = onCompleted
        _draft = State(initialValue: Self.preloadedDraft(from: node))
    }


    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ActivityTaskBackgroundImage(
                    image: activityContent?.image
                )

                // Keep the task image visible while ensuring every foreground
                // label remains readable against photography of any brightness.
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.52),
                        Color.black.opacity(0.24),
                        Color.black.opacity(0.82)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: verticalSpacing(for: geometry.size.height)) {
                    header
                    editableTimeRow
                    taskDetails

                    Spacer(minLength: geometry.size.height < 700 ? 12 : 28)

                    bottomControls
                }
                .padding(.horizontal, 20)
                .padding(.top, topPadding(for: geometry.size.height))
                .padding(.bottom, bottomPadding(for: geometry.size.height))
                .frame(
                    width: geometry.size.width,
                    height: geometry.size.height,
                    alignment: .top
                )

                if let target = activeTimePicker {
                    timePickerOverlay(for: target)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipped()
        }
        .ignoresSafeArea()
        .onAppear {
            // Always refresh from the latest map node when this full-screen
            // cover is presented. SwiftUI can preserve @State across repeated
            // presentations of the same item identity, so relying only on the
            // State initializer can leave stale/blank time fields.
            draft = Self.preloadedDraft(from: node)
        }
        .confirmationDialog(
            "Skip this task?",
            isPresented: $isShowingSkipConfirmation,
            titleVisibility: .visible
        ) {
            Button("Skip Task", role: .destructive) {
                finish(with: .skip)
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This marks the ActivityTask as skipped and returns to the day map.")
        }
        .confirmationDialog(
            "Mark this task done?",
            isPresented: $isShowingDoneConfirmation,
            titleVisibility: .visible
        ) {
            Button("Task Completed") {
                finish(with: .completed)
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This marks the ActivityTask as completed and returns to the day map.")
        }
    }
}


private extension ActivityTaskExperienceView {

    /// ActivityTask payloads created before the full-screen task experience
    /// do not always contain explicit Activity.startTime / endTime strings.
    /// The map node itself still owns a canonical `DayTime`, so seed the
    /// presentation draft from that value before SwiftUI creates the controls.
    /// This makes the existing task times visible immediately when the cover
    /// opens instead of showing empty "Select time" fields.
    static func preloadedDraft(from node: GameMapNode) -> GameMapNode {
        var result = node

        guard case var .activity(content) = result.content,
              content.resolvedActivityType == .task else {
            return result
        }

        let start = content.startTime
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if start.isEmpty || start.lowercased() == "none" {
            content.startTime = node.time.displayClockString
        }

        let end = content.endTime
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if end.isEmpty || end.lowercased() == "none" {
            content.endTime = DayTime(
                secondsFromMidnight: min(
                    node.time.secondsFromMidnight + 3_600,
                    DayTime.secondsPerDay - 60
                )
            ).displayClockString
        }

        result.content = .activity(content)
        return result
    }


    var activityContent: ActivityNodeContent? {
        guard case let .activity(content) = draft.content,
              content.resolvedActivityType == .task else {
            return nil
        }
        return content
    }


    var taskSummary: ActivityTaskNodeSummary? {
        activityContent?.task
    }


    var displayTitle: String {
        if let title = taskSummary?.title,
           !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return title
        }

        if let title = activityContent?.title,
           !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return title
        }

        return "Task"
    }


    var displayDescription: String? {
        let taskDescription =
            taskSummary?.description
                .trimmingCharacters(in: .whitespacesAndNewlines)

        if let taskDescription,
           !taskDescription.isEmpty {
            return taskDescription
        }

        let activityDescription =
            activityContent?.description?
                .trimmingCharacters(in: .whitespacesAndNewlines)

        if let activityDescription,
           !activityDescription.isEmpty {
            return activityDescription
        }

        return nil
    }


    var startTimeBinding: Binding<String> {
        Binding(
            get: { activityContent?.startTime ?? "" },
            set: { newValue in
                updateActivityContent { $0.startTime = newValue }
            }
        )
    }


    var endTimeBinding: Binding<String> {
        Binding(
            get: { activityContent?.endTime ?? "" },
            set: { newValue in
                updateActivityContent { $0.endTime = newValue }
            }
        )
    }


    var header: some View {
        HStack(spacing: 14) {
            Text(displayTitle)
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.8)

            Spacer()

            Button {
                persistDraft()
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.headline.weight(.bold))
                    .frame(width: 42, height: 42)
                    .background(.black.opacity(0.30), in: Circle())
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
        }
    }


    var editableTimeRow: some View {
        HStack(spacing: 12) {
            timeField(
                title: "Start",
                text: startTimeBinding,
                target: .start
            )

            Image(systemName: "arrow.right")
                .foregroundStyle(.white.opacity(0.7))

            timeField(
                title: "End",
                text: endTimeBinding,
                target: .end
            )
        }
    }


    func timeField(
        title: String,
        text: Binding<String>,
        target: ActivityTaskTimePickerTarget
    ) -> some View {
        Button {
            withAnimation(.snappy(duration: 0.22)) {
                activeTimePicker = target
            }
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.65))

                HStack(spacing: 8) {
                    Text(text.wrappedValue.isEmpty ? "Select time" : text.wrappedValue)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Spacer(minLength: 0)

                    Image(systemName: "clock")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.72))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                .black.opacity(0.28),
                in: RoundedRectangle(cornerRadius: 14)
            )
        }
        .buttonStyle(.plain)
    }


    @ViewBuilder
    var taskDetails: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let status = activityContent?.status,
               !status.isEmpty {
                Text(status)
                    .font(.caption.weight(.bold))
                    .textCase(.uppercase)
                    .foregroundStyle(.white.opacity(0.88))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        .black.opacity(0.28),
                        in: Capsule()
                    )
            }

            if let description = displayDescription {
                Text(description)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.white.opacity(0.94))
                    .lineLimit(5)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 10) {
                if let location = activityContent?.location,
                   !location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    detailCard(
                        title: "Location",
                        value: location,
                        systemImage: "mappin.and.ellipse"
                    )
                }

                if let date = activityContent?.date,
                   !date.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    detailCard(
                        title: "Date",
                        value: date,
                        systemImage: "calendar"
                    )
                }
            }

            if let task = taskSummary {
                let imageCount = task.imageURLs?.count ?? 0
                let videoCount = task.videoURLs?.count ?? 0

                if imageCount > 0 || videoCount > 0 {
                    HStack(spacing: 10) {
                        if imageCount > 0 {
                            detailCard(
                                title: "Images",
                                value: "\(imageCount)",
                                systemImage: "photo.on.rectangle"
                            )
                        }

                        if videoCount > 0 {
                            detailCard(
                                title: "Videos",
                                value: "\(videoCount)",
                                systemImage: "play.rectangle"
                            )
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }


    func detailCard(
        title: String,
        value: String,
        systemImage: String
    ) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.78))
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption2.weight(.semibold))
                    .textCase(.uppercase)
                    .foregroundStyle(.white.opacity(0.60))

                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            .black.opacity(0.28),
            in: RoundedRectangle(cornerRadius: 15)
        )
    }


    var bottomControls: some View {
        HStack(spacing: 16) {
            taskActionButton(
                title: "Skip",
                systemImage: "forward.end.fill",
                roleColor: .red
            ) {
                isShowingSkipConfirmation = true
            }

            taskActionButton(
                title: "Done",
                systemImage: "checkmark",
                roleColor: .green
            ) {
                isShowingDoneConfirmation = true
            }
        }
    }


    func taskActionButton(
        title: String,
        systemImage: String,
        roleColor: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.headline.weight(.bold))

                Text(title)
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                roleColor.opacity(0.26),
                in: RoundedRectangle(cornerRadius: 16)
            )
        }
        .buttonStyle(.plain)
    }


    @ViewBuilder
    func timePickerOverlay(
        for target: ActivityTaskTimePickerTarget
    ) -> some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.40)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.snappy(duration: 0.22)) {
                        activeTimePicker = nil
                    }
                }

            VStack(spacing: 10) {
                HStack {
                    Text(target == .start ? "Start Time" : "End Time")
                        .font(.headline.weight(.semibold))

                    Spacer()

                    Button("Done") {
                        withAnimation(.snappy(duration: 0.22)) {
                            activeTimePicker = nil
                        }
                    }
                    .font(.headline.weight(.semibold))
                }
                .padding(.horizontal, 18)
                .padding(.top, 16)

                DatePicker(
                    "",
                    selection: timeDateBinding(for: target),
                    displayedComponents: .hourAndMinute
                )
                .labelsHidden()
                .datePickerStyle(.wheel)
                .frame(maxWidth: .infinity)
            }
            .foregroundStyle(.primary)
            .background(.ultraThinMaterial)
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 26,
                    topTrailingRadius: 26
                )
            )
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
        .zIndex(50)
    }


    func timeDateBinding(
        for target: ActivityTaskTimePickerTarget
    ) -> Binding<Date> {
        Binding(
            get: {
                let value =
                    target == .start
                    ? startTimeBinding.wrappedValue
                    : endTimeBinding.wrappedValue

                let fallback =
                    target == .start
                    ? draft.time
                    : DayTime(
                        secondsFromMidnight:
                            min(
                                draft.time.secondsFromMidnight + 3_600,
                                DayTime.secondsPerDay - 60
                            )
                    )

                return dateForClockString(value, fallback: fallback)
            },
            set: { newDate in
                let time = DayTime.from(
                    date: newDate,
                    timeZone: .current
                )

                if target == .start {
                    startTimeBinding.wrappedValue = time.displayClockString
                } else {
                    endTimeBinding.wrappedValue = time.displayClockString
                }
            }
        )
    }


    func dateForClockString(
        _ value: String,
        fallback: DayTime
    ) -> Date {
        let dayTime = parseClockString(value) ?? fallback

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current

        return calendar
            .startOfDay(for: Date())
            .addingTimeInterval(
                min(
                    dayTime.secondsFromMidnight,
                    DayTime.secondsPerDay - 60
                )
            )
    }


    func parseClockString(
        _ value: String
    ) -> DayTime? {
        let cleaned = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return nil }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)

        for format in [
            "h:mm a", "hh:mm a", "h:mm:ss a", "hh:mm:ss a",
            "H:mm", "HH:mm", "H:mm:ss", "HH:mm:ss"
        ] {
            formatter.dateFormat = format

            guard let date = formatter.date(from: cleaned) else {
                continue
            }

            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = formatter.timeZone

            let components = calendar.dateComponents(
                [.hour, .minute, .second],
                from: date
            )

            return DayTime(
                secondsFromMidnight: TimeInterval(
                    (components.hour ?? 0) * 3_600
                    + (components.minute ?? 0) * 60
                    + (components.second ?? 0)
                )
            )
        }

        return nil
    }


    func updateActivityContent(
        _ mutation: (inout ActivityNodeContent) -> Void
    ) {
        guard case var .activity(content) = draft.content else {
            return
        }

        mutation(&content)
        draft.content = .activity(content)
    }


    func persistDraft() {
        synchronizeNodeTimeFromStartTime()
        onUpdate(draft)
    }


    func finish(
        with action: ActivityNodeEditorAction
    ) {
        updateActivityContent { content in
            content.status = action.statusValue ?? content.status
        }
        synchronizeNodeTimeFromStartTime()

        switch action {
        case .skip:
            onSkip(draft)
        case .completed:
            onCompleted(draft)
        case .join:
            onUpdate(draft)
        }

        dismiss()
    }


    func synchronizeNodeTimeFromStartTime() {
        guard let startTime = parseClockString(startTimeBinding.wrappedValue) else {
            return
        }

        switch draft.placement {
        case let .roadVertex(vertexID):
            if let vertex = roadGraph.vertex(id: vertexID) {
                draft.setPlacement(
                    .coordinate(
                        MapCoordinate(
                            time: startTime,
                            progress: vertex.coordinate.progress
                        )
                    )
                )
            } else {
                draft.setTime(startTime)
            }

        case .coordinate:
            draft.setTime(startTime)
        }
    }


    func topPadding(for height: CGFloat) -> CGFloat {
        height < 700 ? 54 : 72
    }


    func bottomPadding(for height: CGFloat) -> CGFloat {
        height < 700 ? 34 : 48
    }


    func verticalSpacing(for height: CGFloat) -> CGFloat {
        height < 700 ? 12 : 18
    }
}


private struct ActivityTaskBackgroundImage: View {

    let image: GameNodeImage?

    var body: some View {
        Group {
            switch image {
            case let .asset(name):
                if let uiImage = UIImage(named: name) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    placeholder
                }

            case let .remote(urlString):
                if let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case let .success(image):
                            image.resizable().scaledToFill()
                        case .empty:
                            ZStack {
                                placeholder
                                ProgressView().tint(.white)
                            }
                        case .failure:
                            placeholder
                        @unknown default:
                            placeholder
                        }
                    }
                } else {
                    placeholder
                }

            case .systemSymbol, nil:
                placeholder
            }
        }
        .ignoresSafeArea()
    }


    private var placeholder: some View {
        Image(
            uiImage: GameNodePlaceholderImage.image(
                for: .activityTask,
                size: 900
            )
        )
        .resizable()
        .scaledToFill()
    }
}
