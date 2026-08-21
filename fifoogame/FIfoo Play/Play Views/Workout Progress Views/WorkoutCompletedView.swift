//
//  WorkoutCompletedView.swift
//  Fifoo Play
//
//  Created by Daudi Sagala on 8/13/26.
//

import SwiftUI


// MARK: - Workout Completed View

struct WorkoutCompletedView: View {
    
    let workout: Workout
    
    let onFinished: () -> Void
    
    
    var body: some View {
        
        ZStack {
            
            // MARK: - Background
            
            LinearGradient(
                colors: [
                    .green,
                    .green.opacity(0.75),
                    .black
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            
            VStack(spacing: 24) {
                
                Spacer()
                
                
                // MARK: - Celebration Icon
                
                ZStack {
                    
                    Circle()
                        .fill(
                            .white.opacity(0.18)
                        )
                        .frame(
                            width: 150,
                            height: 150
                        )
                    
                    
                    Image(
                        systemName:
                            "trophy.fill"
                    )
                    .font(
                        .system(size: 75)
                    )
                    .foregroundStyle(.yellow)
                }
                
                
                // MARK: - Congratulations
                
                VStack(spacing: 8) {
                    
                    Text("WORKOUT COMPLETE!")
                        .font(
                            .system(
                                size: 30,
                                weight: .black,
                                design: .rounded
                            )
                        )
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                    
                    
                    Text("Great work!")
                        .font(
                            .system(
                                size: 20,
                                weight: .bold,
                                design: .rounded
                            )
                        )
                        .foregroundStyle(
                            .white.opacity(0.85)
                        )
                }
                
                
                // MARK: - Workout Name
                
                Text(workout.name)
                    .font(
                        .system(
                            size: 24,
                            weight: .heavy,
                            design: .rounded
                        )
                    )
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                
                
                // MARK: - Progress
                
                VStack(spacing: 8) {
                    
                    Text("100%")
                        .font(
                            .system(
                                size: 55,
                                weight: .black,
                                design: .rounded
                            )
                        )
                        .foregroundStyle(.white)
                    
                    
                    Text("COMPLETED")
                        .font(
                            .system(
                                size: 13,
                                weight: .heavy,
                                design: .rounded
                            )
                        )
                        .foregroundStyle(
                            .white.opacity(0.8)
                        )
                }
                
                
                Spacer()
                
                
                // MARK: - Report Message
                
                HStack(spacing: 8) {
                    
                    ProgressView()
                        .tint(.white)
                    
                    Text(
                        "Preparing your workout report..."
                    )
                    .font(
                        .system(
                            size: 14,
                            weight: .semibold,
                            design: .rounded
                        )
                    )
                    .foregroundStyle(
                        .white.opacity(0.8)
                    )
                }
                
                
                Spacer()
                    .frame(height: 40)
            }
            .padding()
        }
        
        // MARK: - Automatically Show Report
        
        .task {
            
            do {
                
                try await Task.sleep(
                    for: .seconds(7)
                )
                
            } catch {
                return
            }
            
            guard !Task.isCancelled else {
                return
            }
            
            onFinished()
        }
    }
}
