//
//  UserProfileView.swift
//  Fifoo
//
//  Created by Daudi Sagala on 5/17/24.
//

import SwiftUI
import UserNotifications

struct UserProfileView: View {
    @Environment(\.presentationMode) private var presentationMode
    @StateObject var socketClient = SocketClient.shared
    @StateObject var loginVM = AppManagerVM.shared
    @StateObject var sessionPolling = SessionPolling.shared
    @EnvironmentObject var userProfileVM: UserProfileVM
    var geometry: GeometryProxy
    @Binding var showGiphyPicker: Bool
    @Binding var showMedia: Bool
    @State private var showingMyPosts: Bool = false
    @State private var showEditGoal: Bool = false
    @State private var notificationsAllowed: Bool? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Section
            headerSection
            
            // Content Section
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Profile Image Section
                    profileImageSection
                    
                    // Name and Username Section
                    nameSection
                    
                    // Contact Information
                    contactSection
                    
                    // Member Since
                    memberSinceSection
                    
                    // Goal Section
                    goalSection
                    
                    // Support Section
                    supportSection
                    
                    // Notifications Section
                    notificationsSection
                    
                    // Stats Section
                    statsSection
                    
                    // Logout Section
                    logoutSection
                    
                    Spacer(minLength: 30)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
            }
        }
        .padding(.bottom)
        .background(
            LinearGradient(
                colors: [Color(.systemBackground), Color(.systemGray6).opacity(0.3)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            socketClient.requestWeightLossGoal()
            checkNotificationSettings()
            sessionPolling.startTimer()
        }
        .onChange(of: sessionPolling.poller) { _, _ in
            if (sessionPolling.poller % 10 == 0) {
                checkNotificationSettings()
            }
        }
        .onDisappear {
            sessionPolling.stopTimer()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            Button(action: {
                withAnimation {
                    self.presentationMode.wrappedValue.dismiss()
                }
            }) {
                Text(Image(systemName: "chevron.backward.circle"))
                    .font(.system(size: 28))
                    .foregroundStyle(.blue)
                    .fontWeight(.thin)
            }
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 4) {
                
                Text("My Profile")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .modifier(DarkCustomColorView())
                
                Text("Manage your account")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            NavigationLink(destination: EditProfileView().navigationBarBackButtonHidden(true)) {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Edit")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    LinearGradient(
                        colors: [Color.blue, Color.blue.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(20)
                .shadow(color: .blue.opacity(0.3), radius: 5, x: 0, y: 3)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .overlay(
            Divider()
                .background(Color.gray.opacity(0.3)),
            alignment: .bottom
        )
    }
    
    // MARK: - Profile Image Section
    private var profileImageSection: some View {
        VStack(spacing: 16) {
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
                
                if (socketClient.userProfile.imageUrl != "none" && socketClient.userProfile.imageUrl != "") {
                    CustomAsyncImage(url: URL(string: socketClient.userProfile.imageUrl)!)
                        .aspectRatio(1, contentMode: .fill)
                        .frame(width: 170, height: 170)
                        .clipShape(Circle())
                } else {
                    Image("user")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 170, height: 170)
                        .clipShape(Circle())
                        .foregroundColor(.gray.opacity(0.6))
                }
            }
        }
    }
    
    // MARK: - Name Section
    private var nameSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 6) {
                Text(socketClient.userProfile.firstName)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .modifier(TitleCustomColorView())
                
                Text(socketClient.userProfile.lastName)
                    .font(.system(size: 24, weight: .bold))
                    .modifier(TitleCustomColorView())
            }
            
            if (socketClient.userProfile.username != "none") {
                Text("@\(socketClient.userProfile.username)")
                    .font(.system(size: 18, weight: .semibold))
                    .modifier(CustomColorView())
            } else {
                Text("Username Not Added")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.orange)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Contact Section
    private var contactSection: some View {
        InfoCard(
            icon: "iphone.homebutton",
            title: "Phone Number",
            value: socketClient.userProfile.phone != "none" && socketClient.userProfile.phone != ""
            ? socketClient.userProfile.phone
            : "Not Added",
            iconColor: .blue,
            isValueMissing: socketClient.userProfile.phone == "none" || socketClient.userProfile.phone == ""
        )
    }
    
    // MARK: - Member Since Section
    private var memberSinceSection: some View {
        InfoCard(
            icon: "calendar",
            title: "Member Since",
            value: socketClient.userProfile.joined,
            iconColor: .green,
            isValueMissing: false
        )
    }
    
    // MARK: - Goal Section
    private var goalSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "target")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.red)
                    .frame(width: 28)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("My Goal")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                    
                    if (socketClient.weightLossNumber > 0 && socketClient.weightLossPeriod != "" && socketClient.weightLossPeriod != "none") {
                        Text("Lose \(socketClient.weightLossNumber)lbs In \(socketClient.weightLossPeriod)")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                    } else {
                        Text("Not Added")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.orange)
                    }
                }
                
                Spacer()
                
                Button(action: {
                    showEditGoal = true
                }) {
                    Text(socketClient.weightLossNumber > 0 ? "Edit" : "Add Goal")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.red)
                        .cornerRadius(20)
                }
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        .fullScreenCover(isPresented: $showEditGoal) {
            EditWeightLossGoal(showEditGoal: $showEditGoal, geometry: geometry)
        }
  
    }
    
    // MARK: - Support Section
    private var supportSection: some View {
        NavigationLink(destination: ConversationMessagesView(conversationId: socketClient.supportConversationId, memberId: socketClient.supportUserId)) {
            HStack(spacing: 16) {
                Image("support")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Contact Support")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text("Get help with your account")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray.opacity(0.6))
            }
            .padding(20)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Notifications Section
    private var notificationsSection: some View {
        Button(action: {
            openSettings()
        }) {
            HStack(spacing: 16) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.orange)
                    .frame(width: 28)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Push Notifications")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    if let allowed = notificationsAllowed {
                        Text(allowed ? "Enabled" : "Disabled")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(allowed ? .green : .red)
                    } else {
                        Text("Checking permissions...")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                if let allowed = notificationsAllowed {
                    Image(systemName: allowed ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(allowed ? .green : .red)
                }
            }
            .padding(20)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Stats Section
    private var statsSection: some View {
        VStack(spacing: 16) {
            Text("Activity Overview")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                // Activity Stats
                HStack(spacing: 15) {
                    StatItem(title: "Tips", value: "\(socketClient.userProfile.tipsCount)", color: .green)
                    StatItem(title: "Requests", value: "\(socketClient.userProfile.requestCount)", color: .orange)
                    StatItem(title: "Responses", value: "\(socketClient.userProfile.responseCount)", color: .blue)
                }
                
                // Social Stats
                HStack(spacing: 15) {
                    StatItem(title: "Followers", value: "\(socketClient.userProfile.inFollowersCount)", color: .purple)
                    StatItem(title: "Following", value: "\(socketClient.userProfile.outFollowersCount)", color: .pink)
                }
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Logout Section
    private var logoutSection: some View {
        Button(action: {
            loginVM.logout()
        }) {
            HStack(spacing: 12) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                
                Text("Log Out")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [Color.red, Color.red.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .shadow(color: .red.opacity(0.3), radius: 5, x: 0, y: 3)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Helper Functions
    func checkNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                notificationsAllowed = (settings.authorizationStatus == .authorized)
            }
        }
    }
    
    func openSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        
        if UIApplication.shared.canOpenURL(settingsURL) {
            UIApplication.shared.open(settingsURL)
        }
    }
}

// MARK: - Supporting Views
struct InfoCard: View {
    let icon: String
    let title: String
    let value: String
    let iconColor: Color
    let isValueMissing: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(iconColor)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isValueMissing ? .orange : .primary)
            }
            
            Spacer()
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct StatItem: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(color)
            
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(12)
    }
}
