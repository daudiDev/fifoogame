//
//  AppOverlayMenu.swift
//  fifoo
//
//  Created by Daudi Sagala on 6/1/26.
//

import SwiftUI

struct AppOverlayMenu: View {
    @Binding var isShowingHomeMenuView: Bool
    //MARK: this is the app menu with links to: profile, chat, reminders, posts etc
    var body: some View {
        
        VStack(alignment: .center, spacing: 15) {
            ScrollView(showsIndicators: false) {
                HStack(alignment: .center, spacing: 5) {
                    Text("Main Menu")
                        .font(.system(size: 24))
                        .fontWeight(.bold)
                        .foregroundStyle(.black)
                }
                .padding(.top, 100)
                .padding(.bottom, 30)
                
                Divider()
                
                //MARK: profile link
                NavigationLink{ProfileView()} label: {
                    HStack(alignment: .center, spacing: 5) {
                        Image("placeholder")
                            .resizable()
                            .frame(width: 40, height: 40)
                        Text("My Profile")
                            .font(.system(size: 18))
                            .fontWeight(.semibold)
                            .foregroundStyle(.black)
                    }
                    .padding(.vertical, 30)
                }
                
                Divider()
                
                //MARK: add params
                NavigationLink{ PostsView()} label: {
                    HStack(alignment: .center, spacing: 5) {
                        Text("📢 Tips   |   ✋ Requests")
                            .font(.system(size: 18))
                            .fontWeight(.semibold)
                            .foregroundStyle(.black)
                    }
                    .padding(.vertical, 30)
                }
                
                Divider()
                
                NavigationLink{ ChatsView()} label: {
                    HStack(alignment: .center, spacing: 5) {
                        Image("chat_bubbles")
                            .resizable()
                            .frame(width: 25, height: 25)
                        Text("My Chats")
                            .font(.system(size: 18))
                            .fontWeight(.semibold)
                            .foregroundStyle(.black)
                    }
                    .padding(.vertical, 30)
                }
                
                Divider()
                
                //MARK: add params?
                NavigationLink{ FriendsView()} label: {
                    HStack(alignment: .center, spacing: 5) {
                        Image("people")
                            .resizable()
                            .frame(width: 25, height: 25)
                        Text("My Friends")
                            .font(.system(size: 18))
                            .fontWeight(.semibold)
                            .foregroundStyle(.black)
                    }
                    .padding(.vertical, 30)
                }
                
                Divider()
                
                //MARK: profile link
                NavigationLink{ SupportView()} label: {
                    HStack(alignment: .center, spacing: 5) {
                        Image("helpdesk")
                            .resizable()
                            .frame(width: 40, height: 40)
                        Text("Contact Support")
                            .font(.system(size: 18))
                            .fontWeight(.semibold)
                            .foregroundStyle(.black)
                    }
                    .padding(.vertical, 30)
                }
                
                Divider()
                
                Spacer()
                
                Button(action: {
                    withAnimation(.spring()) {
                        isShowingHomeMenuView.toggle()
                    }
                }) {
                    
                    Text("Close Menu")
                        .font(.system(size: 18))
                        .fontWeight(.semibold)
                        .foregroundStyle(.black)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 25).fill(.ultraThinMaterial))
                        .padding(.vertical, 20)
                    
                }
                
            } //sv
            
        } // vs
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .background(RoundedRectangle(cornerRadius: 5).fill(.ultraThinMaterial))
        .ignoresSafeArea()
       
    }
}
