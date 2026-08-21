//
//  WorkoutProgressStatus.swift
//  Learn Canvas
//
//  Created by Daudi Sagala on 8/11/26.
//

import SwiftUI

struct WorkoutProgressStatus: View {
    
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
                    lineWidth: 22
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
                        lineWidth: 16,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(
                    .easeInOut(duration: 0.35),
                    value: clampedProgress
                )
            
            
            VStack(alignment: .center, spacing: 0) {
                // Percentage
                Text(percentageText)
                    .font(.system(size: 40, weight: .bold,design: .rounded))
                    .foregroundStyle(.white)
                Text("Completed")
                    .font(.system(size: 14, weight: .bold,design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.top, -3)
                    
            }
        }
        .frame(width: 200, height: 200)
        .background(Circle().fill(.clear))
    }
}

