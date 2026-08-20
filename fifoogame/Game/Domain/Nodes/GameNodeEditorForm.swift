//
//  GameNodeEditorForm.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/19/26.
//



import SwiftUI
import Foundation

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

            validationSection

            identitySection

            contentSection

            imageSection

            placementSection

            roadRelationshipSection

            statusSection
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
            // Label
            // =========================================

            case .label:

                TextField(
                    "Text",
                    text:
                        labelTextBinding
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

                TextField(
                    "Title",
                    text:
                        postTitleBinding
                )


                TextField(
                    "Post ID",
                    text:
                        postIDBinding
                )
                .textInputAutocapitalization(
                    .never
                )
                .autocorrectionDisabled()


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
// MARK: - Image Editor
// =====================================================

private extension GameNodeEditorForm {

    enum ImageSource:
        String,
        CaseIterable,
        Identifiable {

        case none

        case asset

        case systemSymbol

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


            case .systemSymbol:

                return "SF Symbol"


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
                    "This node will use its fallback marker."
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


            case .systemSymbol:

                TextField(
                    "SF Symbol Name",
                    text:
                        imageValueBinding
                )
                .textInputAutocapitalization(
                    .never
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


            if currentImage != nil {

                nodeImagePreview
            }
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

                    Image(
                        name
                    )
                    .resizable()
                    .scaledToFill()


                case let .systemSymbol(
                    name
                ):

                    Image(
                        systemName:
                            name
                    )
                    .resizable()
                    .scaledToFit()
                    .padding(
                        12
                    )


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

                                ProgressView()


                            case let .success(
                                image
                            ):

                                image
                                    .resizable()
                                    .scaledToFill()


                            case .failure:

                                Image(
                                    systemName:
                                        "photo.badge.exclamationmark"
                                )
                                .font(
                                    .title
                                )


                            @unknown default:

                                EmptyView()
                            }
                        }

                    } else {

                        Image(
                            systemName:
                                "photo.badge.exclamationmark"
                        )
                    }


                case nil:

                    EmptyView()
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

                    node.placement =
                        .roadVertex(
                            vertexID
                        )
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
// MARK: - Label Bindings
// =====================================================

private extension GameNodeEditorForm {

    var labelTextBinding:
        Binding<String> {

        Binding {

            guard case let .label(
                content
            ) = node.content
            else {

                return ""
            }


            return content.text

        } set: { newValue in

            guard case var .label(
                content
            ) = node.content
            else {

                return
            }


            content.text =
                newValue


            node.content =
                .label(
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

    var postTitleBinding:
        Binding<String> {

        Binding {

            guard case let .post(
                content
            ) = node.content
            else {

                return ""
            }


            return content.title

        } set: { newValue in

            guard case var .post(
                content
            ) = node.content
            else {

                return
            }


            content.title =
                newValue


            node.content =
                .post(
                    content
                )
        }
    }


    var postIDBinding:
        Binding<String> {

        Binding {

            guard case let .post(
                content
            ) = node.content
            else {

                return ""
            }


            return content.postID

        } set: { newValue in

            guard case var .post(
                content
            ) = node.content
            else {

                return
            }


            content.postID =
                newValue


            node.content =
                .post(
                    content
                )
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

                return .systemSymbol


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


            case .systemSymbol:

                setNodeImage(
                    .systemSymbol(
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

                setNodeImage(
                    .systemSymbol(
                        name:
                            newValue
                    )
                )


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


        case let .systemSymbol(
            name
        ):

            return name


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

        case var .label(
            content
        ):

            content.image =
                image

            node.content =
                .label(
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
                            coordinate.time,
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

            node.placement =
                .roadVertex(
                    RoadVertexID(
                        newValue
                    )
                )
        }
    }
}

// =====================================================
// MARK: - Time Binding
// =====================================================

private extension GameNodeEditorForm {

    var coordinateTimeBinding:
        Binding<Date> {

        Binding {

            guard case let .coordinate(
                coordinate
            ) = node.placement
            else {

                return referenceDate(
                    for:
                        .noon
                )
            }


            return referenceDate(
                for:
                    coordinate.time
            )

        } set: { newDate in

            guard case let .coordinate(
                coordinate
            ) = node.placement
            else {

                return
            }


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


            node.placement =
                .coordinate(
                    MapCoordinate(
                        time:
                            DayTime(
                                secondsFromMidnight:
                                    seconds
                            ),
                        progress:
                            coordinate.progress
                    )
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

            DatePicker(
                "Time",
                selection:
                    coordinateTimeBinding,
                displayedComponents:
                    .hourAndMinute
            )


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


        node.placement =
            .coordinate(
                vertex.coordinate
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


        node.placement =
            .roadVertex(
                vertex.id
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
