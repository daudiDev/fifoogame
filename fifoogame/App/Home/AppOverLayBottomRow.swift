//
//  HomeBottomRow.swift
//  fifoo
//
//  Created by Daudi Sagala on 7/15/26.
//

import SwiftUI

struct AppOverLayBottomRow: View {
    private let socketManager = SocketManager.shared
    var geo: GeometryProxy
    @Binding var isShowingSearchView: Bool
    @Binding var isShowingHomeMenuView: Bool
    let onAddNodeTapped: () -> Void
    
    var body: some View {
        HStack(alignment: .center) {
            HStack(alignment: .center, spacing: 35) {
                Button {
                    
                    withAnimation(.spring()) {
                        isShowingSearchView.toggle()
                    }
                    
                } label: {
                    Text(Image(systemName: "magnifyingglass.circle.fill"))
                        .font(.system(size: 28, weight: .regular, design: .monospaced))
                        .foregroundStyle(.black.opacity(0.9))
                }
                .buttonStyle(
                    .plain
                )
                
                Button {
                    
                    socketManager.openPlay()
                    
                } label: {
                    Text(Image(systemName: "play.square.stack.fill"))
                        .font(.system(size: 28))
                        .foregroundStyle(.black.opacity(0.9))
                }
                .buttonStyle(
                    .plain
                )
                

                Button {

                    onAddNodeTapped()

                } label: {
                    
                    Text(Image(systemName: "plus.circle.fill"))
                        .font(.system(size: 28))
                        .foregroundStyle(.black.opacity(0.9))
                }
                .buttonStyle(
                    .plain
                )
                
                
                //MARK: this will open the app menu with links to: profile, chat, reminders, posts etc
                Button(action: {
                    withAnimation(.spring()) {
                        isShowingHomeMenuView.toggle()
                    }
                }) {
                    
                    ZStack {
                        //MARK: add user profile image
                        HStack(alignment: .center) {
                            Image(
                                socketManager.currentUserAvatarAssetName
                            )
                                .resizable()
                                .frame(width: 40, height: 40)
                                .background(
                                    Color.blue.opacity(0.1),
                                    in: Circle()
                                )
                        }
                        
                        //MARK: add data on the actions count?? or something else
                        HStack {
                            Spacer()
                            VStack {
                                Text(
                                    "\(socketManager.pendingHomeActionCount)"
                                )
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(5)
                                    .background(Circle().fill(Color.red))
                                Spacer()
                            }
                            
                        }
                        .frame(width: 40, height: 40)
                        .background(.clear)
                        
                    } //zs
                    
                } //btn
                
                
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 30).fill(.ultraThinMaterial))
            .padding(.horizontal)
        }

    }
}


