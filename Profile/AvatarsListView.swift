//
//   AvatarsListView.swift
//  Fifoo
//
//  Created by Daudi Sagala on 7/8/24.
//

import SwiftUI
import SDWebImageSwiftUI

struct AvatarsListView: View {
    @StateObject var socketClient = SocketClient.shared
    @Binding var showAvatars: Bool

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        VStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(socketClient.avatars, id: \.avatarId) { avatar in
                        CustomAsyncImage(url: URL(string: avatar.imageUrl)!)
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .aspectRatio(contentMode: .fit)
                                .onTapGesture {
                                    
                                    socketClient.avatarImageUrl = avatar.imageUrl
                                    showAvatars = false
                                    
                                }
                        }
                    
                    
                }
                .padding()
            }
            
            
            HStack {
                Spacer()
                Button(action: {
                    
                    showAvatars = false
                    
                })
                {
                    Text("Cancel")
                        .foregroundColor(.white)
                        .font(.system(size: 14))
                        .fontWeight(.semibold)
                        .frame(width: 140)
                    
                }
                .padding(.vertical, 8)
                .padding(.horizontal,20)
                .background(Color.blue)
                .cornerRadius(20)
                Spacer()
            }
            
        }
    }
}


