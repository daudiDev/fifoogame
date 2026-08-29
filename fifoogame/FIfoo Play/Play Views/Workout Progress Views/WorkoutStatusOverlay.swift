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

    /// Only non-nil when Fifoo Play was opened from an independent
    /// ActivityWorkout stop. Browsing classes belongs to this workout-level
    /// overlay rather than the per-exercise PlayOverlay.
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
                    onBrowseWorkoutClasses:
                        onBrowseWorkoutClasses
                )

            } else if socketManager.workout.status == .paused {

                WorkoutResumeView(
                    geometry:
                        geometry,
                    showWorkoutStatusOverlay:
                        $showWorkoutStatusOverlay,
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
