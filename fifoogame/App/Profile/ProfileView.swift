//
//  ProfileView.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/24/26.
//

import SwiftUI

struct ProfileView: View {
    @State private var auth = AuthManager.shared

    var body: some View {
        List {
            if let user = auth.currentUser {
                Section("Account") {
                    LabeledContent("Name", value: user.displayName)
                    LabeledContent("Username", value: "@\(user.username)")
                    LabeledContent("Email", value: user.email)
                }
            }

            Section {
                Button(role: .destructive) {
                    Task { await auth.logout() }
                } label: {
                    HStack {
                        if auth.isWorking {
                            ProgressView()
                        }
                        Text("Log out")
                    }
                }
                .disabled(auth.isWorking)

                Button(role: .destructive) {
                    Task { await auth.logoutAllDevices() }
                } label: {
                    Text("Log out on all devices")
                }
                .disabled(auth.isWorking)
            } footer: {
                Text("Logging out clears this account from the current app session. Your server data remains stored with your account.")
            }
        }
        .navigationTitle("Profile")
    }
}
