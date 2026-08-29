//
//  ActivityTypeEditorView.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/24/26.
//


import SwiftUI
import Foundation


struct ActivityTypeEditorView: View {

    @Binding var node:
        GameMapNode


    var body: some View {

        Group {

            switch resolvedType {

            case .meal:

                suggestedMealEditor

            case .workout:

                workoutEditor

            case .task:

                taskEditor
            }
        }
        .navigationTitle(
            navigationTitle
        )
        .navigationBarTitleDisplayMode(
            .inline
        )
    }
}


// =====================================================
// MARK: - Type
// =====================================================

private extension ActivityTypeEditorView {

    var resolvedType:
        ActivityNodeContent.ActivityType {

        guard case let .activity(
            content
        ) = node.content
        else {

            return .task
        }

        return content.resolvedActivityType
    }


    var navigationTitle: String {

        switch resolvedType {

        case .meal:
            return "Suggested Meal"

        case .workout:
            return "Workout"

        case .task:
            return "Task"
        }
    }
}


// =====================================================
// MARK: - Suggested Meal
// =====================================================

private extension ActivityTypeEditorView {

    var suggestedMealEditor: some View {

        Form {

            Section(
                "Suggested Meal"
            ) {

                TextField(
                    "Title",
                    text:
                        mealBinding.title
                )


                TextField(
                    "Image URL",
                    text:
                        optionalStringBinding(
                            mealBinding.imageURL
                        )
                )
                .textInputAutocapitalization(
                    .never
                )
                .keyboardType(
                    .URL
                )
                .autocorrectionDisabled()


                remoteImagePreview(
                    urlString:
                        mealBinding
                            .imageURL
                            .wrappedValue
                )


                TextField(
                    "Estimated Time (minutes)",
                    value:
                        mealBinding
                            .estimatedTimeMinutes,
                    format:
                        .number
                )
                .keyboardType(
                    .numberPad
                )


                TextField(
                    "Price Range",
                    text:
                        mealBinding.priceRange
                )
            }


            if let user =
                mealBinding
                    .wrappedValue
                    .user {

                Section(
                    "Creator"
                ) {

                    LabeledContent(
                        "Name",
                        value:
                            user.name
                    )

                    if !user.location.isEmpty {

                        LabeledContent(
                            "Location",
                            value:
                                user.location
                        )
                    }
                }
            }


            if let meals =
                mealBinding
                    .wrappedValue
                    .meals,
               !meals.isEmpty {

                Section(
                    "Meals"
                ) {

                    ForEach(
                        meals
                    ) { meal in

                        VStack(
                            alignment:
                                .leading,
                            spacing:
                                6
                        ) {

                            Text(
                                meal.title
                            )
                            .fontWeight(
                                .semibold
                            )


                            HStack(
                                spacing:
                                    12
                            ) {

                                Text(
                                    "\(meal.estimatedTimeMinutes) min"
                                )

                                if let priceRange =
                                    meal.priceRange,
                                   !priceRange.isEmpty {

                                    Text(
                                        priceRange
                                    )
                                }
                            }
                            .font(
                                .caption
                            )
                            .foregroundStyle(
                                .secondary
                            )


                            Text(
                                "\(meal.recipeCount) recipes • \(meal.ingredientCount) ingredients • \(meal.sourceCount) sources"
                            )
                            .font(
                                .caption2
                            )
                            .foregroundStyle(
                                .secondary
                            )
                        }
                        .padding(
                            .vertical,
                            2
                        )
                    }
                }
            }


            metadataSection(
                createdAt:
                    mealBinding
                        .wrappedValue
                        .createdAt,
                copyStatus:
                    mealBinding
                        .wrappedValue
                        .copyStatus
            )
        }
    }
}


// =====================================================
// MARK: - Workout
// =====================================================

private extension ActivityTypeEditorView {

    var workoutEditor: some View {

        Form {

            Section(
                "Workout Type"
            ) {
                Picker(
                    "Type",
                    selection: workoutTypeBinding
                ) {
                    ForEach(
                        ActivityWorkoutType.allCases,
                        id: \.self
                    ) { type in
                        Text(type.displayName)
                            .tag(type)
                    }
                }
                .pickerStyle(.segmented)

                Text(
                    workoutTypeBinding.wrappedValue == .guidedClass
                    ? "Class times are owned by the class schedule. Choose another class to change time."
                    : "Independent workouts use Fifoo Play and can be scheduled at any time."
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }


            Section(
                "Workout"
            ) {

                TextField(
                    "Title",
                    text:
                        workoutBinding.title
                )


                TextField(
                    "Description",
                    text:
                        optionalStringBinding(
                            workoutBinding.description
                        ),
                    axis:
                        .vertical
                )
                .lineLimit(
                    3...8
                )


                TextField(
                    "Location",
                    text:
                        workoutBinding.location
                )


                TextField(
                    "Categories",
                    text:
                        commaSeparatedBinding(
                            workoutBinding.categories
                        )
                )


                TextField(
                    "Image URLs",
                    text:
                        lineSeparatedBinding(
                            workoutBinding.imageURLs
                        ),
                    axis:
                        .vertical
                )
                .lineLimit(
                    2...6
                )
                .textInputAutocapitalization(
                    .never
                )
                .autocorrectionDisabled()


                remoteImagePreview(
                    urlString:
                        workoutBinding
                            .imageURLs
                            .wrappedValue?
                            .first
                )
            }


            Section(
                "Workout Details"
            ) {

                TextField(
                    "Selected Workout Time",
                    text:
                        workoutBinding
                            .selectedWorkoutTime
                )


                TextField(
                    "Duration",
                    text:
                        workoutBinding
                            .durationText
                )


                TextField(
                    "Duration (seconds)",
                    value:
                        workoutBinding
                            .durationInSeconds,
                    format:
                        .number
                )
                .keyboardType(
                    .numberPad
                )


                TextField(
                    "Distance",
                    text:
                        workoutBinding.distance
                )


                TextField(
                    "Format",
                    text:
                        workoutBinding
                            .workoutFormat
                )


                TextField(
                    "Rating",
                    text:
                        workoutBinding.rating
                )


                TextField(
                    "Workout Status",
                    text:
                        optionalStringBinding(
                            workoutBinding
                                .workoutStatus
                        )
                )
            }


            if let trainer =
                workoutBinding
                    .wrappedValue
                    .trainer {

                Section(
                    "Trainer"
                ) {

                    LabeledContent(
                        "Name",
                        value:
                            trainer.name
                    )

                    if !trainer.location.isEmpty {

                        LabeledContent(
                            "Location",
                            value:
                                trainer.location
                        )
                    }

                    if !trainer.rating.isEmpty {

                        LabeledContent(
                            "Rating",
                            value:
                                trainer.rating
                        )
                    }
                }
            }


            Section(
                "Participation"
            ) {

                if let commentsCount =
                    workoutBinding
                        .wrappedValue
                        .commentsCount {

                    LabeledContent(
                        "Comments",
                        value:
                            "\(commentsCount)"
                    )
                }


                let participants =
                    workoutBinding
                        .wrappedValue
                        .participants
                    ?? []

                LabeledContent(
                    "Participants",
                    value:
                        "\(participants.count)"
                )


                ForEach(
                    participants
                ) { participant in

                    VStack(
                        alignment:
                            .leading,
                        spacing:
                            3
                    ) {

                        Text(
                            participant.name
                        )
                        .fontWeight(
                            .semibold
                        )

                        if !participant.userRole.isEmpty {

                            Text(
                                participant.userRole
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
            }


            if let user =
                workoutBinding
                    .wrappedValue
                    .user {

                Section(
                    "Creator"
                ) {

                    LabeledContent(
                        "Name",
                        value:
                            user.name
                    )

                    if !user.location.isEmpty {

                        LabeledContent(
                            "Location",
                            value:
                                user.location
                        )
                    }
                }
            }


            metadataSection(
                createdAt:
                    workoutBinding
                        .wrappedValue
                        .createdAt,
                copyStatus:
                    workoutBinding
                        .wrappedValue
                        .copyStatus
            )
        }
    }
}


// =====================================================
// MARK: - Task
// =====================================================

private extension ActivityTypeEditorView {

    var taskEditor: some View {

        Form {

            Section(
                "Task"
            ) {

                TextField(
                    "Title",
                    text:
                        taskBinding.title
                )


                TextField(
                    "Description",
                    text:
                        taskBinding.description,
                    axis:
                        .vertical
                )
                .lineLimit(
                    3...8
                )
            }


            Section(
                "Media"
            ) {

                TextField(
                    "Image URLs",
                    text:
                        lineSeparatedBinding(
                            taskBinding.imageURLs
                        ),
                    axis:
                        .vertical
                )
                .lineLimit(
                    2...6
                )
                .textInputAutocapitalization(
                    .never
                )
                .autocorrectionDisabled()


                TextField(
                    "Video URLs",
                    text:
                        lineSeparatedBinding(
                            taskBinding.videoURLs
                        ),
                    axis:
                        .vertical
                )
                .lineLimit(
                    2...6
                )
                .textInputAutocapitalization(
                    .never
                )
                .autocorrectionDisabled()


                remoteImagePreview(
                    urlString:
                        taskBinding
                            .imageURLs
                            .wrappedValue?
                            .first
                )
            }


            metadataSection(
                createdAt:
                    nil,
                copyStatus:
                    taskBinding
                        .wrappedValue
                        .copyStatus
            )
        }
    }
}


// =====================================================
// MARK: - Snapshot Bindings
// =====================================================

private extension ActivityTypeEditorView {

    var mealBinding:
        Binding<ActivityMealNodeSummary> {

        Binding {

            guard case let .activity(
                content
            ) = node.content
            else {

                return defaultMealSummary
            }

            return content.meal
            ?? defaultMealSummary

        } set: { newValue in

            guard case var .activity(
                content
            ) = node.content
            else {

                return
            }

            content.meal =
                newValue

            node.content =
                .activity(
                    content
                )
        }
    }


    var workoutTypeBinding:
        Binding<ActivityWorkoutType> {

        Binding {
            workoutBinding.wrappedValue.resolvedWorkoutType
        } set: { newValue in
            var workout = workoutBinding.wrappedValue
            workout.workoutType = newValue
            workout.workoutFormat = newValue.displayName
            workoutBinding.wrappedValue = workout
        }
    }


    var workoutBinding:
        Binding<ActivityWorkoutNodeSummary> {

        Binding {

            guard case let .activity(
                content
            ) = node.content
            else {

                return defaultWorkoutSummary
            }

            return content.workout
            ?? defaultWorkoutSummary

        } set: { newValue in

            guard case var .activity(
                content
            ) = node.content
            else {

                return
            }

            content.workout =
                newValue

            node.content =
                .activity(
                    content
                )
        }
    }


    var taskBinding:
        Binding<ActivityTaskNodeSummary> {

        Binding {

            guard case let .activity(
                content
            ) = node.content
            else {

                return defaultTaskSummary
            }

            return content.task
            ?? defaultTaskSummary

        } set: { newValue in

            guard case var .activity(
                content
            ) = node.content
            else {

                return
            }

            content.task =
                newValue

            node.content =
                .activity(
                    content
                )
        }
    }


    var activityTitle: String {

        guard case let .activity(
            content
        ) = node.content
        else {

            return ""
        }

        return content.title
    }


    var activityStartTime: String {

        guard case let .activity(
            content
        ) = node.content
        else {

            return ""
        }

        return content.startTime
    }


    var defaultMealSummary:
        ActivityMealNodeSummary {

        ActivityMealNodeSummary(
            suggestedMealID:
                "",
            title:
                activityTitle,
            estimatedTimeMinutes:
                0,
            priceRange:
                ""
        )
    }


    var defaultWorkoutSummary:
        ActivityWorkoutNodeSummary {

        ActivityWorkoutNodeSummary(
            activityWorkoutID:
                "",
            workoutID:
                "",
            title:
                activityTitle,
            location:
                "",
            categories:
                [],
            selectedWorkoutTime:
                "",
            durationInSeconds:
                0,
            durationText:
                "",
            distance:
                "",
            workoutFormat:
                "Independent",
            rating:
                "",
            workoutType:
                .independent
        )
    }


    var defaultTaskSummary:
        ActivityTaskNodeSummary {

        ActivityTaskNodeSummary(
            activityTaskID:
                "",
            taskID:
                "",
            title:
                activityTitle,
            description:
                ""
        )
    }
}



// =====================================================
// MARK: - Utility Bindings
// =====================================================

private extension ActivityTypeEditorView {

    func optionalStringBinding(
        _ binding: Binding<String?>
    ) -> Binding<String> {

        Binding {

            binding.wrappedValue
            ?? ""

        } set: { newValue in

            let cleaned =
                newValue
                    .trimmingCharacters(
                        in:
                            .whitespacesAndNewlines
                    )

            binding.wrappedValue =
                cleaned.isEmpty
                ? nil
                : newValue
        }
    }


    func commaSeparatedBinding(
        _ binding: Binding<[String]>
    ) -> Binding<String> {

        Binding {

            binding
                .wrappedValue
                .joined(
                    separator:
                        ", "
                )

        } set: { newValue in

            binding.wrappedValue =
                newValue
                    .split(
                        separator:
                            ","
                    )
                    .map {

                        $0
                            .trimmingCharacters(
                                in:
                                    .whitespacesAndNewlines
                            )
                    }
                    .filter {

                        !$0.isEmpty
                    }
        }
    }


    func lineSeparatedBinding(
        _ binding: Binding<[String]?>
    ) -> Binding<String> {

        Binding {

            binding
                .wrappedValue?
                .joined(
                    separator:
                        "\n"
                )
            ?? ""

        } set: { newValue in

            let values =
                newValue
                    .components(
                        separatedBy:
                            .newlines
                    )
                    .map {

                        $0
                            .trimmingCharacters(
                                in:
                                    .whitespacesAndNewlines
                            )
                    }
                    .filter {

                        !$0.isEmpty
                    }

            binding.wrappedValue =
                values.isEmpty
                ? nil
                : values
        }
    }
}


// =====================================================
// MARK: - Read-only Metadata
// =====================================================

private extension ActivityTypeEditorView {

    @ViewBuilder
    func metadataSection(
        createdAt: String?,
        copyStatus: ActivityCopyStatusNodeSummary?
    ) -> some View {

        if createdAt != nil
            || copyStatus != nil {

            Section(
                "Metadata"
            ) {

                if let createdAt,
                   !createdAt.isEmpty {

                    LabeledContent(
                        "Created",
                        value:
                            createdAt
                    )
                }


                if let copyStatus {

                    if !copyStatus.status.isEmpty {

                        LabeledContent(
                            "Copy Status",
                            value:
                                copyStatus.status
                        )
                    }

                    if !copyStatus.timestamp.isEmpty {

                        LabeledContent(
                            "Copy Timestamp",
                            value:
                                copyStatus.timestamp
                        )
                    }
                }
            }
        }
    }
}


// =====================================================
// MARK: - Image Preview
// =====================================================

private extension ActivityTypeEditorView {

    @ViewBuilder
    func remoteImagePreview(
        urlString: String?
    ) -> some View {

        if let value =
            urlString?
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                ),
           !value.isEmpty,
           let url =
            URL(
                string:
                    value
            ) {

            HStack {

                Spacer()

                AsyncImage(
                    url:
                        url
                ) { phase in

                    switch phase {

                    case .empty:

                        ProgressView()
                            .frame(
                                width:
                                    84,
                                height:
                                    84
                            )

                    case let .success(
                        image
                    ):

                        image
                            .resizable()
                            .scaledToFill()
                            .frame(
                                width:
                                    84,
                                height:
                                    84
                            )
                            .clipShape(
                                RoundedRectangle(
                                    cornerRadius:
                                        12,
                                    style:
                                        .continuous
                                )
                            )

                    case .failure:

                        Image(
                            systemName:
                                "photo"
                        )
                        .foregroundStyle(
                            .secondary
                        )
                        .frame(
                            width:
                                84,
                            height:
                                84
                        )
                        .background(
                            .quaternary,
                            in:
                                RoundedRectangle(
                                    cornerRadius:
                                        12,
                                    style:
                                        .continuous
                                )
                        )

                    @unknown default:

                        EmptyView()
                    }
                }

                Spacer()
            }
        }
    }
}
