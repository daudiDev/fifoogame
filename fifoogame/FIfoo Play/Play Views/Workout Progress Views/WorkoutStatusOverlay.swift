//
//  WorkoutStatusOverlay.swift
//  Learn Canvas
//
//  Created by Daudi Sagala on 8/12/26.
//

import SwiftUI

struct WorkoutStatusOverlay: View {
    var geometry: GeometryProxy
    private let session = WorkoutSessionManager.shared
    @State private var showProgressView: Bool = false
    @Binding var showWorkoutStatusOverlay: Bool
    
    var body: some View {
        
        VStack {
            
            if (session.workout.status == .completed) {
                WorkoutCompleted(geometry: geometry, session: session, showProgressView: $showProgressView)
            } else if (session.workout.status == .notStarted) {
                WorkoutWelcome(geometry: geometry, session: session, showWorkoutStatusOverlay: $showWorkoutStatusOverlay)
            } else if (session.workout.status == .paused) {
                WorkoutResumeView(geometry: geometry, session: session, showWorkoutStatusOverlay: $showWorkoutStatusOverlay)
            }

        }
        .frame(width: geometry.size.width, height: geometry.size.height)
        .background(RoundedRectangle(cornerRadius: 3).fill(.black).opacity(0.9))
        .onAppear {
            //MARK: todo 1
            session.loadWorkout(session.workout)
        }
        
    }
}

//MARK: Welcome
struct WorkoutWelcome: View {
    private let socketManager = SocketManager.shared
    var geometry: GeometryProxy
    var session: WorkoutSessionManager
    @Binding var showWorkoutStatusOverlay: Bool
    
    var body: some View {
    
        VStack {
            
            HStack {
                Spacer()
                Button {

                    //MARK: todo exit
                    socketManager.isShowingPlay = false
                    
                   
                } label: {
                    
                    HStack(alignment: .center, spacing: 4) {
                        Text("Exit Workout")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                         
                        Text(Image(systemName: "arrow.up.forward.app"))
                            .font(.system(size: 20))
                            .foregroundStyle(.white)
                        
                    }
                    .frame(width: 200, height: 32)
                    .padding(5)
                    .background(RoundedRectangle(cornerRadius: 10).fill(.ultraThinMaterial))
                }
                Spacer()
            }
            
            Spacer()
            
            HStack {
                Text(session.workout.name)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            
            HStack {
                Text(session.workout.description ?? "Start When Ready")
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundStyle(.gray)
            }
            
            Spacer()
            
            Button {

                session.startWorkout()
                showWorkoutStatusOverlay = false
               
            } label: {
                Text("START")
                    .font(.system(size: 24, weight: .heavy))
                    .foregroundStyle(.white)
                    .frame(width: 120, height: 32)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 5).fill(.green))
                    .padding()
            }
            
//            Spacer()
            
        }
        .frame(width: geometry.size.width, height: geometry.size.height * 0.7)
        
    }
}

//MARK: Paused Status
struct WorkoutResumeView: View {
    private let socketManager = SocketManager.shared
    var geometry: GeometryProxy
    var session: WorkoutSessionManager
    @Binding var showWorkoutStatusOverlay: Bool
    
    var body: some View {
    
        VStack {
            
            HStack {
                Spacer()
                Button {

                    //MARK: todo exit
                    
                    socketManager.isShowingPlay = false
                    
                   
                } label: {
                    HStack(alignment: .center, spacing: 4) {
                        Text("Exit Workout")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                         
                        Text(Image(systemName: "arrow.up.forward.app"))
                            .font(.system(size: 20))
                            .foregroundStyle(.white)
                        
                    }
                    .frame(width: 200, height: 32)
                    .padding(5)
                    .background(RoundedRectangle(cornerRadius: 10).fill(.ultraThinMaterial))
                }
                Spacer()
            }
            
            Spacer()
            
            HStack {
                Text(session.workout.name)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            
            HStack {
                Text(session.workout.description ?? "Resume When Ready")
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundStyle(.gray)
            }
            
            Spacer()
            
            WorkoutProgressStatus(progress: session.workoutProgress())
            
            Spacer()
            
            Button {

                session.resumeWorkout()
                showWorkoutStatusOverlay = false
                
            } label: {
                Text("RESUME")
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(width: 150, height: 32)
                    .padding(5)
                    .background(RoundedRectangle(cornerRadius: 10).fill(.orange))
            }
            
        }
        .frame(width: geometry.size.width, height: geometry.size.height * 0.7)
        
    }
}

//MARK: completed Status
struct WorkoutCompleted: View {
    private let socketManager = SocketManager.shared
    var geometry: GeometryProxy
    var session: WorkoutSessionManager
    @Binding var showProgressView: Bool
    
    var body: some View {
    
        VStack {
            
            HStack {
                Spacer()
                Button {

                    //MARK: todo exit
                    socketManager.isShowingPlay = false
                   
                } label: {
                    HStack(alignment: .center, spacing: 4) {
                        Text("Exit Workout")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                         
                        Text(Image(systemName: "arrow.up.forward.app"))
                            .font(.system(size: 20))
                            .foregroundStyle(.white)
                        
                    }
                    .frame(width: 200, height: 32)
                    .padding(5)
                    .background(RoundedRectangle(cornerRadius: 10).fill(.ultraThinMaterial))
                }
                Spacer()
            }
            
            Spacer()
            
            HStack {
                Text(session.workout.name)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            
            HStack {
                Text(session.workout.description ?? "You've completed your workout!")
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundStyle(.gray)
            }
            
            Spacer()
            
            WorkoutProgressStatus(progress: session.workoutProgress())
            
            Spacer()
            
            // MARK: "View Progress" button
            Button {

                showProgressView = true
               
            } label: {
                Text("View Summary")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(width: 150, height: 32)
                    .padding(5)
                    .background(RoundedRectangle(cornerRadius: 10).fill(.gray))
            }
            .sheet(isPresented: $showProgressView) {
                WorkoutProgressReportView(showProgressView: $showProgressView)
            }
            
        }
        .frame(width: geometry.size.width, height: geometry.size.height * 0.7)
        
    }
}
