//
//  WorkoutCircularProgressBar.swift
//  Learn Canvas
//
//  Created by Daudi Sagala on 8/12/26.
//


import SwiftUI

struct WorkoutCircularProgressBar: View {
    
    let progress: Double
    
    private var clampedProgress: Double {
        min(max(progress, 0), 1)
    }
    
    private var percentageText: String {
        "\(Int(clampedProgress * 100))%"
    }
    
    var body: some View {
        
        ZStack {
            
            // Background ring
            Circle()
                .stroke(
                    Color.gray.opacity(0.25),
                    lineWidth: 6
                )
            
            
            // Progress ring
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
            
            
            // Percentage
            Text(percentageText)
                .font(
                    .system(
                        size: 16,
                        weight: .bold,
                        design: .rounded
                    )
                )
                .foregroundStyle(.green)
        }
        .frame(width: 50, height: 50)
        .background(Circle().fill(.ultraThickMaterial))
    }
}
