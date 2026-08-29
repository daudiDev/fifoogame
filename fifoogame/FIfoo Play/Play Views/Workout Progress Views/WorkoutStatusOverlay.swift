//
//  WorkoutStatusOverlay.swift
//  Learn Canvas
//
//  Created by Daudi Sagala on 8/12/26.
//

import SwiftUI


struct WorkoutStatusOverlay: View {

    private let socketManager =
        SocketManager.shared

    var geometry:
        GeometryProxy

    @State
    private var showProgressView:
        Bool = false

    @Binding
    var showWorkoutStatusOverlay:
        Bool

    /// ActivityWorkout planning fields are supplied only when Fifoo Play was
    /// opened from an independent ActivityWorkout stop. They intentionally
    /// live on the workout-level overlay, not on an individual exercise page.
    let scheduledWorkoutStartTime: String?
    let scheduledWorkoutEndTime: String?
    let scheduledWorkoutLocation: String?
    let onUpdateScheduledWorkoutTimes: ((String, String) -> Void)?
    let onUpdateScheduledWorkoutLocation: ((String) -> Void)?

    /// Browsing classes also belongs to the workout-level overlay.
    let onBrowseWorkoutClasses: (() -> Void)?


    var body: some View {

        VStack {

            if socketManager.workout.status == .completed {

                WorkoutCompleted(
                    geometry:
                        geometry,
                    showProgressView:
                        $showProgressView
                )

            } else if socketManager.workout.status == .notStarted {

                WorkoutWelcome(
                    geometry:
                        geometry,
                    showWorkoutStatusOverlay:
                        $showWorkoutStatusOverlay,
                    scheduledWorkoutStartTime:
                        scheduledWorkoutStartTime,
                    scheduledWorkoutEndTime:
                        scheduledWorkoutEndTime,
                    scheduledWorkoutLocation:
                        scheduledWorkoutLocation,
                    onUpdateScheduledWorkoutTimes:
                        onUpdateScheduledWorkoutTimes,
                    onUpdateScheduledWorkoutLocation:
                        onUpdateScheduledWorkoutLocation,
                    onBrowseWorkoutClasses:
                        onBrowseWorkoutClasses
                )

            } else if socketManager.workout.status == .paused {

                WorkoutResumeView(
                    geometry:
                        geometry,
                    showWorkoutStatusOverlay:
                        $showWorkoutStatusOverlay,
                    scheduledWorkoutStartTime:
                        scheduledWorkoutStartTime,
                    scheduledWorkoutEndTime:
                        scheduledWorkoutEndTime,
                    scheduledWorkoutLocation:
                        scheduledWorkoutLocation,
                    onUpdateScheduledWorkoutTimes:
                        onUpdateScheduledWorkoutTimes,
                    onUpdateScheduledWorkoutLocation:
                        onUpdateScheduledWorkoutLocation,
                    onBrowseWorkoutClasses:
                        onBrowseWorkoutClasses
                )
            }
        }
        .frame(
            width: geometry.size.width,
            height: geometry.size.height
        )
        .background(
            RoundedRectangle(
                cornerRadius: 3
            )
            .fill(.black)
            .opacity(0.9)
        )
    }
}


// MARK: - Welcome

private struct WorkoutWelcome: View {

    private let socketManager =
        SocketManager.shared

    var geometry:
        GeometryProxy

    @Binding
    var showWorkoutStatusOverlay:
        Bool

    let scheduledWorkoutStartTime: String?
    let scheduledWorkoutEndTime: String?
    let scheduledWorkoutLocation: String?
    let onUpdateScheduledWorkoutTimes: ((String, String) -> Void)?
    let onUpdateScheduledWorkoutLocation: ((String) -> Void)?
    let onBrowseWorkoutClasses: (() -> Void)?


    var body: some View {

        VStack {

            exitButton

            Spacer()

            HStack {

                Text(
                    socketManager.workout.name
                )
                .font(
                    .system(
                        size: 32,
                        weight: .bold,
                        design: .rounded
                    )
                )
                .foregroundStyle(
                    .white
                )
            }


            HStack {

                Text(
                    socketManager.workout.description
                    ?? "Start When Ready"
                )
                .font(
                    .system(
                        size: 16,
                        weight: .regular,
                        design: .rounded
                    )
                )
                .foregroundStyle(
                    .gray
                )
            }

            Spacer()

            if let onUpdateScheduledWorkoutTimes,
               let onUpdateScheduledWorkoutLocation {

                IndependentWorkoutPlanEditor(
                    startTime:
                        scheduledWorkoutStartTime ?? "",
                    endTime:
                        scheduledWorkoutEndTime ?? "",
                    location:
                        scheduledWorkoutLocation ?? "",
                    onUpdateTimes:
                        onUpdateScheduledWorkoutTimes,
                    onUpdateLocation:
                        onUpdateScheduledWorkoutLocation
                )
                .padding(.horizontal, 28)
                .padding(.bottom, 14)
            }

            if let onBrowseWorkoutClasses {
                Button {
                    onBrowseWorkoutClasses()
                } label: {
                    Label(
                        "Browse Workout Classes",
                        systemImage: "person.2.fill"
                    )
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(.white.opacity(0.12))
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(.white.opacity(0.18), lineWidth: 1)
                    }
                }
                .buttonStyle(.plain)
                .padding(.bottom, 10)
            }

            Button {

                socketManager.startWorkoutSession()

                showWorkoutStatusOverlay =
                    false

            } label: {

                Text(
                    "START"
                )
                .font(
                    .system(
                        size: 24,
                        weight: .heavy
                    )
                )
                .foregroundStyle(
                    .white
                )
                .frame(
                    width: 120,
                    height: 32
                )
                .padding()
                .background(
                    RoundedRectangle(
                        cornerRadius: 5
                    )
                    .fill(.green)
                )
                .padding()
            }
        }
        .frame(
            width: geometry.size.width,
            height: geometry.size.height * 0.7
        )
    }


    var exitButton: some View {

        HStack {

            Spacer()

            Button {

                socketManager.closePlay(
                    pauseActiveWorkout:
                        false
                )

            } label: {

                exitButtonLabel
            }

            Spacer()
        }
    }
}


// MARK: - Paused Status

private struct WorkoutResumeView: View {

    private let socketManager =
        SocketManager.shared

    var geometry:
        GeometryProxy

    @Binding
    var showWorkoutStatusOverlay:
        Bool

    let scheduledWorkoutStartTime: String?
    let scheduledWorkoutEndTime: String?
    let scheduledWorkoutLocation: String?
    let onUpdateScheduledWorkoutTimes: ((String, String) -> Void)?
    let onUpdateScheduledWorkoutLocation: ((String) -> Void)?
    let onBrowseWorkoutClasses: (() -> Void)?


    var body: some View {

        VStack {

            HStack {

                Spacer()

                Button {

                    socketManager.closePlay(
                        pauseActiveWorkout:
                            false
                    )

                } label: {

                    exitButtonLabel
                }

                Spacer()
            }

            Spacer()

            HStack {

                Text(
                    socketManager.workout.name
                )
                .font(
                    .system(
                        size: 32,
                        weight: .bold,
                        design: .rounded
                    )
                )
                .foregroundStyle(
                    .white
                )
            }


            HStack {

                Text(
                    socketManager.workout.description
                    ?? "Resume When Ready"
                )
                .font(
                    .system(
                        size: 16,
                        weight: .regular,
                        design: .rounded
                    )
                )
                .foregroundStyle(
                    .gray
                )
            }

            Spacer()

            WorkoutProgressStatus(
                progress:
                    socketManager.workoutProgress()
            )

            Spacer()

            if let onUpdateScheduledWorkoutTimes,
               let onUpdateScheduledWorkoutLocation {

                IndependentWorkoutPlanEditor(
                    startTime:
                        scheduledWorkoutStartTime ?? "",
                    endTime:
                        scheduledWorkoutEndTime ?? "",
                    location:
                        scheduledWorkoutLocation ?? "",
                    onUpdateTimes:
                        onUpdateScheduledWorkoutTimes,
                    onUpdateLocation:
                        onUpdateScheduledWorkoutLocation
                )
                .padding(.horizontal, 28)
                .padding(.bottom, 14)
            }

            if let onBrowseWorkoutClasses {
                Button {
                    onBrowseWorkoutClasses()
                } label: {
                    Label(
                        "Browse Workout Classes",
                        systemImage: "person.2.fill"
                    )
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.white.opacity(0.12))
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.white.opacity(0.18), lineWidth: 1)
                    }
                }
                .buttonStyle(.plain)
                .padding(.bottom, 10)
            }

            Button {

                socketManager.resumeWorkoutSession()

                showWorkoutStatusOverlay =
                    false

            } label: {

                Text(
                    "RESUME"
                )
                .font(
                    .system(
                        size: 24,
                        weight: .heavy,
                        design: .rounded
                    )
                )
                .foregroundStyle(
                    .white
                )
                .frame(
                    width: 150,
                    height: 32
                )
                .padding(5)
                .background(
                    RoundedRectangle(
                        cornerRadius: 10
                    )
                    .fill(.orange)
                )
            }
        }
        .frame(
            width: geometry.size.width,
            height: geometry.size.height * 0.7
        )
    }
}



// MARK: - Independent ActivityWorkout Plan

private enum IndependentWorkoutTimeField:
    String,
    Identifiable {

    case start
    case end

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .start:
            return "Start Time"
        case .end:
            return "End Time"
        }
    }
}


private struct IndependentWorkoutPlanEditor: View {

    let startTime: String
    let endTime: String
    let location: String
    let onUpdateTimes: (String, String) -> Void
    let onUpdateLocation: (String) -> Void

    @State private var editingTimeField: IndependentWorkoutTimeField?
    @State private var isEditingLocation = false


    var body: some View {

        VStack(spacing: 10) {

            HStack(spacing: 10) {
                planButton(
                    title: "Start",
                    value: startTime.isEmpty ? "Set Time" : startTime,
                    systemImage: "clock.fill"
                ) {
                    editingTimeField = .start
                }

                planButton(
                    title: "End",
                    value: endTime.isEmpty ? "Set Time" : endTime,
                    systemImage: "clock.badge.checkmark.fill"
                ) {
                    editingTimeField = .end
                }
            }

            Button {
                isEditingLocation = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.78))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("LOCATION")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.58))

                        Text(
                            location
                                .trimmingCharacters(in: .whitespacesAndNewlines)
                                .isEmpty
                            ? "Add Location"
                            : location
                        )
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    }

                    Spacer(minLength: 0)

                    Image(systemName: "pencil")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.70))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(.white.opacity(0.10))
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(.white.opacity(0.16), lineWidth: 1)
                }
            }
            .buttonStyle(.plain)
        }
        .sheet(item: $editingTimeField) { target in
            IndependentWorkoutTimeEditorSheet(
                title: target.title,
                initialValue:
                    target == .start
                    ? startTime
                    : endTime
            ) { newValue in
                switch target {
                case .start:
                    onUpdateTimes(newValue, endTime)
                case .end:
                    onUpdateTimes(startTime, newValue)
                }
            }
        }
        .sheet(isPresented: $isEditingLocation) {
            IndependentWorkoutLocationEditorSheet(
                initialLocation: location,
                onSave: onUpdateLocation
            )
        }
    }


    private func planButton(
        title: String,
        value: String,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {

        Button(action: action) {
            HStack(spacing: 9) {
                Image(systemName: systemImage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.78))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title.uppercased())
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.58))

                    Text(value)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                Image(systemName: "pencil")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.70))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 11)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(.white.opacity(0.10))
            )
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(.white.opacity(0.16), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}


private struct IndependentWorkoutTimeEditorSheet: View {

    let title: String
    let onSave: (String) -> Void

    @State private var selectedDate: Date
    @Environment(\.dismiss) private var dismiss


    init(
        title: String,
        initialValue: String,
        onSave: @escaping (String) -> Void
    ) {
        self.title = title
        self.onSave = onSave
        _selectedDate = State(
            initialValue:
                Self.dateForClockString(initialValue)
        )
    }


    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                DatePicker(
                    title,
                    selection: $selectedDate,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .frame(maxWidth: .infinity)

                Spacer(minLength: 0)
            }
            .padding()
            .navigationTitle(title)
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
                        onSave(time.displayClockString)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
    }


    private static func dateForClockString(
        _ value: String
    ) -> Date {

        let seconds = secondsFromClockString(value)

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current

        return calendar
            .startOfDay(for: Date())
            .addingTimeInterval(seconds)
    }


    private static func secondsFromClockString(
        _ value: String
    ) -> TimeInterval {

        let cleaned = value
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleaned.isEmpty else {
            return 12 * 3_600
        }

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

            return TimeInterval(
                (components.hour ?? 0) * 3_600
                + (components.minute ?? 0) * 60
                + (components.second ?? 0)
            )
        }

        return 12 * 3_600
    }
}


private struct IndependentWorkoutLocationEditorSheet: View {

    let onSave: (String) -> Void

    @State private var draftLocation: String
    @Environment(\.dismiss) private var dismiss


    init(
        initialLocation: String,
        onSave: @escaping (String) -> Void
    ) {
        self.onSave = onSave
        _draftLocation = State(initialValue: initialLocation)
    }


    var body: some View {
        NavigationStack {
            Form {
                Section("Workout Location") {
                    TextField(
                        "Home, gym, park, studio...",
                        text: $draftLocation
                    )
                    .textInputAutocapitalization(.words)
                }
            }
            .navigationTitle("Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(
                            draftLocation.trimmingCharacters(
                                in: .whitespacesAndNewlines
                            )
                        )
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
    }
}


// MARK: - Completed Status

private struct WorkoutCompleted: View {

    private let socketManager =
        SocketManager.shared

    var geometry:
        GeometryProxy

    @Binding
    var showProgressView:
        Bool


    var body: some View {

        VStack {

            HStack {

                Spacer()

                Button {

                    socketManager.closePlay(
                        pauseActiveWorkout:
                            false
                    )

                } label: {

                    exitButtonLabel
                }

                Spacer()
            }

            Spacer()

            HStack {

                Text(
                    socketManager.workout.name
                )
                .font(
                    .system(
                        size: 32,
                        weight: .bold,
                        design: .rounded
                    )
                )
                .foregroundStyle(
                    .white
                )
            }


            HStack {

                Text(
                    socketManager.workout.description
                    ?? "You've completed your workout!"
                )
                .font(
                    .system(
                        size: 16,
                        weight: .regular,
                        design: .rounded
                    )
                )
                .foregroundStyle(
                    .gray
                )
            }

            Spacer()

            WorkoutProgressStatus(
                progress:
                    socketManager.workoutProgress()
            )

            Spacer()

            Button {

                showProgressView =
                    true

            } label: {

                Text(
                    "View Summary"
                )
                .font(
                    .system(
                        size: 18,
                        weight: .bold,
                        design: .rounded
                    )
                )
                .foregroundStyle(
                    .white
                )
                .frame(
                    width: 150,
                    height: 32
                )
                .padding(5)
                .background(
                    RoundedRectangle(
                        cornerRadius: 10
                    )
                    .fill(.gray)
                )
            }
            .sheet(
                isPresented:
                    $showProgressView
            ) {

                WorkoutProgressReportView(
                    showProgressView:
                        $showProgressView
                )
            }
        }
        .frame(
            width: geometry.size.width,
            height: geometry.size.height * 0.7
        )
    }
}


// MARK: - Shared Exit Label

private extension View {

    var exitButtonLabel: some View {

        HStack(
            alignment: .center,
            spacing: 4
        ) {

            Text(
                "Exit Workout"
            )
            .font(
                .system(
                    size: 18,
                    weight: .bold,
                    design: .rounded
                )
            )
            .foregroundStyle(
                .white
            )


            Image(
                systemName:
                    "arrow.up.forward.app"
            )
            .font(
                .system(
                    size: 20
                )
            )
            .foregroundStyle(
                .white
            )
        }
        .frame(
            width: 200,
            height: 32
        )
        .padding(5)
        .background(
            RoundedRectangle(
                cornerRadius: 10
            )
            .fill(
                .ultraThinMaterial
            )
        )
    }
}
