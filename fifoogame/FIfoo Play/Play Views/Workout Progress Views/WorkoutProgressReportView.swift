//
//  WorkoutProgressView.swift
//  Learn Canvas
//
//  Created by Daudi Sagala on 8/11/26.
//

import SwiftUI


struct WorkoutProgressReportView: View {
    
    private let socketManager = SocketManager.shared
    @Binding var showProgressView: Bool
    
    var body: some View {
        
        NavigationStack {
            
            ScrollView {
                    
                    VStack(spacing: 20) {
                        
                        // MARK: - Header
                        
                        WorkoutReportHeader(
                            workout: socketManager.workout
                        )
                        
                        
                        // MARK: - Overall Progress
                        
                        WorkoutOverallProgressSection(
                            workout: socketManager.workout
                        )
                        
                        
                        // MARK: - Workout Timing
                        
                        WorkoutTimingSection(
                            workout: socketManager.workout
                        )
                        
                        
                        // MARK: - Current Exercise
                        
                        if let currentExercise = socketManager.workout.currentExercise {
                            
                            WorkoutCurrentExerciseSection(
                                exercise: currentExercise
                            )
                        }
                        
                        
                        // MARK: - Exercise Breakdown
                        
                        WorkoutExerciseProgressSection(
                            exercises: socketManager.workout.exercises
                        )
                    }
                    .padding()
                    
            }
            .navigationTitle("Workout Progress")
            .navigationBarTitleDisplayMode(.inline)
            
            HStack {
                Spacer()
                Button(action: {
                    //MARK: todo - add action
                    showProgressView = false
                })
                {
                    Text("Exit")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.blue)
                        .padding()
                        .padding(.horizontal, 30)
                        .background(RoundedRectangle(cornerRadius: 10).fill(.ultraThinMaterial))
                }
                Spacer()
            }
    
        }
    }
}


// MARK: - Report Header

struct WorkoutReportHeader: View {
    
    let workout: Workout
    
    var body: some View {
        
        VStack(spacing: 12) {
            
            HStack {
                
                VStack(alignment: .leading, spacing: 5) {
                    
                    Text(workout.name)
                        .font(.title2)
                        .fontWeight(.heavy)
                    
                    if let description = workout.description {
                        
                        Text(description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                WorkoutCircularProgressView(
                    progress: workout.progress
                )
            }
            
            
            HStack {
                
                Text(workout.status.rawValue)
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(statusColor.opacity(0.15))
                    )
                    .foregroundStyle(statusColor)
                
                Spacer()
                
                Text(
                    "\(workout.completedExerciseCount) / \(workout.exercises.count) completed"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(.ultraThinMaterial)
        )
    }
    
    
    private var statusColor: Color {
        
        switch workout.status {
            
        case .notStarted:
            return .gray
            
        case .active:
            return .green
            
        case .paused:
            return .orange
            
        case .completed:
            return .blue
            
        case .ended:
            return .red
        }
    }
}

// MARK: - Overall Progress Section

struct WorkoutOverallProgressSection: View {
    
    let workout: Workout
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 12) {
            
            Text("Progress")
                .font(.headline)
            
            
            HStack(spacing: 12) {
                
                ReportStatCard(
                    title: "PROGRESS",
                    value: "\(workout.progressPercentage)%",
                    systemImage: "chart.line.uptrend.xyaxis"
                )
                
                ReportStatCard(
                    title: "COMPLETED",
                    value: "\(workout.completedExerciseCount)",
                    systemImage: "checkmark.circle.fill"
                )
                
                ReportStatCard(
                    title: "REMAINING",
                    value: "\(workout.remainingExerciseCount)",
                    systemImage: "hourglass"
                )
            }
        }
    }
}

// MARK: - Report Stat Card

struct ReportStatCard: View {
    
    let title: String
    let value: String
    let systemImage: String
    
    var body: some View {
        
        VStack(spacing: 8) {
            
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(.green)
            
            Text(value)
                .font(.title2)
                .fontWeight(.heavy)
            
            Text(title)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.ultraThinMaterial)
        )
    }
}

// MARK: - Workout Timing Section

struct WorkoutTimingSection: View {
    
    let workout: Workout
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 12) {
            
            Text("Timing")
                .font(.headline)
            
            
            VStack(spacing: 10) {
                
                WorkoutReportRow(
                    title: "Started",
                    value: formatDate(workout.startedAt)
                )
                
                WorkoutReportRow(
                    title: "Last Resumed",
                    value: formatDate(workout.resumedAt)
                )
                
                WorkoutReportRow(
                    title: "Last Paused",
                    value: formatDate(workout.pausedAt)
                )
                
                WorkoutReportRow(
                    title: "Ended",
                    value: formatDate(workout.endedAt)
                )
                
                WorkoutReportRow(
                    title: "Total Elapsed",
                    value: formatDuration(
                        workout.totalElapsedTime
                    )
                )
                
                WorkoutReportRow(
                    title: "Paused Time",
                    value: formatDuration(
                        workout.totalPausedTime
                    )
                )
                
                WorkoutReportRow(
                    title: "Active Time",
                    value: formatDuration(
                        workout.totalActiveTime
                    )
                )
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            )
        }
    }
    
    
    private func formatDate(_ date: Date?) -> String {
        
        guard let date else {
            return "—"
        }
        
        return date.formatted(
            date: .abbreviated,
            time: .shortened
        )
    }
    
    
    private func formatDuration(
        _ duration: TimeInterval
    ) -> String {
        
        let totalSeconds = Int(duration)
        
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return String(
                format: "%d:%02d:%02d",
                hours,
                minutes,
                seconds
            )
        }
        
        return String(
            format: "%02d:%02d",
            minutes,
            seconds
        )
    }
}

// MARK: - Report Row

struct WorkoutReportRow: View {
    
    let title: String
    let value: String
    
    var body: some View {
        
        HStack {
            
            Text(title)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text(value)
                .fontWeight(.semibold)
        }
    }
}

// MARK: - Current Exercise Section

struct WorkoutCurrentExerciseSection: View {
    
    let exercise: WorkoutExercise
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 12) {
            
            Text("Current Exercise")
                .font(.headline)
            
            
            VStack(alignment: .leading, spacing: 10) {
                
                HStack {
                    
                    VStack(alignment: .leading, spacing: 4) {
                        
                        Text(exercise.name)
                            .font(.title3)
                            .fontWeight(.heavy)
                        
                        Text(exercise.status.rawValue)
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.green)
                    }
                    
                    Spacer()
                    
                    Image(
                        systemName:
                            "figure.strengthtraining.traditional"
                    )
                    .font(.title)
                }
                
                
                Divider()
                
                
                HStack {
                    
                    if let sets = exercise.sets {
                        
                        CurrentExerciseStat(
                            value: "\(sets)",
                            label: "Sets"
                        )
                    }
                    
                    if let reps = exercise.reps {
                        
                        CurrentExerciseStat(
                            value: "\(reps)",
                            label: "Reps"
                        )
                    }
                    
                    if let weight = exercise.weight {
                        
                        CurrentExerciseStat(
                            value: "\(Int(weight))",
                            label: "lbs"
                        )
                    }
                    
                    if let duration = exercise.duration,
                       let unit = exercise.durationUnit {
                        
                        CurrentExerciseStat(
                            value: formatNumber(duration),
                            label: unit.rawValue
                            
                        )
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            )
        }
    }
    
    
    private func formatNumber(
        _ value: Double
    ) -> String {
        
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(value))"
        }
        
        return value.formatted(
            .number.precision(.fractionLength(0...1))
        )
    }
}

struct CurrentExerciseStat: View {
    
    let value: String
    let label: String
    
    var body: some View {
        
        VStack(spacing: 2) {
            
            Text(value)
                .font(.title3)
                .fontWeight(.heavy)
            
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Exercise Progress Section

struct WorkoutExerciseProgressSection: View {
    
    let exercises: [WorkoutExercise]
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 12) {
            
            Text("Exercises")
                .font(.headline)
            
            
            VStack(spacing: 10) {
                
                ForEach(
                    Array(exercises.enumerated()),
                    id: \.element.workoutExerciseId
                ) { index, exercise in
                    
                    WorkoutExerciseReportRow(
                        number: index + 1,
                        exercise: exercise
                    )
                }
            }
        }
    }
}

// MARK: - Exercise Report Row

struct WorkoutExerciseReportRow: View {
    
    let number: Int
    let exercise: WorkoutExercise
    
    var body: some View {
        
        HStack(spacing: 12) {
            
            ZStack {
                
                Circle()
                    .fill(statusColor.opacity(0.15))
                
                if exercise.status == .completed {
                    
                    Image(systemName: "checkmark")
                        .fontWeight(.bold)
                        .foregroundStyle(statusColor)
                    
                } else {
                    
                    Text("\(number)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(statusColor)
                }
            }
            .frame(width: 36, height: 36)
            
            
            VStack(alignment: .leading, spacing: 4) {
                
                Text(exercise.name)
                    .fontWeight(.semibold)
                
                
                HStack(spacing: 8) {
                    
                    if let sets = exercise.sets {
                        Text("\(sets) sets")
                    }
                    
                    if let reps = exercise.reps {
                        Text("× \(reps) reps")
                    }
                    
                    if let weight = exercise.weight {
                        Text("• \(weight.formatted()) lbs")
                    }
                    
                    if let duration = exercise.duration,
                       let unit = exercise.durationUnit {
                        
                        Text(
                            "• \(duration.formatted()) \(unit.rawValue)"
                        )
                    }
                    
                    if let distance = exercise.distance,
                       let unit = exercise.distanceUnit {
                        
                        Text(
                            "• \(distance.formatted()) \(unit.rawValue)"
                        )
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            
            
            Spacer()
            
            
            Text(exercise.status.rawValue)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundStyle(statusColor)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.ultraThinMaterial)
        )
    }
    
    
    private var statusColor: Color {
        
        switch exercise.status {
            
        case .notStarted:
            return .gray
            
        case .active:
            return .green
            
        case .paused:
            return .orange
            
        case .completed:
            return .blue
            
        case .skipped:
            return .gray
        }
        
        
    }
}

import SwiftUI

struct WorkoutCircularProgressView: View {
    
    let progress: Double
    
    // MARK: - Clamped Progress
    
    private var clampedProgress: Double {
        min(max(progress, 0), 1)
    }
    
    
    // MARK: - Percentage
    
    private var percentageText: String {
        "\(Int(clampedProgress * 100))%"
    }
    
    
    var body: some View {
        
        ZStack {
            
            // MARK: - Background Ring
            
            Circle()
                .stroke(
                    Color.gray.opacity(0.25),
                    lineWidth: 6
                )
            
            
            // MARK: - Progress Ring
            
            Circle()
                .trim(
                    from: 0,
                    to: clampedProgress
                )
                .stroke(
                    Color.green,
                    style: StrokeStyle(
                        lineWidth: 6,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(
                    .easeInOut(duration: 0.35),
                    value: clampedProgress
                )
            
            
            // MARK: - Percentage
            
            Text(percentageText)
                .font(
                    .system(
                        size: 12,
                        weight: .bold,
                        design: .rounded
                    )
                )
                .foregroundStyle(.primary)
        }
        .frame(
            width: 52,
            height: 52
        )
    }
}
