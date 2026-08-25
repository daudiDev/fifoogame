//
//  MemberProfileView.swift
//  fifoo
//
//  Created by Daudi Sagala on 10/14/24.
//

import SwiftUI

struct MemberProfileView: View {
    @StateObject private var socketClient = SocketClient.shared
    @State private var member:  UserFollowerViewModel = UserFollowerViewModel(UserFollower(userId: "", name: "", userImage: "", userRole: "", userBio: "", goal: "", conversationId: "", userLocation: "", lastActive: "", inFollowersCount: 0, outFollowersCount: 0, status: "", followsMe: false, followThem: false, viewedByUser: true, topTipster: false, topRequester: false, topResponder: false, topContributor: false, tipsCount: 0, responseCount: 0, requestCount: 0))
    @ObservedObject var userSettings = UserSettings()
    @State private var currentUserId: String?
    @State private var isLoadingProfile = false
    @State private var updateCount: Int = 0
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    // Custom Header
                    headerView
                    
                    if isLoadingProfile {
                        loadingView
                    } else {
                        profileContentView
                    }
                }
            }
            .background(
                LinearGradient(
                    colors: [Color(.systemBackground), Color(.systemGray6)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            socketClient.requestMemberProfile(memberId: socketClient.selectedMemberId)
            member = socketClient.memberProfile

            if let savedUserId = UserDefaults.standard.string(forKey: "userId") {
                currentUserId = savedUserId
            } else {
                currentUserId = "none"
            }
            
        }
        .onReceive(socketClient.$memberProfile) {memberProfile in
            
            member = memberProfile
            
        }
        .onChange(of: updateCount) {_,_ in
         
            socketClient.requestMemberProfile(memberId: socketClient.selectedMemberId)
         

        }
        .onDisappear {
            socketClient.selectedMemberId = ""
        }
        
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: {
                   
                    socketClient.selectedMemberId = ""
                    
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                        Text("Close")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(20)
                }
                
                Spacer()
                
                Text("MEMBER PROFILE")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .modifier(TitleCustomColorView())
                
                Spacer()
                
                // Balance the layout
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: 80, height: 36)
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 15)
            
            Divider()
                .background(Color.gray.opacity(0.3))
        }
        .background(Color(.systemBackground))
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.2)
                    .tint(.blue)
                
                Text("Loading profile...")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(30)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
            
            Spacer()
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Profile Content View
    private var profileContentView: some View {
        VStack(spacing: 24) {
            // Profile Header Section
            profileHeaderSection
            
            // Stats Section
            statsSection
            
            // Details Section
            detailsSection
            
            // Follow Section
            followSection
            
            Spacer(minLength: 30)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    // MARK: - Profile Header Section
    private var profileHeaderSection: some View {
        VStack(spacing: 16) {
            // Profile Image
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 180, height: 180)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [Color.blue, Color.purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 3
                            )
                    )
                
                if (!member.userImage.isEmpty && member.userImage != "none") {
                    AsyncImage(url: URL(string: member.userImage)) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Image("user")
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(.gray.opacity(0.6))
                    }
                    .clipShape(Circle())
                    .frame(width: 170, height: 170)
                } else {
                    Image("user")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 170, height: 170)
                        .foregroundColor(.gray.opacity(0.6))
                }
            }
            
            // Name and Message Button
            VStack(spacing: 8) {
                Text(member.name)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                
                if (member.userId != currentUserId) {
                    NavigationLink(destination: ConversationMessagesView(conversationId: member.conversationId, memberId: member.userId)) {
                        HStack(spacing: 8) {
                            Image(systemName: "text.bubble")
                                .font(.system(size: 14))
                            Text("Send Message")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(
                                colors: [Color.blue, Color.blue.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(25)
                        .shadow(color: .blue.opacity(0.3), radius: 5, x: 0, y: 3)
                    }
                }
            }
        }
    }
    
    // MARK: - Stats Section
    private var statsSection: some View {
        VStack(spacing: 16) {
            // Activity Stats
            HStack(spacing: 20) {
                ProStatCard(title: "Tips", value: "\(member.tipsCount)", color: .green)
                ProStatCard(title: "Requests", value: "\(member.requestCount)", color: .orange)
                ProStatCard(title: "Responses", value: "\(member.responseCount)", color: .blue)
            }
            
            // Follower Stats
            HStack(spacing: 20) {
                ProStatCard(title: "Followers", value: "\(member.inFollowersCount)", color: .purple)
                ProStatCard(title: "Following", value: "\(member.outFollowersCount)", color: .pink)
            }
        }
    }
    
    // MARK: - Details Section
    private var detailsSection: some View {
        VStack(spacing: 16) {
            DetailCard(
                icon: "clock.fill",
                title: "Last Active",
                value: FormatDateAndTime().changeToDate(timeIs: member.lastActive),
                color: .gray
            )
            
            DetailCard(
                icon: "location.fill",
                title: "Lives In",
                value: member.userLocation,
                color: .red
            )
            
            DetailCard(
                icon: "target",
                title: "Goal",
                value: member.goal,
                color: .blue
            )
            
            DetailCard(
                icon: "person.text.rectangle.fill",
                title: "Bio",
                value: member.userBio,
                color: .green
            )
        }
    }
    
    // MARK: - Follow Section
    private var followSection: some View {
        VStack(spacing: 12) {
            if member.followsMe {
                followStatusCard(text: "\(member.name) Follows You", color: .blue)
            }
            
            if member.followThem {
                HStack(spacing: 12) {
                    followStatusCard(text: "You Follow \(member.name)", color: .green)
                    
                    Button("Unfollow") {
                        var updatedList = socketClient.unFollowedUserIds
                        updatedList.append(member.userId)
                        socketClient.unFollowedUserIds = updatedList
                        socketClient.unFollowMembers(memberIds: socketClient.unFollowedUserIds)
                        updateCount = updateCount + 1
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.red)
                    .cornerRadius(20)
                    .font(.system(size: 14, weight: .semibold))
                }
            } else {
                if (member.userId != currentUserId && member.followThem == false) {
                    if (socketClient.selectedUserFollowerIds.contains(member.userId)) {
                        HStack(spacing: 12) {
                            followStatusCard(text: "You Follow \(member.name)", color: .green)
                            
                            Button("Unfollow") {
                                var updatedList = socketClient.unFollowedUserIds
                                updatedList.append(member.userId)
                                socketClient.unFollowedUserIds = updatedList
                                socketClient.unFollowMembers(memberIds: socketClient.unFollowedUserIds)
                                updateCount = updateCount + 1
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.red)
                            .cornerRadius(20)
                            .font(.system(size: 14, weight: .semibold))
                        }
                    } else {
                        Button("Follow \(member.name)'s Progress") {
                            var updatedList = socketClient.selectedUserFollowerIds
                            updatedList.append(member.userId)
                            socketClient.selectedUserFollowerIds = updatedList
                            socketClient.followMembers(memberIds: socketClient.selectedUserFollowerIds)
                            updateCount = updateCount + 1
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [Color.darkGreen, Color.green],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(25)
                        .font(.system(size: 16, weight: .semibold))
                        .shadow(color: .green.opacity(0.3), radius: 5, x: 0, y: 3)
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Views
    private func followStatusCard(text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(color)
            .cornerRadius(20)
    }
    

}




